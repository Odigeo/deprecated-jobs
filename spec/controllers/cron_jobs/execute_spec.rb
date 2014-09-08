require 'spec_helper'

describe CronJobsController, :type => :controller do  

  describe "PUT execute" do

    it "should require no authentication or authorisation and return a 204" do
      expect(CronJob).to receive :process_queue
      put :execute, body: nil
      expect(response.status).to be 204
    end
    
    it "should not return a body" do
      expect(CronJob).to receive :process_queue
      put :execute, body: nil
      expect(response.body).to be_blank
    end

  end

end
