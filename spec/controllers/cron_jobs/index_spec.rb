require 'spec_helper'

describe CronJobsController, :type => :controller do
  
  render_views
  

  describe "index" do

    before :each do
      CronJob.delete_all
      permit_with 200
      create :cron_job
      create :cron_job
      create :cron_job
      request.headers['HTTP_ACCEPT'] = "application/json"
      request.headers['X-API-Token'] = "boy-is-this-fake"
    end
    
    it "should return JSON" do
      get :index
      expect(response.content_type).to eq "application/json"
    end
    
    it "should return a 400 if the X-API-Token header is missing" do
      request.headers['X-API-Token'] = nil
      get :index
      expect(response.status).to eq 400
      expect(response.content_type).to eq "application/json"
    end
    
    it "should return a 400 if the authentication represented by the X-API-Token can't be found" do
      request.headers['X-API-Token'] = 'unknown, matey'
      allow(Api).to receive(:permitted?).and_return(double(:status => 400, :body => {:_api_error => []}))
      get :index
      expect(response.status).to eq 400
      expect(response.content_type).to eq "application/json"
    end
    
    it "should return a 403 if the X-API-Token doesn't authorise" do
      allow(Api).to receive(:permitted?).and_return(double(:status => 403, :body => {:_api_error => []}))
      get :index
      expect(response.status).to eq 403
      expect(response.content_type).to eq "application/json"
    end
        
    it "should return a 200 when successful" do
      get :index
      expect(response.status).to eq 200
    end
    
    it "should render the object partial when successful" do
      get :index
      expect(response).to render_template(partial: '_cron_job', count: 3)
    end

  end

end
