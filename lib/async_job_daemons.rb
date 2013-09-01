#
# The directory RUN_TIME_DIR must already exist, and this process
# must have the right to create files in it.
#
RUN_TIME_DIR = "/var/run/async_job_workers"

#
# The number of log workers to keep running at all times
#
N_WORKERS = 5


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
    q = AsyncJobQueue.new basename: 'AsyncJobs'
    loop do
      q.poll { |qm| qm.process } rescue nil
    end
  end
end

# A daemon to purge jobs (one per machine instance)
Daemons.run_proc("async_job_purger", options) do
  require ENV_PATH
  while true do
    # Do something here
    sleep 1.hour
  end
end
