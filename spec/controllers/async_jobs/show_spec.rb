require 'spec_helper'

describe AsyncJobsController, :type => :controller do
  
  render_views


  describe "GET" do
    
    before :each do
      permit_with 200
      @async_job = create :async_job
      request.headers['HTTP_ACCEPT'] = "application/json"
      request.headers['X-API-Token'] = "totally-fake"
      request.headers['If-None-Match'] = 'e65ae6734803fa'
    end

    
    it "should return JSON" do
      get :show, id: @async_job.uuid
      expect(response.content_type).to eq "application/json"
    end
    
    it "should return a 400 if the X-API-Token header is missing" do
      request.headers['X-API-Token'] = nil
      get :show, id: @async_job.uuid
      expect(response.status).to eq 400
      expect(response.content_type).to eq "application/json"
    end
    
    it "should return a 404 when the user can't be found" do
      get :show, id: -1
      expect(response.status).to eq 404
      expect(response.content_type).to eq "application/json"
    end
    
    it "should return a 200 when successful" do
      get :show, id: @async_job.uuid
      expect(response.status).to eq 200
      expect(response).to render_template(partial: "_async_job", count: 1)
    end

    it "should return a different ETag when updated" do
      get :show, id: @async_job.uuid
      expect(response.status).to eq 200
      etag = response.headers['ETag']
      bod = response.body
      @async_job.save!
      get :show, id: @async_job.uuid
      expect(response.status).to eq 200
      expect(response.body).not_to eq bod
      expect(response.headers['ETag']).not_to eq etag
    end


  end
  
end
