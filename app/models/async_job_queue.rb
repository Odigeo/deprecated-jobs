class AsyncJobQueue

  cattr_reader :sqs

  attr_reader :basename, :fullname
  attr_reader :queue


  def initialize(basename: "AsyncJobQueue-" + SecureRandom::urlsafe_base64)
    @@sqs ||= AWS::SQS.new
    @basename = basename
    @fullname = AsyncJobQueue.adorn_name(basename)
    @queue = AsyncJobQueue.create_queue(self)
  end


  #
  # Adds environment info to the basename, so that testing and execution in various combinations
  # of the Rails env and the Chef environment can be done without collision. 
  #
  # The chef_env will lways be appended to the basename, since we never want to share queues 
  # between different Chef environments. 
  #
  # If the chef_env is 'dev' or 'ci', we must separate things as much as
  # possible: therefore, we add the local IP number and the Rails environment. 
  #
  # We also add the same information if by any chance the Rails environment isn't 'production'. 
  # This is a precaution; in staging and prod apps should always run in Rails production mode, 
  # but if by mistake they don't, we must prevent the production queues from being touched.
  #
  def self.adorn_name(basename, chef_env: CHEF_ENV, rails_env: Rails.env)
    fullname = "#{basename}_#{chef_env}"
    if rails_env != 'production' || chef_env == 'dev' || chef_env == 'ci'
      local_ip = UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last}.gsub('.', '-')
      fullname += "_#{local_ip}_#{rails_env}"
    end
    fullname
  end


  def self.create_queue(i)
    q = i.sqs.queues.create(i.fullname)
    q.wait_time_seconds = 20
    q
  end


end
