require 'spec_helper'

describe TheModelsController do
  
  render_views
  
  describe "POST" do
    
    before :each do
      Api.stub(:permitted?).and_return(double(:status => 200, 
                                               :body => {'authentication' => {'user_id' => 123}}))
      request.headers['HTTP_ACCEPT'] = "application/json"
      request.headers['X-API-Token'] = "incredibly-fake!"
      Api.stub(:call_p)
      @args = build(:the_model).attributes
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
    
    it "should return a 422 if the the_model already exists" do
      post :create, @args
      response.status.should == 201
      response.content_type.should == "application/json"
      post :create, @args
      response.status.should == 422
      response.content_type.should == "application/json"
      JSON.parse(response.body).should == {"_api_error" => ["TheModel already exists"]}
    end

    it "should return a 422 when there are validation errors" do
      post :create, @args.merge('name' => "qz")
      response.status.should == 422
      response.content_type.should == "application/json"
      JSON.parse(response.body).should == {"name"=>["is too short (minimum is 3 characters)"]}
    end
                
    it "should return a 201 when successful" do
      post :create, @args
      response.should render_template(partial: "_the_model", count: 1)
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
