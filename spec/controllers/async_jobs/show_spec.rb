require 'spec_helper'

describe AsyncJobsController do
  
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
      response.content_type.should == "application/json"
    end
    
    it "should return a 400 if the X-API-Token header is missing" do
      request.headers['X-API-Token'] = nil
      get :show, id: @async_job.uuid
      response.status.should == 400
      response.content_type.should == "application/json"
    end
    
    it "should return a 404 when the user can't be found" do
      get :show, id: -1
      response.status.should == 404
      response.content_type.should == "application/json"
    end
    
    it "should return a 428 if the request has no If-None-Match or If-Modified-Since HTTP header" do
      request.headers['If-None-Match'] = nil
      get :show, id: @async_job.uuid
      response.status.should == 428
      response.content_type.should == "application/json"
    end

    it "should return a 200 when successful" do
      get :show, id: @async_job.uuid
      response.status.should == 200
      response.should render_template(partial: "_async_job", count: 1)
    end


  end
  
end
