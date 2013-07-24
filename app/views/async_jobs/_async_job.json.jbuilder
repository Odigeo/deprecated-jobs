# == Schema Information
#
# Table name: async_jobs
#
#  id                   :integer          not null, primary key
#  uuid                 :string(255)      not null
#  restarts             :integer          default(0), not null
#  state                :string(255)      default(""), not null
#  started_at           :datetime
#  finished_at          :datetime
#  steps                :text
#  lock_version         :integer          default(0), not null
#  created_by           :integer          default(0), not null
#  updated_by           :integer          default(0), not null
#  created_at           :datetime
#  updated_at           :datetime
#  invisible_until      :datetime
#  last_completed_step  :integer
#  max_seconds_in_queue :integer          default(86400), not null
#  destroy_at           :datetime
#

json.async_job do |json|
	json._links       hyperlinks(self:    async_job_url(async_job.uuid),
	                             creator: api_user_url(async_job.created_by || 0),
	                             updater: api_user_url(async_job.updated_by || 0))
	json.(async_job, :uuid, 
	                 :restarts, 
	                 :state, 
	                 :steps,
	                 :lock_version) 
	json.created_at           async_job.created_at.utc.iso8601
	json.updated_at           async_job.updated_at.utc.iso8601
	json.started_at           async_job.started_at.utc.iso8601 if async_job.started_at
	json.finished_at          async_job.finished_at.utc.iso8601 if async_job.finished_at
	json.max_seconds_in_queue async_job.max_seconds_in_queue
	json.destroy_at           async_job.destroy_at
	json.invisible_until      async_job.invisible_until.utc.iso8601 if async_job.invisible_until
	json.last_completed_step  async_job.last_completed_step
end
