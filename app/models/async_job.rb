# == Schema Information
#
# Table name: async_jobs
#
#  id                   :integer          not null, primary key
#  uuid                 :string(255)      not null
#  restarts             :integer          default(0), not null
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
#  poison_limit         :integer          default(5), not null
#  visible_at           :datetime
#  credentials          :string(255)      default(""), not null
#

class AsyncJob < ActiveRecord::Base

  ocean_resource_model index: [:uuid], search: false
  serialize :steps, Array

  # Attributes
  attr_accessible :uuid, :lock_version,
                  :steps, :max_seconds_in_queue, :poison_limit,
                  :credentials

  # Scopes
  scope :visible,   -> { where("visible_at <= ?", Time.now.utc) }
  scope :invisible, -> { where("visible_at > ?", Time.now.utc) }

  # Validations
  validates_each :steps do |record, attr, value|
    record.errors.add(attr, 'must be an Array') unless value.is_a?(Array)
  end 
  validates :visible_at, presence: true
  validates :credentials, presence: { message: "must be specified", on: :create }
  validates_each :credentials, on: :create, allow_blank: true do |job, attr, val|
    username, password = Api.decode_credentials val
    job.errors.add(attr, "are malformed") if username.blank? || password.blank?
  end


  # Callbacks
  after_initialize  { |j| j.uuid ||= SecureRandom.uuid }
  before_validation do |j| 
    j.destroy_at ||= Time.now.utc + j.max_seconds_in_queue
    j.visible_at ||= Time.now.utc
  end

end
