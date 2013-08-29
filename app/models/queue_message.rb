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


  def visibility_timeout=(value)
    message.visibility_timeout = value
  end


  def delete
    message.delete
  end


  def async_job
    @async_job ||= AsyncJob.where(uuid: body).first
  end

end
