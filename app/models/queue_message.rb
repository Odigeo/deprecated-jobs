class QueueMessage

  attr_reader :message

  def initialize(message)
    @message = message
  end

  def body
    message.body
  end

  def receive_count
    message.receive_count
  end

  def delete
    message.delete
  end

end
