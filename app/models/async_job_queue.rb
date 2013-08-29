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


  #
  # This deletes the AWs Queue permanently, including any messages it may contain.
  #
  def delete
    queue.delete
  end


  #
  # This enqueues a message to the AWS queue.
  #
  def send_message(*args)
    queue.send_message *args 
  end


  #
  # This receives a message from the AWS queue. Like its AWS::SQS counterpart, 
  # it can be called with or without a block. When called with a block, the
  # message will automatically be deleted when the block is exited normally.
  # Always receives exactly 1 message, with receive_count.
  #
  def receive_message(opts={}, &block)
    opts = {attributes: [:receive_count]}.merge(opts).merge(limit: 1)
    if block
      queue.receive_message(opts) { |msg| yield QueueMessage.new(msg) }
    else
      QueueMessage.new(queue.receive_message(opts))
    end
  end


  #
  # This polls the AWS queue. Like its AWS::SQS counterpart, it can be called
  # with or without a block. When called with a block, the message will 
  # automatically be deleted when the block is exited normally. Always receives 
  # exactly 1 message at a time, with receive_count.
  #
  def poll(opts={}, &block)
    opts = {attributes: [:receive_count]}.merge(opts).merge(limit: 1)
    if block
      queue.poll(opts) { |msg| yield QueueMessage.new(msg) }
    else
      QueueMessage.new(queue.poll(opts))
    end
  end


end
