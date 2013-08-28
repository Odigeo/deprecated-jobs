require 'spec_helper'

describe AsyncJobQueue do

  before :each do
    AsyncJobQueue.stub(:create_queue).and_return(double(AWS::SQS::Queue))
  end


  describe "creation" do 

    it "should work" do
      AsyncJobQueue.new.should be_a(AsyncJobQueue)
    end

    it "should allow a queue name to be specified" do
      AsyncJobQueue.new(name: "ZalagadoolaQueue").name.should == "ZalagadoolaQueue"
    end

    it "should have a random, unique name if not explicitly specified" do
      AsyncJobQueue.new.name.should be_a String
      AsyncJobQueue.new.name.should_not == AsyncJobQueue.new.name
    end
  end


  describe "instances" do

    it "should set up an AWS::SQS object the first time" do
      # We don't know the order of exec of specs, hence at_most(:once) 
      AWS::SQS.should_receive(:new).at_most(:once)
      AsyncJobQueue.new
      AsyncJobQueue.new
      AsyncJobQueue.new
    end

    it "should have a SQS attribute" do
      AsyncJobQueue.new.sqs.should be_an(AWS::SQS)
    end

    it "should all use the same AWS::SQS instance" do
      the_sqs = AsyncJobQueue.new.sqs
      AsyncJobQueue.new.sqs.should == the_sqs
      AsyncJobQueue.new.sqs.should == the_sqs
      AsyncJobQueue.new.sqs.should == the_sqs
    end


    it "should have a queue attribute" do
      lambda { AsyncJobQueue.new.queue }.should_not raise_error
    end

  end

end
