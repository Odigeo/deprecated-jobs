require 'spec_helper'

describe CronJobsController, :type => :controller do
  
  render_views
  

  describe "update" do

    before :each do
      CronJob.delete_all
      permit_with 200
      request.headers['HTTP_ACCEPT'] = "application/json"
      request.headers['X-API-Token'] = "incredibly-fake!"
      @u = create :cron_job
      @args = @u.attributes
    end
     

    it "should return JSON" do
      put :update, @args
      expect(response.content_type).to eq "application/json"
    end
    
    it "should return a 400 if the X-API-Token header is missing" do
      request.headers['X-API-Token'] = nil
      put :update, @args
      expect(response.status).to eq 400
    end

    it "should return a 404 if the resource can't be found" do
      put :update, id: "a-b-c-d-e"
      expect(response.status).to eq 404
      expect(response.content_type).to eq "application/json"
    end

    it "should return a 422 when resource properties are missing (all must be set simultaneously)" do
      put :update, id: @u.id
      expect(response.status).to eq 422
      expect(response.content_type).to eq "application/json"
    end

    it "should return a 409 when there is an update conflict" do
      @args['lock_version'] = -2
      put :update, @args
      expect(response.status).to eq 409
    end
        
    it "should return a 200 when successful" do
      put :update, @args
      expect(response.status).to eq 200
      expect(response).to render_template(partial: "_cron_job", count: 1)
    end

    it "should return the updated resource in the body when successful" do
      put :update, @args
      expect(response.status).to eq 200
      expect(JSON.parse(response.body)).to be_a Hash
    end

    
    it "should return a 422 when there are validation errors" do
      put :update, @args.merge('cron' => "* * *")
      expect(response.status).to eq 422
      expect(response.content_type).to eq "application/json"
      expect(JSON.parse(response.body)).to eq({"cron"=>["must have five components (m h dm m dw)"]})
    end


    it "should alter the CronJob when successful" do
      expect(@u.steps).to eq @args['steps']
      @args['steps'] = [{}, {}, {}, {}]
      put :update, @args
      expect(response.status).to eq 200
      @u.reload
      expect(@u.steps).to eq [{}, {}, {}, {}]
    end

  end

end
