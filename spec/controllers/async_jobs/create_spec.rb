require 'spec_helper'

describe AsyncJobsController do
  
  render_views
  

  describe "POST" do
    
    before :each do
      permit_with 200
      request.headers['HTTP_ACCEPT'] = "application/json"
      request.headers['X-API-Token'] = "incredibly-fake!"
      @args = build(:async_job).attributes   # 'uuid' needs to be unique in the DB
    end
    
    
    it "should return JSON" do
      post :create, @args
      response.content_type.should == "application/json"
    end
    
    it "should return a 400 if the X-API-Token header is missing" do
      request.headers['X-API-Token'] = nil
      post :create, @args
      response.status.should == 400
    end
    
    it "should return a 422 when there are validation errors" do
      post :create, @args.merge('credentials' => "qz")
      response.status.should == 422
      response.content_type.should == "application/json"
      JSON.parse(response.body).should_not == {"_api_error"=>["Resource not unique"]}
      JSON.parse(response.body).should == {"credentials"=>["are malformed"]}
    end
                
    it "should return a 201 when successful" do
      post :create, @args
      response.should render_template(partial: "_async_job", count: 1)
      response.status.should == 201
    end

    it "should contain a Location header when successful" do
      post :create, @args
      response.headers['Location'].should be_a String
    end

    it "should return the new resource in the body when successful" do
      post :create, @args
      response.body.should be_a String
    end
    
  end
  
end
