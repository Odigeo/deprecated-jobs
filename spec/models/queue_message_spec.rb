require 'spec_helper'

describe QueueMessage do

  before :each do
    @msg = double(AWS::SQS::ReceivedMessage,
             body:                "This is the message body.",
             receive_count:       2,
             :visibility_timeout= => 3600,
             delete:              nil
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


  it "should have a visibility_timeout setter" do
    (QueueMessage.new(@msg).visibility_timeout = 1.hour).should == 3600
  end



  it "should have a delete method which removes the message from the AWS queue" do
    QueueMessage.new(@msg).delete
  end



end
