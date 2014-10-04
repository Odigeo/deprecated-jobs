json.async_job do |json|
	json._links       hyperlinks(self:    async_job_url(async_job.id),
	                             creator: api_user_url(async_job.created_by),
	                             updater: api_user_url(async_job.updated_by))
	json.(async_job, :uuid, 
	                 :default_step_time,
	                 :default_poison_limit,
	                 :max_seconds_in_queue,
	                 :last_completed_step,
	                 :steps,
	                 :succeeded,
	                 :failed,
	                 :poison,
	                 :last_status,
	                 :last_headers,
	                 :last_body,
	                 :poison_email,
	                 :lock_version)
	json.x_metadata           async_job.x_metadata if async_job.x_metadata
	json.created_at           async_job.created_at.utc.iso8601
	json.updated_at           async_job.updated_at.utc.iso8601
	json.destroy_at           async_job.destroy_at.utc.iso8601
	json.started_at           async_job.started_at.utc.iso8601 if async_job.started_at
	json.finished_at          async_job.finished_at.utc.iso8601 if async_job.finished_at
end
