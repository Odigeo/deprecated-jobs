# == Schema Information
#
# Table name: async_jobs
#
#  id                   :integer          not null, primary key
#  uuid                 :string(255)      not null
#  started_at           :datetime
#  finished_at          :datetime
#  steps                :text
#  lock_version         :integer          default(0), not null
#  created_by           :integer          default(0), not null
#  updated_by           :integer          default(0), not null
#  created_at           :datetime
#  updated_at           :datetime
#  last_completed_step  :integer
#  max_seconds_in_queue :integer          default(86400), not null
#  destroy_at           :datetime
#  default_poison_limit :integer          default(5), not null
#  credentials          :string(255)      default(""), not null
#  default_step_time    :integer          default(30), not null
#

require 'spec_helper'

describe AsyncJob do


  describe "attributes" do
    
    it "should have an UUID" do
      create(:async_job).uuid.should be_a String
    end

    it "should require UUIDs to be unique" do
      create(:async_job, uuid: "blahonga")
      lambda { create(:async_job, uuid: "blahonga") }.should raise_error
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

  end


  describe "search" do
  
    describe ".collection" do
    
      before :each do
        create :async_job, uuid: 'foo'
        create :async_job, uuid: 'bar'
        create :async_job, uuid: 'baz'
      end
      
    
      it "should return an array of AsyncJob instances" do
        ix = AsyncJob.collection
        ix.length.should == 3
        ix[0].should be_a AsyncJob
      end
    
      it "should allow matches on uuid" do
        AsyncJob.collection(uuid: 'NOWAI').length.should == 0
        AsyncJob.collection(uuid: 'bar').length.should == 1
        AsyncJob.collection(uuid: 'baz').length.should == 1
      end
      
      it "should not allow searches" do
        AsyncJob.collection(search: 'b').length.should == 0
        AsyncJob.collection(search: 'z').length.should == 0
      end
      
      it "key/value pairs not in the index_only array should quietly be ignored" do
        AsyncJob.collection(uuid: 'bar', aardvark: 12).length.should == 1
      end
        
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

    it "#current_step should obtain the current step" do
      @j.current_step.should == {'name' => "Step 1"}
      @j.last_completed_step = 0
      @j.current_step.should == {'name' => "Step 2", 'poison_limit' => 50}
      @j.last_completed_step = 1
      @j.current_step.should == {'name' => "Step 3", 'step_time' => 2.minutes}
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
  end


  describe "queue handling" do

    it "should have an enqueue method" do

    end

  end

end
