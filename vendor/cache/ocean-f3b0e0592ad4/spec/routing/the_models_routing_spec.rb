require "spec_helper"

describe TheModelsController do
  describe "routing" do

    it "routes to #index" do
      get("/v1/the_models").should route_to("the_models#index")
    end

    it "routes to #show" do
      get("/v1/the_models/1").should route_to("the_models#show", :id => "1")
    end

    it "routes to #create" do
      post("/v1/the_models").should route_to("the_models#create")
    end

    it "routes to #update" do
      put("/v1/the_models/1").should route_to("the_models#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/v1/the_models/1").should route_to("the_models#destroy", :id => "1")
    end
    
  end
end
