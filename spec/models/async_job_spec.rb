# == Schema Information
#
# Table name: async_jobs
#
#  id           :integer          not null, primary key
#  uuid         :string(255)      not null
#  restarts     :integer          default(0), not null
#  state        :string(255)      default(""), not null
#  started_at   :datetime
#  finished_at  :datetime
#  payload      :text             default("{}"), not null
#  lock_version :integer          default(0), not null
#  created_by   :integer          default(0), not null
#  updated_by   :integer          default(0), not null
#  created_at   :datetime
#  updated_at   :datetime
#

require 'spec_helper'

describe AsyncJob do


  describe "attributes" do
    
    it "should have an UUID" do
      create(:async_job).uuid.should be_a String
    end

    it "should have a restart count" do
      create(:async_job).restarts.should be_an Integer
    end

    it "should have a state" do
      create(:async_job).state.should be_a String
    end

    it "should have a start time" do
      create(:async_job, started_at: nil).started_at.should == nil
    end

    it "should have a finish time" do
      create(:async_job, finished_at: nil).finished_at.should == nil
    end

    it "should have a payload" do
      create(:async_job, payload: "{}").payload.should == "{}"
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

  end


  describe "relations" do

    before :each do
      AsyncJob.destroy_all
    end


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
