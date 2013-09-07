# == Schema Information
#
require 'spec_helper'

describe AsyncJobDyn do

  before :all do
    WebMock.allow_net_connect!
    AsyncJobDyn.establish_db_connection
  end

  after :all do
    WebMock.disable_net_connect!
  end


  describe "attributes" do
    
    it "should have an UUID" do
      create(:async_job_dyn).uuid.should be_a String
    end

    it "should have a start time" do
      create(:async_job_dyn, started_at: Time.now.utc).started_at.should be_a Time
    end

    it "should have a start time" do
      create(:async_job, started_at: Time.now.utc).started_at.should be_a Time
    end

    it "should have a finish time" do
      create(:async_job, finished_at: nil).finished_at.should == nil
    end

    it "should have a steps array" do
     AsyncJob.any_instance.should_receive(:enqueue)
     create(:async_job, steps: [1,2,3]).steps.should == [1,2,3]
    end

     it "should have a creation time" do
      create(:async_job).created_at.should be_a Time
    end

    it "should have an update time" do
      create(:async_job).updated_at.should be_a Time
    end
  
   it "should have a creator" do
      create(:async_job).created_by.should be_an Integer
    end

    it "should have an updater" do
      create(:async_job).updated_by.should be_an Integer
    end

    it "should have a last_completed_step attribute" do
      create(:async_job).last_completed_step.should == nil
      create(:async_job, last_completed_step: 2).last_completed_step.should == 2
    end

    it "should have a max_seconds_in_queue of 1 day" do
      create(:async_job).max_seconds_in_queue.should == 1.day
    end

    it "should have a destroy_at time" do
      create(:async_job).destroy_at.should be_a Time
    end

    it "should set a destroy_at time automatically from the max_seconds_in_queue value" do
      j = create :async_job
      j.destroy_at.to_i.should be_within(1).of((j.created_at + j.max_seconds_in_queue).to_i)
    end

    it "should have a default poison_limit of 5" do
      create(:async_job).default_poison_limit.should == 5
      create(:async_job, default_poison_limit: 10).default_poison_limit.should == 10
    end

    it "should have a required credentials attribute" do
      create(:async_job).credentials.should be_a String
      build(:async_job, credentials: nil).should_not be_valid
    end

    it "should require the credentials to be unscramblable (is that a word?)" do
      build(:async_job, credentials: 'bWFnbmV0bzp4YXZpZXI=').should be_valid
      build(:async_job, credentials: 'blahonga').should_not be_valid
    end

    it "should only require the credentials at creation time" do
      j = create :async_job, credentials: 'bWFnbmV0bzp4YXZpZXI='
      j.should be_valid
      j.credentials = ""
      j.should be_valid
      j.save!
    end

    it "should have an optional token attribute" do
      create(:async_job).token.should be_a String
      create(:async_job, token: nil).token.should == nil
    end
  end


  describe "step handling" do

    before :each do
      AsyncJob.any_instance.should_receive(:enqueue)
      @j = create(:async_job, steps: [{'name' => "Step 1"}, 
                                      {'name' => "Step 2", 'poison_limit' => 50}, 
                                      {'name' => "Step 3", 'step_time' => 2.minutes}
                                     ])
    end

    it "should have a finished? predicate" do
      @j.finished?.should == false
      @j.job_is_poison
      @j.reload
      @j.finished?.should == true
    end

    it "should have a success? predicate" do
      @j.finished?.should == false
      @j.job_succeeded
      @j.reload
      @j.succeeded?.should == true
    end

    it "should have a failure? predicate" do
      @j.finished?.should == false
      @j.job_failed
      @j.reload
      @j.failed?.should == true
    end

    it "should have a poison? predicate" do
      @j.finished?.should == false
      @j.job_is_poison
      @j.reload
      @j.poison?.should == true
    end

    it "should have a job_succeeded method that finishes the job" do
      @j.job_succeeded
      @j.reload
      @j.finished?.should == true
      @j.succeeded?.should == true
      @j.failed?.should == false
      @j.poison?.should == false
    end

    it "should have a job_failed method to finish a job" do
      @j.job_failed
      @j.reload
      @j.finished?.should == true
      @j.failed?.should == true
      @j.succeeded?.should == false
      @j.poison?.should == false
    end

    it "#job_failed should take an optional message to log" do
      @j.job_failed "And this is why."
      @j.current_step['log'].should == ["And this is why."]
    end

    it "should have a job_is_poison method to finish a job" do
      @j.job_is_poison
      @j.reload
      @j.finished?.should == true
      @j.failed?.should == true
      @j.succeeded?.should == false
      @j.poison?.should == true
    end



    it "#current_step should obtain the current step" do
      @j.current_step['name'].should == "Step 1"
      @j.last_completed_step = 0
      @j.current_step['name'].should == "Step 2"
      @j.last_completed_step = 1
      @j.current_step['name'].should == "Step 3"
      @j.last_completed_step = 2
      @j.current_step.should == nil
      @j.last_completed_step = 200000
      @j.current_step.should == nil
    end

    it "#done_all_steps? should return true if the job has no remaining steps" do
      create(:async_job).done_all_steps?.should == true
    end

    it "#current_step_done! should advance state to the next job step" do
      @j.last_completed_step.should == nil
      @j.current_step_done!
      @j.last_completed_step.should == 0
      @j.current_step_done!
      @j.last_completed_step.should == 1
      @j.current_step_done!
      @j.last_completed_step.should == 2
      @j.current_step_done!
      @j.last_completed_step.should == 2
      @j.current_step_done!
      @j.last_completed_step.should == 2
    end

    it "#current_step_done! should finish the job if no steps remain" do
      @j.current_step_done!
      @j.finished_at.should == nil      
      @j.current_step_done!
      @j.finished_at.should == nil      
      @j.current_step_done!
      @j.finished_at.should_not == nil      
      @j.reload
      @j.finished?.should == true
      @j.failed?.should == false
      @j.succeeded?.should == true
      @j.poison?.should == false
    end

    it "#poison_limit should return the poison limit for the current job step" do
      @j.poison_limit.should == 5
      @j.current_step_done!
      @j.poison_limit.should == 50
      @j.current_step_done!
      @j.poison_limit.should == 5
    end

    it "#step_time should return the step time for the current job step" do
      @j.step_time.should == @j.default_step_time
      @j.current_step_done!
      @j.step_time.should == @j.default_step_time
      @j.current_step_done!
      @j.step_time.should == 2.minutes
    end

    it "#log should log to the current step" do
      @j.log("Log data")
      @j.log("Some more")
      @j.current_step['log'].should == ["Log data", "Some more"]
    end

    it "#log should return its string argument" do
      @j.log("Log data").should == "Log data"
    end
  end

end
