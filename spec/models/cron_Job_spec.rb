require 'spec_helper'

describe CronJob, :type => :model do

  describe "attributes" do
    
    it "should have a UUID" do
      expect(create(:cron_job).id).to be_a String
    end

    it "should assign a UUID to the hash_key attribute if nil at create" do
      i = build :cron_job, id: nil
      expect(i.save).to eq true
      expect(i.id).not_to be_blank
    end

    it "should have a creation time" do
      expect(create(:cron_job).created_at).to be_a Time
    end

    it "should have an update time" do
      expect(create(:cron_job).updated_at).to be_a Time
    end
  
    it "should have a creator" do
      expect(create(:cron_job).created_by).to eq ""
    end

    it "should have an updater" do
      expect(create(:cron_job).updated_by).to eq ""
    end


    it "should have a required credentials attribute" do
      expect(create(:cron_job).credentials).to be_a String
      expect(build(:cron_job, credentials: nil)).not_to be_valid
    end

    it "should require the credentials to be unscramblable (is that a word?)" do
      expect(build(:cron_job, credentials: 'bWFnbmV0bzp4YXZpZXI=')).to be_valid
      expect(build(:cron_job, credentials: 'blahonga')).not_to be_valid
    end

    it "should only require the credentials at creation time" do
      j = create :cron_job, credentials: 'bWFnbmV0bzp4YXZpZXI='
      expect(j).to be_valid
      j.credentials = ""
      expect(j).to be_valid
      j.save!
    end

    it "should have an optional token attribute" do
      expect(create(:cron_job).token).to be_a String
      expect(create(:cron_job, token: nil).token).to eq nil
    end


    it "should have a steps array" do
     expect(create(:cron_job, steps: [{}, {}, {}]).steps).to eq [{}, {}, {}]
    end


    it "should have a CRON expression" do
      expect(create(:cron_job).cron).to be_a String
      expect(build(:cron_job, cron: nil)).not_to be_valid
    end

    it "should have a minutes attribute" do
      expect(build(:cron_job)).to respond_to(:minutes)
    end

    it "should have a hours attribute" do
      expect(build(:cron_job)).to respond_to(:hours)
    end

    it "should have a day_of_month attribute" do
      expect(build(:cron_job)).to respond_to(:day_of_month)
    end

    it "should have a month attribute" do
      expect(build(:cron_job)).to respond_to(:month)
    end

    it "should have a day_of_week attribute" do
      expect(build(:cron_job)).to respond_to(:day_of_week)
    end


    it "should have a lock_version attribute" do
      expect(build(:cron_job)).to respond_to(:lock_version)
    end

  end

  
  
end
