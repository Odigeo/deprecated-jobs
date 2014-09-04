require 'spec_helper'

describe CronJob do

  describe "CRON" do
    
    it "should have six components separated by spaces" do
      build(:cron_job, cron: "* * * * * *").should be_valid
      build(:cron_job, cron: " *  * * * *      *   ").should be_valid
      build(:cron_job, cron: "* * * * *").should_not be_valid
      build(:cron_job, cron: "* * * * * * *").should_not be_valid
      build(:cron_job, cron: "").should_not be_valid
      build(:cron_job, cron: {}).should_not be_valid
    end

    it "should not share substructure between instances" do
      build(:cron_job).cron_structure.should == build(:cron_job).cron_structure
      build(:cron_job).cron_structure.should_not be_equal build(:cron_job).cron_structure
    end

    it "should populate the seconds attribute when saved" do
      build(:cron_job).seconds.should == nil
      create(:cron_job).seconds.should_not == nil
    end

    it "should populate the minutes attribute when saved" do
      build(:cron_job).minutes.should == nil
      create(:cron_job).minutes.should_not == nil
    end

    it "should populate the hours attribute when saved" do
      build(:cron_job).hours.should == nil
      create(:cron_job).hours.should_not == nil
    end

    it "should populate the day_of_month attribute when saved" do
      build(:cron_job).day_of_month.should == nil
      create(:cron_job).day_of_month.should_not == nil
    end

    it "should populate the month attribute when saved" do
      build(:cron_job).month.should == nil
      create(:cron_job).month.should_not == nil
    end

    it "should populate the day_of_week attribute when saved" do
      build(:cron_job).day_of_week.should == nil
      create(:cron_job).day_of_week.should_not == nil
    end

  end

end