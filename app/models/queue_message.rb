class QueueMessage

  attr_reader :message

  def initialize(message)
    @message = message
  end


  #
  # Returns the body of the AWS message. It's always the UUID of the AsyncJob to which
  # the AWS message and this QueueMessage belongs.
  #
  def body
    message.body
  end

  #
  # This is the number of times this message has been received. Anything above 1 is a
  # restart. The receive_count is used to determine that the job has become poison.
  #
  def receive_count
    message.receive_count
  end

  #
  # This sets the visibility timeout (for this processing round only) to a number of
  # seconds. After the specified number of seconds, the job will be claimed for another
  # run. Therefore, one of the first things the worker does is to set this value high
  # enough to allow normal processing to complete. See AsyncJob#default_step_time.
  # If an exception occurs, the visibility timeout will be set again to control how
  # long to wait before the next attempt.
  #
  def visibility_timeout=(seconds)
    message.visibility_timeout = [seconds, 12.hours].min
  end


  #
  # Deletes the message from the AWS queue. If messages are processed in a block passed
  # to AsyncJobQueue#read_message or AsyncJobQueue#poll, messages will automatically be
  # deleted when the block is completed normally. In all other cases, you should manually
  # delete the QueueMessage as an acknowledgement that the step completed successfully.
  #
  def delete
    message.delete
  end


  #
  # Returns the associated AsyncJob or nil if one doesn't exist. Caches the result:
  # multiple invocations return the same object.
  #
  def async_job    
    @async_job ||= AsyncJob.find_by_key(body, consistent: true)
  end


  #
  # Returns true if the job can't be found.
  #
  def job_missing?
    !async_job
  end

  #
  # Returns true if the job already has finished.
  #
  def job_started?
    !!async_job.started_at
  end

  #
  # Returns true if the job already has finished.
  #
  def job_finished?
    async_job.finished?
  end

  #
  # Returns true if the job step is poison.
  #
  def job_is_poison?
    receive_count > async_job.poison_limit
  end


  def retry_seconds
    s = async_job.current_step
    base = s['retry_base'] || 1
    multiplier = s['retry_multiplier'] || 1
    exponent = s['retry_exponent'] || 1
    (base + ((receive_count - 1) * multiplier) ** exponent).ceil
  end


  #
  # Process the message. Returns false if the job was skipped, true otherwise.
  #
  def process
    return false if job_missing?
    return false if job_finished?
    async_job.job_is_poison and return false if job_is_poison?
    if async_job.done_all_steps?
      async_job.finished_at = Time.now.utc
      return false
    end
    execute_current_step
    true
  end


  #
  # Executes the current job step. If the job isn't finished after this step,
  # a new message will be enqueued to handle the next step.
  #
  def execute_current_step
    # Prepare
    async_job.started_at = Time.now.utc and Rails.logger.info "[Job #{async_job.uuid}] started (#{async_job.steps.length} steps)." unless job_started?
    async_job.current_step['receive_count'] = receive_count
    async_job.save!
    self.visibility_timeout = async_job.step_time
    # Do the work
    if async_job.current_step['url']
      make_http_request 
    else
      Rails.logger.info async_job.log("Step has no URL. Skipped.")
    end
    # Advance or finish
    async_job.current_step_done!
    async_job.enqueue unless job_finished?
  end


  #
  # Make the outgoing HTTP request.
  #
  def make_http_request
    uuid = async_job.uuid
    i = async_job.current_step_index + 1
    nsteps = async_job.steps.length
    step = async_job.current_step
    name = step['name']
    url = step['url']
    http_method = (step['method'] || "GET").to_s.upcase
    body = step['body'] && step['body'].to_json

    Rails.logger.info "[Job #{uuid}] step #{i}:#{nsteps} '#{name}' [#{http_method}] started."

    return if async_job.token.blank? && !authenticate

    headers = {"X-API-Token" => async_job.token}.merge(step['headers'] || {})
    begin
      response = nil
      loop do
        async_job.reload
        response = case http_method
          when "GET"
            Api.request url, :get, headers: headers, reauthentication: false
          when "POST"
            Api.request url, :post, headers: headers, body: body, reauthentication: false
          when "PUT"
            Api.request url, :put, headers: headers, body: body, reauthentication: false
          when "DELETE"
            Api.request url, :delete, headers: headers, reauthentication: false
          else
            async_job.job_failed "Unsupported HTTP method '#{http_method}'"
            return
          end
        raise Exception, "Ocean API request timed out" if response.timed_out?
        if [400, 419].include?(response.status)
          return if !authenticate
          headers["X-API-Token"] = async_job.token
        elsif !(300..399).include?(response.status)
          break
        else
          if response.headers['Location'].blank?
            async_job.job_failed "Failed: #{response.status} without Location header"
            return
          end
          url = response.headers['Location']
          async_job.log "Redirect: #{response.status} to #{url}"
        end
      end
      handle_response(step, response.status, response.headers, response.body) if response
    rescue Exception => e
      self.visibility_timeout = retry_seconds
      logmsg = async_job.log "#{e.class.name}: #{e.message}"
      Rails.logger.info "[Job #{uuid}] step #{i}:#{nsteps} '#{name}' [#{http_method}] crashed: '#{logmsg}'."
      raise e
    ensure
      Rails.logger.info "[Job #{uuid}] step #{i}:#{nsteps} '#{name}' [#{http_method}] finished."
    end
  end


  #
  # Authenticates with the Auth service. Returns the new authentication token if successful,
  # logging the authentication in the step and setting token in the AsyncJob. If not successful,
  # the entire job fails.
  #
  def authenticate
    new_token = Api.authenticate(*Api.decode_credentials(async_job.credentials))
    if new_token
      async_job.token = new_token
      async_job.save!
      async_job.log "Authenticated"
      new_token
    else
      async_job.job_failed "Failed to authenticate"
      nil
    end
  end


  #
  # Handles the response from the HTTP request
  #
  def handle_response(step, status, headers, body)
    async_job.last_status = status
    async_job.last_headers = headers
    async_job.last_body = body
    async_job.save!
    case status
    when 200..299
      async_job.log("Succeeded: #{status}")
    when 400..499
      async_job.job_failed "Failed: #{status}"
    when 500..599
      async_job.log("Remote server error: #{status}. Retrying via exception.")
      raise "Raising exception to trigger retry"
    end
  end

end
