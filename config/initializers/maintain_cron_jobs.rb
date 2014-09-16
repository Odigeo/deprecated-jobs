#
# If there is a cron_jobs.yml file, process it.
# The file will be created automatically by Chef during
# convergence. To create CronJobs, use the cron_job
# data bag in the chef-repo. Do NOT create the file
# manually: it will be overwritten by Chef.
#

f = File.join(Rails.root, "config/cron_jobs.yml")

if File.exists?(f)
  jobs = YAML.load(ERB.new(File.read(f)).result)
  CronJob.maintain_all jobs
end
