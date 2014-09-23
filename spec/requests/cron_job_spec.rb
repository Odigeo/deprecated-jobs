require 'spec_helper'

describe CronJob, :type => :request do

  describe "execute_cron_jobs" do

    it "should not require authentication" do
      allow(Object).to receive(:sleep)
      CronJob.delete_all
      create :cron_job, cron: "* * * * *"  # Always due :)
      expect(CronJob.count).to be 1
      expect(OceanApplicationController).to_not receive :require_x_api_token
      expect(OceanApplicationController).to_not receive :authorize_action
      expect_any_instance_of(CronJob).to receive(:post_async_job)
      put "/execute_cron_jobs", 
          {}, 
          {'HTTP_ACCEPT' => "application/json", 'X-API-TOKEN' => "incredibly-fake"}
      CronJob.delete_all
    end
  end


  describe "run" do

    it "should create an AsyncJob" do
      expect(AsyncJob).to receive(:create!)
      job = create :cron_job, id: 'a-b-c-d-e'
      permit_with 200
      put "/v1/cron_jobs/a-b-c-d-e/run", 
          {}, 
          {'HTTP_ACCEPT' => "application/json", 'X-API-TOKEN' => "incredibly-fake"}
      expect(response.status).to eq 204
      expect(response.body).to be_blank
    end

  end
end 
