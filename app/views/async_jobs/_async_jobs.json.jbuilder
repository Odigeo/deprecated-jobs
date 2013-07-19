json.array! async_jobs do |async_job|
  json.partial! 'async_jobs/async_job', async_job: async_job
end
