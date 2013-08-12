require 'spec_helper'

describe ApplicationHelper do

  describe "hyperlinks" do

    it "should return an empty hash given no args" do
  	  hyperlinks().should == {}
    end

    it "should return as many output array elements as input hash args" do
      hyperlinks(self: "http://foo", 
      	         quux: "https://blah").count.should == 2
    end

    it "should return a two-element hash for each arg" do
      hyperlinks(self: "https://example.com/v1/blah")['self'].count.should == 2
    end

    it "should return a href value for the value of each arg" do
      hyperlinks(self: "blah")['self']['href'].should == "blah"
    end

    it "should default the type to application/json for terse hyperlinks" do
      hyperlinks(self: "blah")['self']['type'].should == "application/json"
    end

    it "should accept non-terse values giving the href and type in a sub-hash" do
      hl = hyperlinks(self: {href: "https://xux", type: "image/jpeg"})
      hl['self']['href'].should == "https://xux"
      hl['self']['type'].should == "image/jpeg"
    end

  end


  describe "api_user_url" do

  	it "should accept exactly one argument" do
  	  api_user_url(123).should == "https://forbidden.example.com/v1/api_users/123"
 	  lambda { api_user_url() }.should raise_error
  	end

  	it "should accept a nil argument and default the user ID to zero" do
  	  api_user_url(nil).should == "https://forbidden.example.com/v1/api_users/0"
  	end


  end

end
