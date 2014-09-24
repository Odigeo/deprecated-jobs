require 'spec_helper'

describe AsyncJob, :type => :model do

  describe "attributes" do
    
    it "should have an UUID" do
      expect(create(:async_job).uuid).to be_a String
    end

    it "should assign an UUID to the hash_key attribute if nil at create" do
      i = build :async_job, uuid: nil
      expect(i.save).to eq true
      expect(i.uuid).not_to be_blank
    end

    it "should have a start time" do
      expect(create(:async_job, started_at: Time.now.utc).started_at).to be_a Time
    end

    it "should have a start time" do
      expect(create(:async_job, started_at: Time.now.utc).started_at).to be_a Time
    end

    it "should have a finish time" do
      expect(create(:async_job, finished_at: nil).finished_at).to eq nil
    end

    it "should have a steps array" do
     expect_any_instance_of(AsyncJob).to receive(:enqueue)
     expect(create(:async_job, steps: [{}, {}, {}]).steps).to eq [{}, {}, {}]
    end

    it "should have a creation time" do
      expect(create(:async_job).created_at).to be_a Time
    end

    it "should have an update time" do
      expect(create(:async_job).updated_at).to be_a Time
    end
  
    it "should have a creator" do
      expect(create(:async_job).created_by).to eq ""
    end

    it "should have an updater" do
      expect(create(:async_job).updated_by).to eq ""
    end

    it "should have a last_completed_step attribute" do
      expect(create(:async_job).last_completed_step).to eq nil
      expect(create(:async_job, last_completed_step: 2).last_completed_step).to eq 2
    end

    it "should have a max_seconds_in_queue of 1 day" do
      expect(create(:async_job).max_seconds_in_queue).to eq 1.day
    end

    it "should have a destroy_at time" do
      expect(create(:async_job).destroy_at).to be_a Time
    end

    it "should set a destroy_at time automatically from the max_seconds_in_queue value" do
      j = create :async_job
      expect(j.destroy_at.to_i).to be_within(1).of((j.created_at + j.max_seconds_in_queue).to_i)
    end

    it "should have a default poison_limit of 5" do
      expect(create(:async_job).default_poison_limit).to eq 5
      expect(create(:async_job, default_poison_limit: 10).default_poison_limit).to eq 10
    end

    it "should have a required credentials attribute" do
      expect(create(:async_job).credentials).to be_a String
      expect(build(:async_job, credentials: nil)).not_to be_valid
    end

    it "should require the credentials to be unscramblable (is that a word?)" do
      expect(build(:async_job, credentials: 'bWFnbmV0bzp4YXZpZXI=')).to be_valid
      expect(build(:async_job, credentials: 'blahonga')).not_to be_valid
    end

    it "should only require the credentials at creation time" do
      j = create :async_job, credentials: 'bWFnbmV0bzp4YXZpZXI='
      expect(j).to be_valid
      j.credentials = ""
      expect(j).to be_valid
      j.save!
    end

    it "should have an optional token attribute" do
      expect(create(:async_job).token).to be_a String
      expect(create(:async_job, token: nil).token).to eq nil
    end

    it "should have a last_status attribute" do
      expect(create(:async_job)).to respond_to :last_status
    end
    
    it "should have a last_headers attribute" do
      expect(create(:async_job)).to respond_to :last_headers
    end
    
    it "should have a last_body attribute" do
      expect(create(:async_job)).to respond_to :last_body
    end

    it "should have a poison_email attribute" do
      expect(create(:async_job)).to respond_to :poison_email
    end

    it "should allow blank poison_email addresses" do
      expect(build(:async_job, poison_email: "")).to be_valid
    end

    it "should require a valid poison_email address" do
      expect(build(:async_job, poison_email: "john@@doe")).not_to be_valid
    end

    it "should not consider poison_email addresses with names valid" do
      expect(build(:async_job, poison_email: "John Doe <john@doe.com>")).not_to be_valid
    end
  end


  describe "step handling" do

    before :each do
      expect_any_instance_of(AsyncJob).to receive(:enqueue)
      @j = create(:async_job, steps: [{'name' => "Step 1"}, 
                                      {'name' => "Step 2", 'poison_limit' => 50}, 
                                      {'name' => "Step 3", 'step_time' => 2.minutes}],
                              poison_email: "someone@example.com")
    end

    it "should have a finished? predicate" do
      expect(Api).to receive(:send_mail)
      expect(@j.finished?).to eq false
      @j.job_is_poison
      @j.reload(consistent: true)
      expect(@j.finished?).to eq true
    end

    it "should have a success? predicate" do
      expect(@j.finished?).to eq false
      @j.job_succeeded
      @j.reload(consistent: true)
      expect(@j.succeeded?).to eq true
    end

    it "should have a failure? predicate" do
      expect(@j.finished?).to eq false
      @j.job_failed
      @j.reload(consistent: true)
      expect(@j.failed?).to eq true
    end

    it "should have a poison? predicate" do
      expect(Api).to receive(:send_mail)
      expect(@j.finished?).to eq false
      @j.job_is_poison
      @j.reload(consistent: true)
      expect(@j.poison?).to eq true
    end

    it "should have a job_succeeded method that finishes the job" do
      @j.job_succeeded
      @j.reload(consistent: true)
      expect(@j.finished?).to eq true
      expect(@j.succeeded?).to eq true
      expect(@j.failed?).to eq false
      expect(@j.poison?).to eq false
    end

    it "should have a job_failed method to finish a job" do
      @j.job_failed
      @j.reload(consistent: true)
      expect(@j.finished?).to eq true
      expect(@j.failed?).to eq true
      expect(@j.succeeded?).to eq false
      expect(@j.poison?).to eq false
    end

    it "#job_failed should take an optional message to log" do
      @j.job_failed "And this is why."
      expect(@j.current_step['log']).to eq ["And this is why."]
    end

    it "should have a job_is_poison method to finish a job" do
      expect(Api).to receive(:send_mail)
      @j.job_is_poison
      @j.reload(consistent: true)
      expect(@j.finished?).to eq true
      expect(@j.failed?).to eq true
      expect(@j.succeeded?).to eq false
      expect(@j.poison?).to eq true
    end

    it "should send mail to poison_email whenever a job becomes poison and poison_email is present" do
      expect(Api).to receive(:send_mail)
      @j.job_is_poison
    end

    it "should not send mail to poison_email whenever a job becomes poison and poison_email is blank" do
      expect(Api).not_to receive(:send_mail)
      @j.poison_email = ""
      @j.job_is_poison
    end



    it "#current_step should obtain the current step" do
      expect(@j.current_step['name']).to eq "Step 1"
      @j.last_completed_step = 0
      expect(@j.current_step['name']).to eq "Step 2"
      @j.last_completed_step = 1
      expect(@j.current_step['name']).to eq "Step 3"
      @j.last_completed_step = 2
      expect(@j.current_step).to eq nil
      @j.last_completed_step = 200000
      expect(@j.current_step).to eq nil
    end

    it "#done_all_steps? should return true if the job has no remaining steps" do
      expect(create(:async_job).done_all_steps?).to eq true
    end

    it "#current_step_done! should advance state to the next job step" do
      expect(@j.last_completed_step).to eq nil
      @j.current_step_done!
      expect(@j.last_completed_step).to eq 0
      @j.current_step_done!
      expect(@j.last_completed_step).to eq 1
      @j.current_step_done!
      expect(@j.last_completed_step).to eq 2
      @j.current_step_done!
      expect(@j.last_completed_step).to eq 2
      @j.current_step_done!
      expect(@j.last_completed_step).to eq 2
    end

    it "#current_step_done! should finish the job if no steps remain" do
      @j.current_step_done!
      expect(@j.finished_at).to eq nil      
      @j.current_step_done!
      expect(@j.finished_at).to eq nil      
      @j.current_step_done!
      expect(@j.finished_at).not_to eq nil      
      @j.reload(consistent: true)
      expect(@j.finished?).to eq true
      expect(@j.failed?).to eq false
      expect(@j.succeeded?).to eq true
      expect(@j.poison?).to eq false
    end

    it "#poison_limit should return the poison limit for the current job step" do
      expect(@j.poison_limit).to eq 5
      @j.current_step_done!
      expect(@j.poison_limit).to eq 50
      @j.current_step_done!
      expect(@j.poison_limit).to eq 5
    end

    it "#step_time should return the step time for the current job step" do
      expect(@j.step_time).to eq @j.default_step_time
      @j.current_step_done!
      expect(@j.step_time).to eq @j.default_step_time
      @j.current_step_done!
      expect(@j.step_time).to eq 2.minutes
    end

    it "#log should log to the current step" do
      @j.log("Log data")
      @j.log("Some more")
      expect(@j.current_step['log']).to eq ["Log data", "Some more"]
    end

    it "#log should return its string argument" do
      expect(@j.log("Log data")).to eq "Log data"
    end
  end


  describe "BAN handling" do

    it "should ban after a save" do
      j = create :async_job
      expect(Api).to receive(:ban).with("/v[0-9]+/async_jobs/#{j.uuid}($|/|\\?)")
      j.save!
    end

    it "should ban after a destroy" do
      j = create :async_job
      expect(Api).to receive(:ban).with("/v[0-9]+/async_jobs/#{j.uuid}($|/|\\?)")
      j.destroy
    end
  end


  describe "cleanup" do

    it "should purge all AsyncJobs past their expiry time" do
      AsyncJob.delete_all
      create :async_job, destroy_at: Time.now.utc + 1.year
      create :async_job, destroy_at: 2.days.ago
      create :async_job, destroy_at: Time.now.utc + 1.year
      create :async_job, destroy_at: 1.minute.ago
      create :async_job, destroy_at: Time.now.utc + 1.year
      expect(AsyncJob.count).to eq 5
      expect(Rails.logger).to receive(:info).with("Cleaned up 2 old AsyncJobs")
      AsyncJob.cleanup
      expect(AsyncJob.count).to eq 3
      AsyncJob.delete_all
    end
  end

end
