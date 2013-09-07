require "spec_helper"

describe AsyncJobsController do
  describe "routing" do

    it "doesn't route to #index" do
      get("/v1/async_jobs").should_not be_routable
    end

    it "routes to #show" do
      get("/v1/async_jobs/1").should route_to("async_jobs#show", :id => "1")
    end

    it "routes to #create" do
      post("/v1/async_jobs").should route_to("async_jobs#create")
    end

    it "routes to #update" do
      put("/v1/async_jobs/1").should_not be_routable
    end

    it "routes to #destroy" do
      delete("/v1/async_jobs/1").should route_to("async_jobs#destroy", :id => "1")
    end

  end
end
