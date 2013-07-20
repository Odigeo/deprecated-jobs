# == Schema Information
#
# Table name: async_jobs
#
#  id           :integer          not null, primary key
#  uuid         :string(255)      not null
#  restarts     :integer          default(0), not null
#  state        :string(255)      default(""), not null
#  started_at   :datetime
#  finished_at  :datetime
#  steps        :text
#  lock_version :integer          default(0), not null
#  created_by   :integer          default(0), not null
#  updated_by   :integer          default(0), not null
#  created_at   :datetime
#  updated_at   :datetime
#

class AsyncJob < ActiveRecord::Base

  ocean_resource_model index: [:uuid], search: :uuid
  serialize :steps, Array

  # Relations


  # Attributes
  attr_accessible :uuid, :restarts, :state, :started_at, 
                  :finished_at, :steps, :lock_version

  # Validations
  validates_each :steps do |record, attr, value|
    record.errors.add(attr, 'must be an Array') unless value.is_a?(Array)
  end 

  # Callbacks
  after_initialize { |j| j.uuid ||= SecureRandom.uuid }
  
end
