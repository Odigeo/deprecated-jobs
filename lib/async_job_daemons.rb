#
# The directory RUN_TIME_DIR must already exist, and this process
# must have the right to create files in it.
#

require 'rubygems'
require 'daemons'

# The number of log workers to keep running at all times
N_WORKERS = 5

# Run time directory
RUN_TIME_DIR = "/var/run/async_job_workers"


options = {
  dir_mode: :normal,
  dir: RUN_TIME_DIR,
  backtrace: true,
  log_output: true,
  multiple: false,
  monitor: true
}


# The async job workers
(0...N_WORKERS).each do |i| 
  Daemons.run_proc("async_job_worker_#{i}", options) do
    q = AsyncJobQueue.new basename: 'AsyncJobs'
    loop do
      q.poll { |qm| qm.process } rescue nil
    end
  end
end

# A daemon to remove log entries older than a month (one per machine instance)
Daemons.run_proc("async_job_purger", options) do
  while true do
    # Do something here
    sleep 86400 # Sleep for a day
  end
end


# j = 
# AsyncJob.create steps: [{'url' => 'http://127.0.0.1', 'retry_exponent' => 3},
#                         {'url' => 'http://127.0.0.2', 'retry_exponent' => 4}],
#                 credentials: "bWFnbmV0bzp4YXZpZXI=", 
#                 token: "hhhhhhhhhhhhhhh"
# j.reload; pp j.attributes; nil
