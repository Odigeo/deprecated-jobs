require 'spec_helper'

describe QueueMessage do

  before :each do
    @async_job = create :async_job
    @msg = double(AWS::SQS::ReceivedMessage,
             body: @async_job.uuid,
             receive_count: 2,
             :visibility_timeout= => 3600,
             delete: nil
      )
  end


  it "should require a message when instantiated" do
    QueueMessage.new(@msg).should be_a QueueMessage
    expect { QueueMessage.new() }.to raise_error
  end


  it "should have a message reader" do
    QueueMessage.new(@msg).message.should == @msg
  end

  it "should have a body reader" do
    QueueMessage.new(@msg).body.should == @async_job.uuid
  end

  it "should have a receive count reader" do
    QueueMessage.new(@msg).receive_count.should == 2
  end


  it "should have a visibility_timeout setter" do
    (QueueMessage.new(@msg).visibility_timeout = 1.hour).should == 3600
  end



  it "should have a delete method which removes the message from the AWS queue" do
    QueueMessage.new(@msg).delete
  end


  it "should have an async_job" do
    QueueMessage.new(@msg).async_job.should be_an AsyncJob
  end

  it "should handle a missing async_job by returning nil" do
    @async_job.destroy
    QueueMessage.new(@msg).async_job.should == nil
  end

  # it "should have async_job always return the same object" do
  #   aj1 = QueueMessage.new(@msg).async_job
  #   aj2 = QueueMessage.new(@msg).async_job
  #   aj1.should be aj2
  # end


end
