require 'spec_helper'

describe AsyncJobsController, :type => :controller do
  
  render_views
  

  describe "delete" do

    before :each do
      AsyncJob.delete_all
      create :async_job, destroy_at: Time.now.utc + 1.year
      create :async_job, destroy_at: 2.days.ago
      create :async_job, destroy_at: Time.now.utc + 1.year
      create :async_job, destroy_at: 1.minute.ago
      create :async_job, destroy_at: Time.now.utc + 1.year
      permit_with 200
      request.headers['HTTP_ACCEPT'] = "application/json"
      request.headers['X-API-Token'] = "so-totally-fake"
    end

    
    it "should return JSON" do
      put :cleanup
      expect(response.content_type).to eq "application/json"
    end

    it "should return a 400 if the X-API-Token header is missing" do
      request.headers['X-API-Token'] = nil
      put :cleanup
      expect(response.status).to eq 400
    end
    
    it "should return a 204 when successful" do
      expect(Rails.logger).to receive(:info).with("Cleaned up 2 old AsyncJobs")
      put :cleanup
      expect(response.status).to eq 204
      expect(response.content_type).to eq "application/json"
    end

    it "should return a 204 when there are no AsyncJobs to be purged" do
      AsyncJob.delete_all
      expect(Rails.logger).to receive(:info).with("Cleaned up 0 old AsyncJobs")
      put :cleanup
      expect(response.status).to eq 204
      expect(response.content_type).to eq "application/json"
    end

  end

end
