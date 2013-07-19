require 'spec_helper'

describe AsyncJobsController do
  
  render_views

  describe "INDEX" do
    
    before :each do
      Api.stub(:permitted?).and_return(double(:status => 200, 
                                               :body => {'authentication' => {'user_id' => 123}}))
      create :async_job
      create :async_job
      create :async_job
      request.headers['HTTP_ACCEPT'] = "application/json"
      request.headers['X-API-Token'] = "boy-is-this-fake"
    end

    
    it "should return JSON" do
      get :index
      response.content_type.should == "application/json"
    end
    
    it "should return a 400 if the X-API-Token header is missing" do
      request.headers['X-API-Token'] = nil
      get :index
      response.status.should == 400
      response.content_type.should == "application/json"
    end
    
    it "should return a 200 when successful" do
      get :index
      response.status.should == 200
      response.should render_template(partial: "_async_job", count: 3)
    end

    it "should accept match and search parameters" do
      AsyncJob.should_receive(:index).with(anything, nil, 'ue').and_return([])
      get :index, search: 'ue'
      response.status.should == 200
    end
        
  end
  
end
