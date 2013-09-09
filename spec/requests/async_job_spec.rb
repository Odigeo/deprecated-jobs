require 'spec_helper'

describe AsyncJob do

  before :each do
    permit_with 200
  end


  describe "create" do

    it "should create an AsyncJob given proper parameters" do
      post "/v1/async_jobs", 
          {'max_seconds_in_queue' => 604800,
           'default_step_time' => 100,
           'credentials' => 'bWFnbmV0bzp4YXZpZXI='}, 
          {'HTTP_ACCEPT' => "application/json", 'X-API-TOKEN' => "incredibly-fake"}
      response.status.should == 201
      puts response.body
      j = JSON.parse(response.body)
      j['async_job'].should be_a Hash
      AsyncJob.find(j['async_job']['uuid'], consistent: true).should be_an AsyncJob
      j['async_job']['default_step_time'].should == 100
      j['async_job']['max_seconds_in_queue'].should == 604800
    end

   it "should return a finished job immediately if no steps" do
      post "/v1/async_jobs", 
          {'steps' => [],
           'credentials' => 'bWFnbmV0bzp4YXZpZXI='}, 
          {'HTTP_ACCEPT' => "application/json", 'X-API-TOKEN' => "incredibly-fake"}
      response.status.should == 201
      j = JSON.parse(response.body)['async_job']
      j.should be_a Hash
      j['finished_at'].should be_a String
   end

    it "should barf on a non-array steps attribute" do
      post "/v1/async_jobs", 
          {'steps' => {x: 1, y: 2}}, 
          {'HTTP_ACCEPT' => "application/json", 'X-API-TOKEN' => "incredibly-fake"}
      response.status.should == 422
      j = JSON.parse(response.body)
      j.should_not == {"_api_error"=>["Resource not unique"]}
      j['async_job'].should == nil
      j['steps'].should == ["must be an Array"]
   end

    it "should return a 422 if the credentials are missing" do
      post "/v1/async_jobs", 
          {'steps' => [{}, {}, {}],
           'credentials' => nil}, 
          {'HTTP_ACCEPT' => "application/json", 'X-API-TOKEN' => "incredibly-fake"}
      response.status.should == 422
      j = JSON.parse(response.body)
      j.should_not == {"_api_error"=>["Resource not unique"]}
      j['async_job'].should == nil
      j['credentials'].should == ["must be specified"]
    end

    it "should return a 422 if the credentials are malformed" do
      post "/v1/async_jobs", 
          {'steps' => [{}, {}, {}],
           'credentials' => "certainly-not-correctly-formed"}, 
          {'HTTP_ACCEPT' => "application/json", 'X-API-TOKEN' => "incredibly-fake"}
      response.status.should == 422
      j = JSON.parse(response.body)
      j.should_not == {"_api_error"=>["Resource not unique"]}
      j['async_job'].should == nil
      j['credentials'].should == ["are malformed"]
    end
  end
  

  describe "show" do

    it "should return an AsyncJob given its UUID" do
      job = create :async_job
      get "/v1/async_jobs/#{job.uuid}", {}, {'HTTP_ACCEPT' => "application/json",
                                             'X-API-TOKEN' => "incredibly-fake",
                                             'If-None-Match' => 'e65ae6734803fa'}
      response.status.should be(200)
      j = JSON.parse(response.body)
      j['async_job'].should be_a Hash
      j['async_job']['uuid'].should == job.uuid
    end

    it "should return a 404 if the UUID isn't found" do
      get "/v1/async_jobs/totallynonexistent", {}, {'HTTP_ACCEPT' => "application/json",
                                                    'X-API-TOKEN' => "incredibly-fake",
                                                    'If-None-Match' => 'e65ae6734803fa'}
      response.status.should be(404)
      j = JSON.parse(response.body)
      j['async_job'].should == nil
      j['_api_error'].should == ["AsyncJob not found"]
    end
  end


  describe "destroy" do

    it "should delete an AsyncJob given its UUID" do
      job = create :async_job
      delete "/v1/async_jobs/#{job.uuid}", 
            {}, 
            {'HTTP_ACCEPT' => "application/json", 'X-API-TOKEN' => "incredibly-fake"}
      response.status.should be(204)
    end 

    it "should return a 404 if the UUID isn't found" do
      delete "/v1/async_jobs/totallynonexistent", {}, 
             {'HTTP_ACCEPT' => "application/json", 'X-API-TOKEN' => "incredibly-fake"}
      response.status.should be(404)
      j = JSON.parse(response.body)
      j['async_job'].should == nil
      j['_api_error'].should == ["AsyncJob not found"]
    end
  end

end 
