require 'spec_helper'

describe QueueMessage do

  before :each do
    @msg = double(AWS::SQS::ReceivedMessage,
             body:          "This is the message body.",
             receive_count: 2,
             delete:        nil
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
    QueueMessage.new(@msg).body.should == "This is the message body."
  end

  it "should have a receive count reader" do
    QueueMessage.new(@msg).receive_count.should == 2
  end

  it "should have a delete method which removes message from the AWS queue" do
    QueueMessage.new(@msg).delete
  end

end
