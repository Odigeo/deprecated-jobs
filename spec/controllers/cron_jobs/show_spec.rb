require 'spec_helper'

describe CronJobsController, :type => :controller do
  
  render_views
  

  describe "show" do

    before :each do
      CronJob.delete_all
      permit_with 200
      @cron_job = create :cron_job
      request.headers['HTTP_ACCEPT'] = "application/json"
      request.headers['X-API-Token'] = "totally-fake"
      request.headers['If-None-Match'] = 'e65ae6734803fa'
    end

    
    it "should return JSON" do
      get :show, id: @cron_job.id
      expect(response.content_type).to eq "application/json"
    end
    
    it "should return a 400 if the X-API-Token header is missing" do
      request.headers['X-API-Token'] = nil
      get :show, id: @cron_job.id
      expect(response.status).to eq 400
      expect(response.content_type).to eq "application/json"
    end
    
    it "should return a 404 when the CronJob can't be found" do
      get :show, id: 'a-a-a-a-a'
      expect(response.status).to eq 404
      expect(response.content_type).to eq "application/json"
    end
    
    it "should return a 404 if the CronJob is the lock record" do
      create :cron_job, id: CronJob::TABLE_LOCK_RECORD_ID
      get :show, id: CronJob::TABLE_LOCK_RECORD_ID
      expect(response.status).to eq 404
      expect(response.content_type).to eq "application/json"
    end
    
    it "should return a 200 when successful" do
      get :show, id: @cron_job.id
      expect(response.status).to eq 200
      expect(response).to render_template(partial: "_cron_job", count: 1)
    end

    it "should return a different ETag when updated" do
      get :show, id: @cron_job.id
      expect(response.status).to eq 200
      etag = response.headers['ETag']
      bod = response.body
      @cron_job.save!
      get :show, id: @cron_job.id
      expect(response.status).to eq 200
      expect(response.body).not_to eq bod
      expect(response.headers['ETag']).not_to eq etag
    end

  end

end
