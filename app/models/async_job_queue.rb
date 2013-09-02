class AsyncJobQueue

  cattr_reader :sqs

  attr_reader :basename, :fullname
  attr_reader :queue


  def initialize(basename: "AsyncJobQueue-" + SecureRandom::urlsafe_base64)
    @@sqs ||= AWS::SQS.new
    @basename = basename
    @fullname = Api.adorn_basename(basename)
    @queue = AsyncJobQueue.create_queue(self, chef_env: CHEF_ENV, rails_env: Rails.env)
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
