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
    expect(@msg).to have_received(:body)
  end

  it "should have a receive count reader" do
    QueueMessage.new(@msg).receive_count.should == 2
    expect(@msg).to have_received(:receive_count)
  end


  it "should have a visibility_timeout setter" do
    (QueueMessage.new(@msg).visibility_timeout = 1.hour).should == 3600
    expect(@msg).to have_received(:visibility_timeout=)
  end



  it "should have a delete method which removes the message from the AWS queue" do
    QueueMessage.new(@msg).delete
    expect(@msg).to have_received(:delete)
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


  describe "process" do

    it "should execute the next step if all is in order" do
      QueueMessage.any_instance.should_receive(:execute_next_step)
      QueueMessage.new(@msg).process.should == true
    end

    it "should do nothing if there's no associated AsyncJob" do
      @async_job.destroy
      QueueMessage.any_instance.should_not_receive(:execute_next_step)
      QueueMessage.new(@msg).process.should == false
    end

    it "should do nothing if the AsyncJob already is finished" do
      @async_job.finished_at = 1.hour.ago.utc
      @async_job.save!
      QueueMessage.any_instance.should_not_receive(:execute_next_step)
      QueueMessage.new(@msg).process.should == false
    end

    it "should handle poison messages" do
      msg = double(AWS::SQS::ReceivedMessage,
               body: @async_job.uuid,
               receive_count: 6,
               :visibility_timeout= => 3600,
               delete: nil
             )
      QueueMessage.any_instance.should_not_receive(:execute_next_step)
      QueueMessage.new(msg).process.should == false
    end
  end


  describe "execute_next_step" do

    it "should be callable" do
      QueueMessage.new(@msg).execute_next_step
    end

  end

end
