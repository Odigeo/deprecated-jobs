class AsyncJobQueue

  cattr_reader :sqs

  attr_reader :name
  attr_reader :queue


  def initialize(name: "AsyncJobQueue-" + SecureRandom::urlsafe_base64)
    @@sqs ||= AWS::SQS.new
    @name = name
    @queue = AsyncJobQueue.create_queue(self)
  end


  def self.create_queue(i)
    i.sqs.queues.create(i.name)
  end


end
