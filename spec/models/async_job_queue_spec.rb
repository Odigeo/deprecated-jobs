require 'spec_helper'

describe AsyncJobQueue do

  before :each do
    AsyncJobQueue.stub(:create_queue).and_return(double(AWS::SQS::Queue))
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
      AsyncJobQueue.new.queue.should be_an Object
    end

  end

end
