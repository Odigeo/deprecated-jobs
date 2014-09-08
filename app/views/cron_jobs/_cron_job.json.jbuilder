json.cron_job do |json|
	json._links       hyperlinks(self:    cron_job_url(cron_job.id),
	                             creator: api_user_url(cron_job.created_by),
	                             updater: api_user_url(cron_job.updated_by))
	json.(cron_job, :name,
	                :description,
	                :enabled,
	                :cron,
	                :steps,
	                :default_step_time,
	                :default_poison_limit,
	                :max_seconds_in_queue,
	                :lock_version) 
	json.created_at           cron_job.created_at.utc.iso8601
	json.updated_at           cron_job.updated_at.utc.iso8601
	json.last_run_at          cron_job.last_run_at.utc.iso8601 if cron_job.last_run_at
end
