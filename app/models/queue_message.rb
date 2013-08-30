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
  #
  def visibility_timeout=(seconds)
    message.visibility_timeout = seconds
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
    @async_job ||= AsyncJob.where(uuid: body).first
  end


  #
  # Process the message. Returns false if the job was skipped, true otherwise.
  #
  def process
    return false if !async_job || finished? || poison?
    execute_current_step
    true
  end


  #
  # Returns true if the job already has finished.
  #
  def finished?
    !!async_job.finished_at
  end

  #
  # Returns true if the job step is poison.
  #
  def poison?
    receive_count > async_job.poison_limit
  end


  #
  # Execute the current job step.
  #
  def execute_current_step
    async_job.started_at = Time.now.utc unless async_job.started_at
    async_job.current_step['receive_count'] = receive_count unless async_job.done_all_steps?
    async_job.save!
    self.visibility_timeout = async_job.step_time

    # Do the work here
    Rails.logger.info "[ASYNC_JOB_STEP] ==========================================================================="
    Rails.logger.info "[ASYNC_JOB_STEP] Executing the step: #{async_job.current_step.inspect}"
    Rails.logger.info "[ASYNC_JOB_STEP] ==========================================================================="

    async_job.current_step_done!
    async_job.enqueue unless async_job.done_all_steps?
  end

end
