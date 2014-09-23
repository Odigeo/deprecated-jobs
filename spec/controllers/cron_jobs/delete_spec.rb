require 'spec_helper'

describe CronJobsController, :type => :controller do
  
  render_views
  

  describe "delete" do

    before :each do
      CronJob.delete_all
      permit_with 200
      @cron_job = create :cron_job
      request.headers['HTTP_ACCEPT'] = "application/json"
      request.headers['X-API-Token'] = "so-totally-fake"
    end

    
    it "should return JSON" do
      delete :destroy, id: @cron_job.id
      expect(response.content_type).to eq "application/json"
    end

    it "should return a 400 if the X-API-Token header is missing" do
      request.headers['X-API-Token'] = nil
      delete :destroy, id: @cron_job.id
      expect(response.status).to eq 400
    end
    
    it "should return a 204 when successful" do
      delete :destroy, id: @cron_job.id
      expect(response.status).to eq 204
      expect(response.content_type).to eq "application/json"
    end

    it "should return a 404 when the CronJob can't be found" do
      delete :destroy, id: 'a-a-a-a-a'
      expect(response.status).to eq 404
    end
    
    it "should return a 404 if the CronJob is the lock record" do
      create :cron_job, id: CronJob::TABLE_LOCK_RECORD_ID
      delete :destroy, id: CronJob::TABLE_LOCK_RECORD_ID
      expect(response.status).to eq 404
      expect(response.content_type).to eq "application/json"
    end

    it "should destroy the CronJob when successful" do
      delete :destroy, id: @cron_job.id
      expect(response.status).to eq 204
    end

  end

end
