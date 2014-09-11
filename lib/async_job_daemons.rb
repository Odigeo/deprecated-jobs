#
# The directory RUN_TIME_DIR must already exist, and this process
# must have the right to create files in it.
#
RUN_TIME_DIR = "/var/run/async_job_workers"

#
# The number of log workers to keep running at all times
#
N_WORKERS = 5

ENV['RAILS_ENV'] ||= 'production'

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

ENV_PATH = File.expand_path('../../config/environment.rb', __FILE__)

require 'daemons'

options = {
  dir_mode:   :normal,
  dir:        RUN_TIME_DIR,
  backtrace:  true,
  log_output: false,
  multiple:   false,
  monitor:    true
}


# The async job workers
(0...N_WORKERS).each do |i| 
  Daemons.run_proc("async_job_worker_#{i}", options) do
    require ENV_PATH
    AsyncJob.establish_db_connection
    q = AsyncJobQueue.new basename: ASYNCJOBQ_AWS_BASENAME
    loop do
      q.poll { |qm| qm.process } rescue nil
    end
  end
end

# A daemon to purge jobs (one per machine instance)
Daemons.run_proc("async_job_purger", options) do
  require ENV_PATH
  while true do
    sleep(15.minutes + rand(7.minutes))
    killed = 0
    t = Time.now.utc
    AsyncJob.find_each do |j|
      j.destroy if j.destroy_at <= t
      killed += 1
      #sleep 0.01
    end
    logger.info "Cleaned up #{killed} old AsyncJobs"
  end
end
