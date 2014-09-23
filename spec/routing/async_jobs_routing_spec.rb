require "spec_helper"

describe AsyncJobsController, :type => :routing do
  describe "routing" do

    it "doesn't route to #index" do
      expect(get("/v1/async_jobs")).not_to be_routable
    end

    it "routes to #show" do
      expect(get("/v1/async_jobs/a-b-c-d-e")).to route_to("async_jobs#show", :id => "a-b-c-d-e")
    end

    it "routes to #create" do
      expect(post("/v1/async_jobs")).to route_to("async_jobs#create")
    end

    it "routes to #update" do
      expect(put("/v1/async_jobs/a-b-c-d-e")).not_to be_routable
    end

    it "routes to #destroy" do
      expect(delete("/v1/async_jobs/a-b-c-d-e")).to route_to("async_jobs#destroy", :id => "a-b-c-d-e")
    end

    it "routes to #cleanup" do
      expect(put("/v1/async_jobs/cleanup")).to route_to("async_jobs#cleanup")
    end
  end
end
