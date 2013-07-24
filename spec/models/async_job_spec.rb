# == Schema Information
#
# Table name: async_jobs
#
#  id                   :integer          not null, primary key
#  uuid                 :string(255)      not null
#  restarts             :integer          default(0), not null
#  started_at           :datetime
#  finished_at          :datetime
#  steps                :text
#  lock_version         :integer          default(0), not null
#  created_by           :integer          default(0), not null
#  updated_by           :integer          default(0), not null
#  created_at           :datetime
#  updated_at           :datetime
#  invisible_until      :datetime
#  last_completed_step  :integer
#  max_seconds_in_queue :integer          default(86400), not null
#  destroy_at           :datetime
#  poison_limit         :integer          default(5), not null
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

    it "should have a restart count" do
      create(:async_job).restarts.should be_an Integer
    end

    it "should have a start time" do
      create(:async_job, started_at: Time.now.utc).started_at.should be_a Time
    end

    it "should have a finish time" do
      create(:async_job, finished_at: nil).finished_at.should == nil
    end

    it "should have a steps array" do
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

    it "should have an invisible_until time" do
      create(:async_job).invisible_until.should == nil
      create(:async_job, invisible_until: 30.minutes.from_now.utc).invisible_until.should be_a Time
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
      j.destroy_at.to_i.should == (j.created_at + j.max_seconds_in_queue).to_i
    end

    it "should have a default poison_limit of 5" do
      create(:async_job).poison_limit.should == 5
      create(:async_job, poison_limit: 10).poison_limit.should == 10
    end

  end


  describe "relations" do

    before :each do
      AsyncJob.destroy_all
    end

  end


  it "should have a visible scope" do
    AsyncJob.visible.should == []
  end

  it "should have an invisible scope" do
    AsyncJob.invisible.should == []
  end



  describe "search" do
    describe ".index_only" do
      it "should return an array of permitted search query args" do
        AsyncJob.index_only.should be_an Array
      end
    end
  
    describe ".index" do
    
      before :each do
        create :async_job, uuid: 'foo'
        create :async_job, uuid: 'bar'
        create :async_job, uuid: 'baz'
      end
      
    
      it "should return an array of AsyncJob instances" do
        ix = AsyncJob.index
        ix.length.should == 3
        ix[0].should be_a AsyncJob
      end
    
      it "should allow matches on uuid" do
        AsyncJob.index(uuid: 'NOWAI').length.should == 0
        AsyncJob.index(uuid: 'bar').length.should == 1
        AsyncJob.index(uuid: 'baz').length.should == 1
      end
      
      it "should allow searches on uuid" do
        AsyncJob.index({}, nil, 'b').length.should == 2
        AsyncJob.index({}, nil, 'z').length.should == 1
      end
      
      it "key/value pairs not in the index_only array should quietly be ignored" do
        AsyncJob.index(uuid: 'bar', aardvark: 12).length.should == 1
      end
        
    end
  end

end
