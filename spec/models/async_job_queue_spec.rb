require 'spec_helper'

describe AsyncJobQueue do

  before :each do
    AsyncJobQueue.stub(:create_queue).
      and_return(double(AWS::SQS::Queue, 
        delete:          nil, 
        send_message:    double(AWS::SQS::Queue::SentMessage),
        receive_message: double(AWS::SQS::ReceivedMessage),
        poll:            double(AWS::SQS::ReceivedMessage)
      ))
  end


  describe "creation" do 

    it "should work" do
      AsyncJobQueue.new.should be_an AsyncJobQueue
    end

    it "should allow a queue basename to be specified" do
      AsyncJobQueue.new(basename: "ZalagadoolaQueue").basename.should == "ZalagadoolaQueue"
    end

    it "should have a random, unique basename if not explicitly specified" do
      AsyncJobQueue.new.basename.should be_a String
      AsyncJobQueue.new.basename.should_not == AsyncJobQueue.new.basename
    end

    it "should have a fullname" do
      AsyncJobQueue.new.fullname.should be_a String
    end
  end



  describe ".adorn_name" do

    it "should return a string" do
      AsyncJobQueue.adorn_name("SomeBaseName").should be_a String
    end

    it "should return a string containing the basename" do
      AsyncJobQueue.adorn_name("SomeBaseName").should match "SomeBaseName"
    end

    it "should return a string containing the Chef environment" do
      AsyncJobQueue.adorn_name("SomeBaseName", chef_env: "zuul").should match "zuul"
    end

    it "should add IP and rails_env if the chef_env is 'dev' or 'ci' or if rails_env isn't 'production'" do
      local_ip = UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last}.gsub('.', '-')
      AsyncJobQueue.adorn_name("Q", chef_env: "dev",  rails_env: 'development').should ==    "Q_dev_#{local_ip}_development"
      AsyncJobQueue.adorn_name("Q", chef_env: "dev",  rails_env: 'test').should ==           "Q_dev_#{local_ip}_test"
      AsyncJobQueue.adorn_name("Q", chef_env: "dev",  rails_env: 'production').should ==     "Q_dev_#{local_ip}_production"
      AsyncJobQueue.adorn_name("Q", chef_env: "ci",   rails_env: 'development').should ==    "Q_ci_#{local_ip}_development"
      AsyncJobQueue.adorn_name("Q", chef_env: "ci",   rails_env: 'test').should ==           "Q_ci_#{local_ip}_test"
      AsyncJobQueue.adorn_name("Q", chef_env: "ci",   rails_env: 'production').should ==     "Q_ci_#{local_ip}_production"
      AsyncJobQueue.adorn_name("Q", chef_env: "master", rails_env: 'development').should ==  "Q_master_#{local_ip}_development"
      AsyncJobQueue.adorn_name("Q", chef_env: "master", rails_env: 'test').should ==         "Q_master_#{local_ip}_test"
      AsyncJobQueue.adorn_name("Q", chef_env: "master", rails_env: 'production').should ==   "Q_master"
      AsyncJobQueue.adorn_name("Q", chef_env: "staging", rails_env: 'development').should == "Q_staging_#{local_ip}_development"
      AsyncJobQueue.adorn_name("Q", chef_env: "staging", rails_env: 'test').should ==        "Q_staging_#{local_ip}_test"
      AsyncJobQueue.adorn_name("Q", chef_env: "staging", rails_env: 'production').should ==  "Q_staging"
      AsyncJobQueue.adorn_name("Q", chef_env: "prod", rails_env: 'development').should ==    "Q_prod_#{local_ip}_development"
      AsyncJobQueue.adorn_name("Q", chef_env: "prod", rails_env: 'test').should ==           "Q_prod_#{local_ip}_test"
      AsyncJobQueue.adorn_name("Q", chef_env: "prod", rails_env: 'production').should ==     "Q_prod"
    end
  end



  describe "instances" do

    it "should have an SQS attribute" do
      AsyncJobQueue.new.sqs.should be_an(AWS::SQS)
    end

    it "should all use the same AWS::SQS instance" do
      the_sqs = AsyncJobQueue.new.sqs
      AsyncJobQueue.new.sqs.should == the_sqs
      AsyncJobQueue.new.sqs.should == the_sqs
      AsyncJobQueue.new.sqs.should == the_sqs
    end


    it "should have a queue attribute" do
      AsyncJobQueue.new.queue.should be_an Object
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
      q.receive_message(visibility_timeout: 60).should be_a QueueMessage
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
      q.poll(visibility_timeout: 60).should be_a QueueMessage
      expect(q.queue).to have_received(:poll).with({:attributes=>[:receive_count], :visibility_timeout=>60, :limit=>1})
    end

    it "should poll from the AWS queue, using a block" do
      q = AsyncJobQueue.new
      q.poll(visibility_timeout: 60) { |msg| puts msg.body }
      expect(q.queue).to have_received(:poll).with({:attributes=>[:receive_count], :visibility_timeout=>60, :limit=>1})
    end
  end

end
