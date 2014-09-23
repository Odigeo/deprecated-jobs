require 'spec_helper'

describe CronJobsController, :type => :controller do
  
  render_views
  

  describe "run" do

    before :each do
      CronJob.delete_all
      permit_with 200
      request.headers['HTTP_ACCEPT'] = "application/json"
      request.headers['X-API-Token'] = "incredibly-fake!"
      @u = create :cron_job
    end
     

    it "should return JSON" do
      put :run, id: @u
      expect(response.content_type).to eq "application/json"
    end
    
    it "should return a 400 if the X-API-Token header is missing" do
      request.headers['X-API-Token'] = nil
      put :run, id: @u
      expect(response.status).to eq 400
    end

    it "should return a 404 if the resource can't be found" do
      put :run, id: "a-b-c-d-e"
      expect(response.status).to eq 404
      expect(response.content_type).to eq "application/json"
    end

    it "should return a 404 if the CronJob is the lock record" do
      create :cron_job, id: CronJob::TABLE_LOCK_RECORD_ID
      put :run, id: CronJob::TABLE_LOCK_RECORD_ID
      expect(response.status).to eq 404
      expect(response.content_type).to eq "application/json"
    end

    it "should return a 204 when successful" do
      put :run, id: @u
      expect(response.status).to eq 204
    end

    it "should post an AsyncJob when successful" do
      expect(AsyncJob).to receive(:create!)
      put :run, id: @u
      expect(response.status).to eq 204
    end
  end
end
