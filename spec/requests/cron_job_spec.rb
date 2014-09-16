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
      put "execute_cron_jobs"
      CronJob.delete_all
    end

  end

end 
