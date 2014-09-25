class AsyncJob < OceanDynamo::Table

  ocean_resource_model index: [:uuid], search: false,
                       invalidate_member: [],
                       invalidate_collection: []


  dynamo_schema(:uuid, table_name_suffix: Api.basename_suffix, 
                       create: Rails.env != "production") do
    # Input attributes
    attribute :credentials
    attribute :token
    attribute :steps,                :serialized, default: []
    attribute :max_seconds_in_queue, :integer,    default: 1.day
    attribute :default_poison_limit, :integer,    default: 5
    attribute :default_step_time,    :integer,    default: 30
    attribute :poison_email

    # Output only
    attribute :started_at,           :datetime
    attribute :last_completed_step,  :integer
    attribute :finished_at,          :datetime
    attribute :destroy_at,           :datetime
    attribute :created_by
    attribute :updated_by
    attribute :succeeded,            :boolean,    default: false
    attribute :failed,               :boolean,    default: false
    attribute :poison,               :boolean,    default: false
    attribute :last_status,          :integer
    attribute :last_headers,         :serialized
    attribute :last_body,            :serialized
  end
  

  @@queue = nil


  # Validations
  validates_each :steps do |record, attr, value|
    record.errors.add(attr, 'must be an Array') unless value.is_a?(Array)
  end 

  validates :credentials, presence: { message: "must be specified", on: :create }

  validates_each :credentials, on: :create, allow_blank: true do |job, attr, val|
    username, password = Api.decode_credentials val
    job.errors.add(attr, "are malformed") if username.blank? || password.blank?
  end

  validates :poison_email, email: { message: "is an invalid email address" }, allow_blank: true


  # Callbacks
  before_validation do |j| 
    j.destroy_at ||= Time.now.utc + j.max_seconds_in_queue
  end

  after_create do |j|
    j.enqueue unless j.steps == []
  end

  after_update  { |model| model.ban }
  after_destroy { |model| model.ban }


  #
  # Finishes the job successfully. Returns true.
  #
  def job_succeeded
    self.finished_at = Time.now.utc
    self.succeeded = true
    save!
    Rails.logger.info "[Job #{uuid}] succeeded (#{steps.length} steps)."
    true
  end

  #
  # Finishes the job as failed. Returns true.
  #
  def job_failed(str=nil)
    self.finished_at = Time.now.utc
    self.failed = true
    save!
    log(str) if str
    Rails.logger.warn "[Job #{uuid}] failed: '#{str}' (#{steps.length} steps)."
    true
  end

  #
  # Finishes the job as poison. Returns true.
  #
  def job_is_poison
    self.finished_at = Time.now.utc
    self.poison = true
    self.failed = true
    save!
    Rails.logger.error "[Job #{uuid}] is poison (#{steps.length} steps)."
    # Mail someone. TODO: parametrise the fallback email
    job = attributes.except("credentials")
    job['api_user'] = Api.decode_credentials(credentials).first
    pretty_json = JSON.pretty_generate(job)
    Api.send_mail to: (poison_email.present? ? poison_email : "peter.bengtson@odigeo.com"), 
                  subject: "Poison AsyncJob",
                  html: "<pre>#{pretty_json}</pre>"
    true
  end


  #
  # Returns true if the whole job is finished, regardless of how it finished 
  # (success, failure, poison)
  #
  def finished?
    !!finished_at
  end


  #
  # Returns the index of the current step
  #
  def current_step_index
    (last_completed_step || -1) + 1
  end

  #
  # Returns the current step
  #
  def current_step
    steps[current_step_index]
  end

  #
  # Returns true if there are no more steps
  #
  def done_all_steps?
    !current_step
  end

  #
  # Advances the job to the next step
  #
  def current_step_done!
    return if finished?
    self.last_completed_step = current_step_index
    job_succeeded if done_all_steps? && !failed?
    save!
  end


  #
  # Poison limit for the current step
  #
  def poison_limit
    cs = current_step
    cs && cs['poison_limit'] || default_poison_limit
  end

  #
  # Step time for the current step
  #
  def step_time
    cs = current_step
    cs && cs['step_time'] || default_step_time
  end


  #
  # This method enqueues the job on AWS.
  #
  def enqueue
    @@queue ||= AsyncJobQueue.new basename: ASYNCJOBQ_AWS_BASENAME
    @@queue.send_message uuid
  end


  #
  # Log to the current step.
  # 
  def log(str)
    reload
    cs = current_step
    cs['log'] ||= []
    cs['log'] << str
    save!
    str
  end


  #
  # Issue a BAN to remove the entity from Varnish
  #
  def ban
    Api.ban "/v[0-9]+/async_jobs/#{uuid}($|/|\\?)"
  end


  #
  # Purge AsyncJobs
  #
  def self.cleanup
    killed = 0
    t = Time.now.utc
    AsyncJob.find_each do |j|
      if j.destroy_at <= t
        j.destroy 
        killed += 1
      end
    end
    Rails.logger.info "Cleaned up #{killed} old AsyncJobs"
  end

end
