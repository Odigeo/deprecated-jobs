require 'spec_helper'

describe AsyncJobsController, :type => :controller do
  
  render_views


  describe "DELETE" do
    
    before :each do
      permit_with 200
      @async_job = create :async_job
      request.headers['HTTP_ACCEPT'] = "application/json"
      request.headers['X-API-Token'] = "so-totally-fake"
    end

    
    it "should return JSON" do
      delete :destroy, id: @async_job.uuid
      expect(response.content_type).to eq "application/json"
    end

    it "should return a 400 if the X-API-Token header is missing" do
      request.headers['X-API-Token'] = nil
      delete :destroy, id: @async_job.uuid
      expect(response.status).to eq 400
    end
    
    it "should return a 204 when successful" do
      delete :destroy, id: @async_job.uuid
      expect(response.status).to eq 204
      expect(response.content_type).to eq "application/json"
    end

    it "should return a 404 when the AsyncJob can't be found" do
      delete :destroy, id: 'a-a-a-a-a'
      expect(response.status).to eq 404
    end
    
    it "should destroy the AsyncJob when successful" do
      delete :destroy, id: @async_job.uuid
      expect(response.status).to eq 204
    end
    
  end
  
end
