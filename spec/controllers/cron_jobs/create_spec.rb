require 'spec_helper'

describe CronJobsController, :type => :controller do
  
  render_views
  

  describe "POST" do

    before :each do
      CronJob.delete_all
      permit_with 200
      request.headers['HTTP_ACCEPT'] = "application/json"
      request.headers['X-API-Token'] = "incredibly-fake!"
      @args = build(:cron_job).attributes   # 'uuid' needs to be unique in the DB
    end
    
    
    it "should return JSON" do
      post :create, @args
      expect(response.content_type).to eq "application/json"
    end
    
    it "should return a 400 if the X-API-Token header is missing" do
      request.headers['X-API-Token'] = nil
      post :create, @args
      expect(response.status).to eq 400
    end
    
    it "should return a 422 when there are validation errors" do
      post :create, @args.merge('credentials' => "qz")
      expect(response.status).to eq 422
      expect(response.content_type).to eq "application/json"
      expect(JSON.parse(response.body)).not_to eq({"_api_error"=>["Resource not unique"]})
      expect(JSON.parse(response.body)).to eq({"credentials"=>["are malformed"]})
    end
                
    it "should return a 201 when successful" do
      post :create, @args
      expect(response).to render_template(partial: "_cron_job", count: 1)
      expect(response.status).to eq 201
    end

    it "should contain a Location header when successful" do
      post :create, @args
      expect(response.headers['Location']).to be_a String
    end

    it "should return the new resource in the body when successful" do
      post :create, @args
      expect(response.body).to be_a String
    end

  end

end
