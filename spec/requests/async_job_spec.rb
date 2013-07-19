require 'spec_helper'

describe AsyncJob do

  before :each do
    Api.stub(:permitted?).and_return(double(:status => 200, 
                                            :body => {'authentication' => {'user_id' => 123}}))
  end


  describe "index" do

	  it "should return a 200 with an array as a body" do
	    get "/v1/async_jobs", {}, {'HTTP_ACCEPT' => "application/json",
	                               'X-API-TOKEN' => "incredibly-fake"}
	    response.status.should be(200)
	    response.body.should == "[]"
	  end

	end


  describe "show" do

    it "should return an AsyncJob given its UUID" do
      job = create :async_job
      get "/v1/async_jobs/#{job.uuid}", {}, {'HTTP_ACCEPT' => "application/json",
                                             'X-API-TOKEN' => "incredibly-fake"}
      response.status.should be(200)
      j = JSON.parse(response.body)
      j['async_job'].should be_a Hash
      j['async_job']['uuid'].should == job.uuid
    end

    it "should return a 404 if the UUID isn't found" do
      get "/v1/async_jobs/totallynonexistent", {}, {'HTTP_ACCEPT' => "application/json",
                                                    'X-API-TOKEN' => "incredibly-fake"}
      response.status.should be(404)
      j = JSON.parse(response.body)
      j['async_job'].should == nil
      j['_api_error'].should == ["AsyncJob not found"]
    end

  end


  describe "destroy" do

    it "should delete an AsyncJob given its UUID" do
      AsyncJob.count.should == 0
      job = create :async_job
      AsyncJob.count.should == 1
      delete "/v1/async_jobs/#{job.uuid}", {}, {'HTTP_ACCEPT' => "application/json",
                                                'X-API-TOKEN' => "incredibly-fake"}
      response.status.should be(204)
      AsyncJob.count.should == 0
    end 

    it "should return a 404 if the UUID isn't found" do
      delete "/v1/async_jobs/totallynonexistent", {}, {'HTTP_ACCEPT' => "application/json",
                                                       'X-API-TOKEN' => "incredibly-fake"}
      response.status.should be(404)
      j = JSON.parse(response.body)
      j['async_job'].should == nil
      j['_api_error'].should == ["AsyncJob not found"]
    end
  end


  describe "create" do

    it "should create an AsyncJob given proper parameters" do
      post "/v1/async_jobs", 
          {}, 
          {'HTTP_ACCEPT' => "application/json",
           'X-API-TOKEN' => "incredibly-fake"}
      response.status.should == 201
      j = JSON.parse(response.body)
      j['async_job'].should be_a Hash
      AsyncJob.find_by_uuid(j['async_job']['uuid']).should be_an AsyncJob
    end

  end
  

end 
