require 'spec_helper'

describe AsyncJobsController do
  
  render_views

  describe "DELETE" do
    
    before :each do
      Api.stub(:permitted?).and_return(double(:status => 200, 
                                               :body => {'authentication' => {'user_id' => 123}}))
      @async_job = create :async_job
      request.headers['HTTP_ACCEPT'] = "application/json"
      request.headers['X-API-Token'] = "so-totally-fake"
    end

    
    it "should return JSON" do
      delete :destroy, id: @async_job
      response.content_type.should == "application/json"
    end

    it "should return a 400 if the X-API-Token header is missing" do
      request.headers['X-API-Token'] = nil
      delete :destroy, id: @async_job
      response.status.should == 400
    end
    
    it "should return a 204 when successful" do
      delete :destroy, id: @async_job
      response.status.should == 204
      response.content_type.should == "application/json"
    end

    it "should return a 404 when the AsyncJob can't be found" do
      delete :destroy, id: -1
      response.status.should == 404
    end
    
    it "should destroy the AsyncJob when successful" do
      delete :destroy, id: @async_job
      response.status.should == 204
      AsyncJob.find_by_id(@async_job.id).should be_nil
    end
    
  end
  
end
