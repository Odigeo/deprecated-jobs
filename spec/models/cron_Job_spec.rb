require 'spec_helper'

describe CronJob, :type => :model do

  before :each do
    CronJob.delete_all
    AsyncJob.delete_all
    allow(Object).to receive(:sleep)
  end

  after :each do
    CronJob.delete_all
    AsyncJob.delete_all
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

    it "should not have a token attribute" do
      expect(create(:cron_job)).to_not respond_to :token
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

    it "should have a max_seconds_in_queue attribute" do
      expect(create(:cron_job).max_seconds_in_queue).to eq 1.day
    end

    it "should have a default_poison_limit attribute" do
      expect(create(:cron_job).default_poison_limit).to eq 5
    end

    it "should have a default_step_time attribute" do
      expect(create(:cron_job).default_step_time).to eq 30
    end

    it "should have a last_run_at time" do
      expect(build(:cron_job)).to respond_to(:last_run_at)
    end

    it "should have a last_async_job_id attribute" do
      expect(build(:cron_job)).to respond_to(:last_async_job_id)
    end

    it "should have a poison_email attribute" do
      expect(create(:cron_job)).to respond_to :poison_email
    end

    it "should allow blank poison_email addresses" do
      expect(build(:cron_job, poison_email: "")).to be_valid
    end

    it "should require a valid poison_email address" do
      expect(build(:cron_job, poison_email: "john@@doe")).not_to be_valid
    end

    it "should not consider poison_email addresses with names valid" do
      expect(build(:cron_job, poison_email: "John Doe <john@doe.com>")).not_to be_valid
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
      expect(cj.match_component({"exactly" => 5}, 5)).to eq true
      expect(cj.match_component({"exactly" => 5}, -5)).to eq false
    end

    it "should handle ranges" do
      cj = create :cron_job, cron: "* * * * *"
      expect(cj.match_component({"range" => [0, 59]}, 0)).to eq true
      expect(cj.match_component({"range" => [0, 59]}, 5)).to eq true
      expect(cj.match_component({"range" => [0, 59]}, 59)).to eq true
      expect(cj.match_component({"range" => [0, 59]}, -5)).to eq false
      expect(cj.match_component({"range" => [0, 59]}, 500)).to eq false
    end

    it "should handle ranges with intervals" do
      cj = create :cron_job, cron: "* * * * *"
      expect(cj.match_component({"range" => [1, 59], "interval" => 3}, 0)).to eq false
      expect(cj.match_component({"range" => [1, 59], "interval" => 3}, 1)).to eq true
      expect(cj.match_component({"range" => [1, 59], "interval" => 3}, 2)).to eq false
      expect(cj.match_component({"range" => [1, 59], "interval" => 3}, 3)).to eq false
      expect(cj.match_component({"range" => [1, 59], "interval" => 3}, 4)).to eq true
      expect(cj.match_component({"range" => [1, 59], "interval" => 3}, 5)).to eq false
      expect(cj.match_component({"range" => [1, 59], "interval" => 3}, 6)).to eq false
      expect(cj.match_component({"range" => [1, 59], "interval" => 3}, 7)).to eq true
      expect(cj.match_component({"range" => [1, 59], "interval" => 3}, 8)).to eq false
    end

    it "should handle lists" do
      cj = create :cron_job, cron: "* * * * *"
      expect(cj.match_component({"member" => [0, 95, 59]}, 0)).to eq true
      expect(cj.match_component({"member" => [0, 95, 59]}, 95)).to eq true
      expect(cj.match_component({"member" => [0, 95, 59]}, 59)).to eq true
      expect(cj.match_component({"member" => [0, 95, 59]}, 4)).to eq false
      expect(cj.match_component({"member" => [0, 95, 59]}, -5)).to eq false
      expect(cj.match_component({"member" => [0, 95, 59]}, 500)).to eq false
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

    it "should do nothing if the job is the lock record" do
      job = create :cron_job, id: CronJob::TABLE_LOCK_RECORD_ID
      expect(CronJob.count).to eq 1
      expect(job).to_not receive(:due?)
      expect(job).to_not receive(:post_async_job)
      job.process_job
    end

    it "should do nothing unless the job is enabled" do
      job = create :cron_job, enabled: false
      expect(CronJob.count).to eq 1
      expect(job).to_not receive(:due?)
      expect(job).to_not receive(:post_async_job)
      job.process_job
    end

    it "should do nothing unless the time is due" do
      job = create :cron_job
      expect(CronJob.count).to eq 1
      expect(job).to receive(:due?).and_return(false)
      expect(job).to_not receive(:post_async_job)
      job.process_job
    end

    describe "when it runs a cron job" do

      it "should call post_async_job" do
        job = create :cron_job
        expect(CronJob.count).to eq 1
        expect(job).to receive(:due?).and_return(true)
        expect(job).to receive(:post_async_job).and_return "the-async-job-uuid"
        job.process_job
      end

      it "should set the last_run_at attribute" do
        job = create :cron_job
        expect(CronJob.count).to eq 1
        expect(job).to receive(:due?).and_return(true)
        expect(job).to receive(:post_async_job).and_return "the-async-job-uuid"
        expect(job).to receive(:last_run_at=).with(an_instance_of Time)
        expect(job).to receive(:save!)
        job.process_job
      end

      it "should set the last_async_job_id attribute" do
        job = create :cron_job
        expect(CronJob.count).to eq 1
        expect(job).to receive(:due?).and_return(true)
        expect(job).to receive(:post_async_job).and_return "the-async-job-uuid"
        expect(job).to receive(:last_async_job_id=).with("the-async-job-uuid")
        expect(job).to receive(:save!)
        job.process_job
      end
    end
  end


  describe "post_async_job" do
    
    it "should create an AsyncJob from the CronJob" do
      expect_any_instance_of(AsyncJob).to receive(:enqueue)
      job = create :cron_job, steps: [{}, {}]
      job.post_async_job
    end

    it "should return the AsyncJob uuid" do
      expect_any_instance_of(AsyncJob).to receive(:enqueue)
      job = create :cron_job, steps: [{}, {}]
      expect(job.post_async_job).to be_a String
    end
  end


  describe "maintain_all" do

    before :each do
      @jobs = [{"name"=>"Purge old Authentications", 
                "description"=>"Remove Authentications past their removal time.", 
                "cron"=>"@hourly", "steps"=>[{"method"=>"PUT", "url"=>"/v1/authentications/cleanup"}], 
                "enabled"=>true, "credentials"=>"emFsYWdhZG9vbGE6bWVuY2hpa2Fib29sYQ==", 
                "default_step_time"=>60, "max_seconds_in_queue"=>3600, "default_poison_limit"=>5}, 
               {"name"=>"Refresh Instance DB", 
                "description"=>"Reads live status information about Ocean instances and stores it in the local database.", 
                "cron"=>"* * * * *", "steps"=>[{"method"=>"PUT", "url"=>"/v1/instances/refresh"}], 
                "enabled"=>true, "credentials"=>"emFsYWdhZG9vbGE6bWVuY2hpa2Fib29sYQ==", 
                "default_step_time"=>10, "max_seconds_in_queue"=>3600, "default_poison_limit"=>5}, 
               {"name"=>"Purge AsyncJobs", "description"=>"Removes AsyncJobs past their destroy_at time.", 
                "cron"=>"*/10 * * * *", "steps"=>[{"method"=>"PUT", "url"=>"/v1/async_jobs/cleanup"}], 
                "enabled"=>true, "credentials"=>"emFsYWdhZG9vbGE6bWVuY2hpa2Fib29sYQ==", 
                "default_step_time"=>60, "max_seconds_in_queue"=>3600, "default_poison_limit"=>5}, 
               {"name"=>"Purge test DynamoDB tables", 
                "description"=>"Removes all DynamoDB tables used for automated tests in this environment.", 
                "cron"=>"@daily", "steps"=>[{"method"=>"DELETE", "url"=>"/v1/dynamo_tables/test_tables"}], 
                "enabled"=>true, "credentials"=>"emFsYWdhZG9vbGE6bWVuY2hpa2Fib29sYQ==", 
                "default_step_time"=>30, "max_seconds_in_queue"=>86400, "default_poison_limit"=>5}
              ]
    end

    it "should be a class method" do
      expect(CronJob).to respond_to(:maintain_all)
    end

    it "should result in the same number of CronJobs as there are elements in the input array" do
      CronJob.maintain_all @jobs
      expect(CronJob.count).to eq 4
    end

    it "should do nothing when run twice with the same data" do
      CronJob.maintain_all @jobs
      expect(CronJob.count).to eq 4
      CronJob.maintain_all @jobs
      expect(CronJob.count).to eq 4
    end

    it "should keep only the jobs described by the data" do
      CronJob.maintain_all @jobs
      expect(CronJob.count).to eq 4
      @jobs = [@jobs[0], @jobs[2], @jobs[3]]
      CronJob.maintain_all @jobs
      expect(CronJob.count).to eq 3
    end

    it "should update a job if its attributes change" do
      CronJob.maintain_all @jobs
      expect(CronJob.count).to eq 4
      @jobs[0]['default_step_time'] = 10
      expect_any_instance_of(CronJob).to receive(:update)
      CronJob.maintain_all @jobs
    end

    it "should not update a job if its attributes are unchanged" do
      CronJob.maintain_all @jobs
      expect(CronJob.count).to eq 4
      expect_any_instance_of(CronJob).to_not receive(:update)
      CronJob.maintain_all @jobs
    end

    it "should add the INTERNAL_OCEAN_API_URL to all URLs in the steps list" do
      CronJob.maintain_all @jobs
      expect(CronJob.all.first.steps.first['url'].index(INTERNAL_OCEAN_API_URL)).to eq 0
    end

  end
end
