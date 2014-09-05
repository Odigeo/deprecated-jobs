require 'spec_helper'

describe AsyncJobQueue, :type => :model do
  
  before :each do
    allow(AsyncJobQueue).to receive(:create_queue).
      and_return(double(AWS::SQS::Queue, 
        delete:          nil, 
        send_message:    double(AWS::SQS::Queue::SentMessage),
        receive_message: double(AWS::SQS::ReceivedMessage),
        poll:            double(AWS::SQS::ReceivedMessage)
      ))
  end


  describe "creation" do 

    it "should work" do
      expect(AsyncJobQueue.new).to be_an AsyncJobQueue
    end

    it "should allow a queue basename to be specified" do
      expect(AsyncJobQueue.new(basename: "ZalagadoolaQueue").basename).to eq "ZalagadoolaQueue"
    end

    it "should have a random, unique basename if not explicitly specified" do
      expect(AsyncJobQueue.new.basename).to be_a String
      expect(AsyncJobQueue.new.basename).not_to eq AsyncJobQueue.new.basename
    end

    it "should have a fullname" do
      expect(AsyncJobQueue.new.fullname).to be_a String
    end
  end



  describe "instances" do

    it "should have an SQS attribute" do
      expect(AsyncJobQueue.new.sqs).to be_an(AWS::SQS)
    end

    it "should all use the same AWS::SQS instance" do
      the_sqs = AsyncJobQueue.new.sqs
      expect(AsyncJobQueue.new.sqs).to eq the_sqs
      expect(AsyncJobQueue.new.sqs).to eq the_sqs
      expect(AsyncJobQueue.new.sqs).to eq the_sqs
    end


    it "should have a queue attribute" do
      expect(AsyncJobQueue.new.queue).to be_an Object
    end
  end



  describe "#delete" do

    it "should delete the AWS queue" do
      q = AsyncJobQueue.new
      q.delete
      expect(q.queue).to have_received(:delete)
    end
  end



  describe "#send_message" do

    it "should post to the AWS queue" do
      q = AsyncJobQueue.new
      q.send_message "Dear John", delay_seconds: 10
      expect(q.queue).to have_received(:send_message).with("Dear John", delay_seconds: 10)
    end
  end



  describe "#receive_message" do

    it "should receive a message from the AWS queue, not using a block" do
      q = AsyncJobQueue.new
      expect(q.receive_message(visibility_timeout: 60)).to be_a QueueMessage
      expect(q.queue).to have_received(:receive_message).with({:attributes=>[:receive_count], :visibility_timeout=>60, :limit=>1})
    end

    it "should receive a message from the AWS queue, using a block" do
      q = AsyncJobQueue.new
      q.receive_message(visibility_timeout: 60) { |msg| puts msg.body }
      expect(q.queue).to have_received(:receive_message).with({:attributes=>[:receive_count], :visibility_timeout=>60, :limit=>1})
    end
  end



  describe "#poll" do

    it "should poll from the AWS queue, not using a block" do
      q = AsyncJobQueue.new
      expect(q.poll(visibility_timeout: 60)).to be_a QueueMessage
      expect(q.queue).to have_received(:poll).with({:attributes=>[:receive_count], :visibility_timeout=>60, :limit=>1})
    end

    it "should poll from the AWS queue, using a block" do
      q = AsyncJobQueue.new
      q.poll(visibility_timeout: 60) { |msg| puts msg.body }
      expect(q.queue).to have_received(:poll).with({:attributes=>[:receive_count], :visibility_timeout=>60, :limit=>1})
    end
  end

end
