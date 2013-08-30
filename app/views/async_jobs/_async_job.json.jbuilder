json.async_job do |json|
	json._links       hyperlinks(self:    async_job_url(async_job.uuid),
	                             creator: api_user_url(async_job.created_by || 0),
	                             updater: api_user_url(async_job.updated_by || 0))
	json.(async_job, :uuid, 
	                 :default_step_time,
	                 :default_poison_limit,
	                 :max_seconds_in_queue,
	                 :last_completed_step,
	                 :steps,
	                 :succeeded,
	                 :failed,
	                 :poison,
	                 :lock_version) 
	json.created_at           async_job.created_at.utc.iso8601
	json.updated_at           async_job.updated_at.utc.iso8601
	json.destroy_at           async_job.destroy_at.utc.iso8601
	json.started_at           async_job.started_at.utc.iso8601 if async_job.started_at
	json.finished_at          async_job.finished_at.utc.iso8601 if async_job.finished_at
end
