require 'spec_helper'

describe AsyncJob, :type => :request do

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
      expect(response.status).to eq 201
      j = JSON.parse(response.body)
      expect(j['async_job']).to be_a Hash
      expect(AsyncJob.find(j['async_job']['uuid'], consistent: true)).to be_an AsyncJob
      expect(j['async_job']['default_step_time']).to eq 100
      expect(j['async_job']['max_seconds_in_queue']).to eq 604800
    end

   it "should return a finished job immediately if no steps" do
      post "/v1/async_jobs", 
          {'steps' => [],
           'credentials' => 'bWFnbmV0bzp4YXZpZXI='}, 
          {'HTTP_ACCEPT' => "application/json", 'X-API-TOKEN' => "incredibly-fake"}
      expect(response.status).to eq 201
      j = JSON.parse(response.body)['async_job']
      expect(j).to be_a Hash
      expect(j['finished_at']).to be_a String
   end

    it "should barf on a non-array steps attribute" do
      post "/v1/async_jobs", 
          {'steps' => {x: 1, y: 2}}, 
          {'HTTP_ACCEPT' => "application/json", 'X-API-TOKEN' => "incredibly-fake"}
      expect(response.status).to eq 422
      j = JSON.parse(response.body)
      expect(j).not_to eq({"_api_error"=>["Resource not unique"]})
      expect(j['async_job']).to eq nil
      expect(j['steps']).to eq ["must be an Array"]
   end

    it "should return a 422 if the credentials are missing" do
      post "/v1/async_jobs", 
          {'steps' => [{}, {}, {}],
           'credentials' => nil}, 
          {'HTTP_ACCEPT' => "application/json", 'X-API-TOKEN' => "incredibly-fake"}
      expect(response.status).to eq 422
      j = JSON.parse(response.body)
      expect(j).not_to eq({"_api_error"=>["Resource not unique"]})
      expect(j['async_job']).to eq nil
      expect(j['credentials']).to eq ["must be specified"]
    end

    it "should return a 422 if the credentials are malformed" do
      post "/v1/async_jobs", 
          {'steps' => [{}, {}, {}],
           'credentials' => "certainly-not-correctly-formed"}, 
          {'HTTP_ACCEPT' => "application/json", 'X-API-TOKEN' => "incredibly-fake"}
      expect(response.status).to eq 422
      j = JSON.parse(response.body)
      expect(j).not_to eq({"_api_error"=>["Resource not unique"]})
      expect(j['async_job']).to eq nil
      expect(j['credentials']).to eq ["are malformed"]
    end
  end
  

  describe "show" do

    it "should return an AsyncJob given its UUID" do
      job = create :async_job
      get "/v1/async_jobs/#{job.uuid}", {}, {'HTTP_ACCEPT' => "application/json",
                                             'X-API-TOKEN' => "incredibly-fake",
                                             'If-None-Match' => 'e65ae6734803fa'}
      expect(response.status).to be(200)
      j = JSON.parse(response.body)
      expect(j['async_job']).to be_a Hash
      expect(j['async_job']['uuid']).to eq job.uuid
    end

    it "should return a 404 if the UUID isn't found" do
      get "/v1/async_jobs/totallynonexistent", {}, {'HTTP_ACCEPT' => "application/json",
                                                    'X-API-TOKEN' => "incredibly-fake",
                                                    'If-None-Match' => 'e65ae6734803fa'}
      expect(response.status).to be(404)
      j = JSON.parse(response.body)
      expect(j['async_job']).to eq nil
      expect(j['_api_error']).to eq ["AsyncJob not found"]
    end
  end


  describe "destroy" do

    it "should delete an AsyncJob given its UUID" do
      job = create :async_job
      delete "/v1/async_jobs/#{job.uuid}", 
            {}, 
            {'HTTP_ACCEPT' => "application/json", 'X-API-TOKEN' => "incredibly-fake"}
      expect(response.status).to be(204)
    end 

    it "should return a 404 if the UUID isn't found" do
      delete "/v1/async_jobs/totallynonexistent", {}, 
             {'HTTP_ACCEPT' => "application/json", 'X-API-TOKEN' => "incredibly-fake"}
      expect(response.status).to be(404)
      j = JSON.parse(response.body)
      expect(j['async_job']).to eq nil
      expect(j['_api_error']).to eq ["AsyncJob not found"]
    end
  end


  describe "cleanup" do

    it "should purge expired AsyncJobs" do
      AsyncJob.delete_all
      create :async_job, destroy_at: Time.now.utc + 1.year
      create :async_job, destroy_at: 2.days.ago
      create :async_job, destroy_at: Time.now.utc + 1.year
      create :async_job, destroy_at: 1.minute.ago
      create :async_job, destroy_at: Time.now.utc + 1.year
      expect(AsyncJob.count).to eq 5
      put "/v1/async_jobs/cleanup", 
            {}, 
            {'HTTP_ACCEPT' => "application/json", 'X-API-TOKEN' => "incredibly-fake"}
      expect(AsyncJob.count).to eq 3
    end

  end

end 
