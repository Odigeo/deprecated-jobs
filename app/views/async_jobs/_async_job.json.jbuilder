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
#  payload      :text             default("{}"), not null
#  lock_version :integer          default(0), not null
#  created_by   :integer          default(0), not null
#  updated_by   :integer          default(0), not null
#  created_at   :datetime
#  updated_at   :datetime
#

json.async_job do |json|
	json._links       hyperlinks(self:    async_job_url(async_job),
	                             creator: api_user_url(id: async_job.created_by || 0),
	                             updater: api_user_url(id: async_job.updated_by || 0))
	json.(async_job, :uuid, 
	                 :restarts, 
	                 :state, 
	                 :payload,
	                 :lock_version) 
	json.created_at  async_job.created_at.utc.iso8601
	json.updated_at  async_job.updated_at.utc.iso8601
	json.started_at  async_job.started_at.utc.iso8601 if async_job.started_at
	json.finished_at async_job.finished_at.utc.iso8601 if async_job.finished_at
end
