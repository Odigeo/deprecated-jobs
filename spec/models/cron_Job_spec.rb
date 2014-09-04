require 'spec_helper'

describe CronJob do

  describe "attributes" do
    
    it "should have a UUID" do
      create(:cron_job).id.should be_a String
    end

    it "should assign a UUID to the hash_key attribute if nil at create" do
      i = build :cron_job, id: nil
      i.save.should == true
      i.id.should_not be_blank
    end

    it "should have a creation time" do
      create(:cron_job).created_at.should be_a Time
    end

    it "should have an update time" do
      create(:cron_job).updated_at.should be_a Time
    end
  
    it "should have a creator" do
      create(:cron_job).created_by.should == ""
    end

    it "should have an updater" do
      create(:cron_job).updated_by.should == ""
    end


    it "should have a required credentials attribute" do
      create(:cron_job).credentials.should be_a String
      build(:cron_job, credentials: nil).should_not be_valid
    end

    it "should require the credentials to be unscramblable (is that a word?)" do
      build(:cron_job, credentials: 'bWFnbmV0bzp4YXZpZXI=').should be_valid
      build(:cron_job, credentials: 'blahonga').should_not be_valid
    end

    it "should only require the credentials at creation time" do
      j = create :cron_job, credentials: 'bWFnbmV0bzp4YXZpZXI='
      j.should be_valid
      j.credentials = ""
      j.should be_valid
      j.save!
    end

    it "should have an optional token attribute" do
      create(:cron_job).token.should be_a String
      create(:cron_job, token: nil).token.should == nil
    end


    it "should have a steps array" do
     create(:cron_job, steps: [{}, {}, {}]).steps.should == [{}, {}, {}]
    end


    it "should have a CRON expression" do
      create(:cron_job).cron.should be_a String
      build(:cron_job, cron: nil).should_not be_valid
    end

    it "should have a minutes attribute" do
      build(:cron_job).should respond_to(:minutes)
    end

    it "should have a hours attribute" do
      build(:cron_job).should respond_to(:hours)
    end

    it "should have a day_of_month attribute" do
      build(:cron_job).should respond_to(:day_of_month)
    end

    it "should have a month attribute" do
      build(:cron_job).should respond_to(:month)
    end

    it "should have a day_of_week attribute" do
      build(:cron_job).should respond_to(:day_of_week)
    end


    it "should have a lock_version attribute" do
      build(:cron_job).should respond_to(:lock_version)
    end

  end

  
  
end
