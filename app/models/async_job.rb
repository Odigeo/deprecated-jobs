# == Schema Information
#
# Table name: async_jobs
#
#  id                   :integer          not null, primary key
#  uuid                 :string(255)      not null
#  started_at           :datetime
#  finished_at          :datetime
#  steps                :text
#  lock_version         :integer          default(0), not null
#  created_by           :integer          default(0), not null
#  updated_by           :integer          default(0), not null
#  created_at           :datetime
#  updated_at           :datetime
#  last_completed_step  :integer
#  max_seconds_in_queue :integer          default(86400), not null
#  destroy_at           :datetime
#  default_poison_limit :integer          default(5), not null
#  credentials          :string(255)      default(""), not null
#  default_step_time    :integer          default(30), not null
#

class AsyncJob < ActiveRecord::Base

  ocean_resource_model index: [:uuid], search: false

  serialize :steps, Array

  @@queue = nil


  # Attributes
  attr_accessible :uuid, :lock_version,
                  :steps, :max_seconds_in_queue, :default_poison_limit,
                  :credentials, :default_step_time

  # Scopes


  # Validations
  validates_each :steps do |record, attr, value|
    record.errors.add(attr, 'must be an Array') unless value.is_a?(Array)
  end 

  validates :credentials, presence: { message: "must be specified", on: :create }

  validates_each :credentials, on: :create, allow_blank: true do |job, attr, val|
    username, password = Api.decode_credentials val
    job.errors.add(attr, "are malformed") if username.blank? || password.blank?
  end


  # Callbacks
  after_initialize do |j| 
    j.uuid ||= SecureRandom.uuid
  end

  before_validation do |j| 
    j.destroy_at ||= Time.now.utc + j.max_seconds_in_queue
  end

  after_create do |j|
    j.enqueue unless j.steps == []
  end


  #
  # Returns the current step
  #
  def current_step
    steps[(last_completed_step || -1) + 1]
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
    return if done_all_steps?
    self.last_completed_step = (last_completed_step || -1) + 1
    self.finished_at = Time.now.utc if done_all_steps?
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

end
