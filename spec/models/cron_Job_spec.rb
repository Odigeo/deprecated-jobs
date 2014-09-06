require 'spec_helper'

describe CronJob, :type => :model do

  before :each do
    CronJob.delete_all
  end

  after :each do
    CronJob.delete_all
  end


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


    it "should have a cron_structure attribute" do
      expect(build(:cron_job)).to respond_to(:cron_structure)
    end


    it "should have an enabled attribute defaulting to true" do
      expect(create(:cron_job).enabled).to be true
    end

    it "should have name attribute" do
      expect(create(:cron_job).name).to eq ""
    end

    it "should have a description attribute" do
      expect(create(:cron_job).description).to eq ""
    end
  end


  describe "due?" do

    it "should exist as a predicate" do
      expect(build :cron_job).to respond_to :due?
    end

    it "should take a Time as its argument" do
      expect(create(:cron_job, cron: "* * * * *").due?(Time.now)).to be true
    end

    it "should call match_component once for each component" do
      cj = create :cron_job, cron: "* * * * *"
      expect(cj).to receive(:match_component).exactly(5).times.and_return(true)
      expect(cj.due?(Time.now.utc)).to eq true
    end

    it "should return true if all invocations of match_component return true" do
      cj = create :cron_job, cron: "* * * * *"
      expect(cj).to receive(:match_component).exactly(4).times.
        and_return(true, true, true, false)
      expect(cj.due?(Time.now.utc)).to eq false
    end

    it "should match anything to * * * * *" do
      cj = create :cron_job, cron: "* * * * *"
      expect(cj).to receive(:time_vector).and_return [0, 0, 1, 0, 0]
      expect(cj.due?(false)).to eq true
    end

    it "should match * 0-12 1-16/4 JUN,JUL,AUG,SEP MON-FRI with proper data" do
      cj = create :cron_job, cron: "* 0-12 1-16/4 JUN,JUL,AUG,SEP MON-FRI"
      expect(cj).to receive(:time_vector).and_return [57, 11, 9, 7, 2]
      expect(cj.due?(false)).to eq true
    end
  end


  describe "match_component" do

    it "should return true when given true and anything" do
      cj = create :cron_job, cron: "* * * * *"
      expect(cj.match_component(true, "BOOGALOO")).to eq true
    end

    it "should handle exact matches" do
      cj = create :cron_job, cron: "* * * * *"
      expect(cj.match_component({exactly: 5}, 5)).to eq true
      expect(cj.match_component({exactly: 5}, -5)).to eq false
    end

    it "should handle ranges" do
      cj = create :cron_job, cron: "* * * * *"
      expect(cj.match_component({range: [0, 59]}, 0)).to eq true
      expect(cj.match_component({range: [0, 59]}, 5)).to eq true
      expect(cj.match_component({range: [0, 59]}, 59)).to eq true
      expect(cj.match_component({range: [0, 59]}, -5)).to eq false
      expect(cj.match_component({range: [0, 59]}, 500)).to eq false
    end

    it "should handle ranges with intervals" do
      cj = create :cron_job, cron: "* * * * *"
      expect(cj.match_component({range: [1, 59], interval: 3}, 0)).to eq false
      expect(cj.match_component({range: [1, 59], interval: 3}, 1)).to eq true
      expect(cj.match_component({range: [1, 59], interval: 3}, 2)).to eq false
      expect(cj.match_component({range: [1, 59], interval: 3}, 3)).to eq false
      expect(cj.match_component({range: [1, 59], interval: 3}, 4)).to eq true
      expect(cj.match_component({range: [1, 59], interval: 3}, 5)).to eq false
      expect(cj.match_component({range: [1, 59], interval: 3}, 6)).to eq false
      expect(cj.match_component({range: [1, 59], interval: 3}, 7)).to eq true
      expect(cj.match_component({range: [1, 59], interval: 3}, 8)).to eq false
    end

    it "should handle lists" do
      cj = create :cron_job, cron: "* * * * *"
      expect(cj.match_component({member: [0, 95, 59]}, 0)).to eq true
      expect(cj.match_component({member: [0, 95, 59]}, 95)).to eq true
      expect(cj.match_component({member: [0, 95, 59]}, 59)).to eq true
      expect(cj.match_component({member: [0, 95, 59]}, 4)).to eq false
      expect(cj.match_component({member: [0, 95, 59]}, -5)).to eq false
      expect(cj.match_component({member: [0, 95, 59]}, 500)).to eq false
    end
  end


  describe "process_queue" do

    it "should be a class method" do
      expect(CronJob).to respond_to :process_queue
    end

    it "should try to acquire the table lock" do
      expect(CronJob).to respond_to :acquire_table_lock
      CronJob.process_queue
    end


    describe "if the lock was acquired" do

      before :each do
        expect(CronJob).to receive(:acquire_table_lock).and_return(true)
      end

      it "should call process_queue_entry on each job" do
        create :cron_job
        expect(CronJob.count).to eq 1
        expect_any_instance_of(CronJob).to receive(:process_job)
        expect(CronJob).to receive(:release_table_lock)
        CronJob.process_queue
      end

      it "should relinquish the table lock upon completion" do
        create :cron_job
        expect(CronJob.count).to eq 1
        expect_any_instance_of(CronJob).to receive(:process_job)
        expect(CronJob).to receive(:release_table_lock)
        CronJob.process_queue
      end

      it "should relinquish the table lock on an exception" do
        create :cron_job
        expect(CronJob.count).to eq 1
        expect_any_instance_of(CronJob).to receive(:process_job).and_raise("BROKEN")
        expect(CronJob).to receive(:release_table_lock)
        expect { CronJob.process_queue }.to raise_error
      end
    end


    describe "if the lock wasn't acquired" do

      it "shouldn't call process_queue_entry on each job" do
        expect(CronJob).to receive(:acquire_table_lock).and_return(false)
        create :cron_job
        expect(CronJob.count).to eq 1
        expect_any_instance_of(CronJob).to_not receive(:process_job)
        CronJob.process_queue
      end

      it "should not relinquish the table lock upon completion" do
        expect(CronJob).to receive(:acquire_table_lock).and_return(false)
        create :cron_job
        expect(CronJob.count).to eq 1
        expect_any_instance_of(CronJob).to_not receive(:process_job)
        expect(CronJob).to_not receive(:release_table_lock)
        CronJob.process_queue
      end

      it "should not relinquish the table lock on an exception" do
        expect(CronJob).to receive(:acquire_table_lock).and_raise("BROKEN")
        create :cron_job
        expect(CronJob.count).to eq 1
        expect_any_instance_of(CronJob).to_not receive(:process_job)
        expect(CronJob).to_not receive(:release_table_lock)
        expect { CronJob.process_queue }.to raise_error
      end
    end
  end


  describe "acquire_table_lock" do

    it "should not succeed twice in a row" do
      expect(CronJob.acquire_table_lock).to eq true
      expect(CronJob.acquire_table_lock).to eq false
    end

    it "should succeed again only if previously released" do
      expect(CronJob.acquire_table_lock).to eq true
      expect(CronJob.acquire_table_lock).to eq false
      CronJob.release_table_lock
      expect(CronJob.acquire_table_lock).to eq true
    end
  end


  describe "process_job" do 

    it "process_job should do nothing if the job is the lock record" do
      job = create :cron_job, id: CronJob::TABLE_LOCK_RECORD_ID
      expect(CronJob.count).to eq 1
      expect(job).to_not receive(:due?)
      expect(job).to_not receive(:post_async_job)
      job.process_job
    end

    it "process_job should do nothing unless the job is enabled" do
      job = create :cron_job, enabled: false
      expect(CronJob.count).to eq 1
      expect(job).to_not receive(:due?)
      expect(job).to_not receive(:post_async_job)
      job.process_job
    end

    it "process_job should do nothing unless the time is due" do
      job = create :cron_job
      expect(CronJob.count).to eq 1
      expect(job).to receive(:due?).and_return(false)
      expect(job).to_not receive(:post_async_job)
      job.process_job
    end

    it "process_job should call post_async_job if the time is due" do
      job = create :cron_job
      expect(CronJob.count).to eq 1
      expect(job).to receive(:due?).and_return(true)
      expect(job).to receive(:post_async_job)
      job.process_job
    end
  end


  describe "post_async_job" do
    
    

  end
end
