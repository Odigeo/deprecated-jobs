require 'spec_helper'

require 'base64'


describe Api do
  
  it "should have a class method to return the API version for a service" do
    Api.version_for(:auth).should match /v[0-9]+/
  end


  it "Api.get should use Api.call" do
    Api.stub(:call).and_return(:aye)
    Api.get(:some_service, "/resource/path/foo/bar").should == :aye
  end

  it "Api.post should use Api.call" do
    Api.stub(:call).and_return(:aye)
    Api.post(:some_service, "/resource/path/foo/bar").should == :aye
  end

  it "Api.put should use Api.call" do
    Api.stub(:call).and_return(:aye)
    Api.put(:some_service, "/resource/path/foo/bar").should == :aye
  end

  it "Api.delete should use Api.call" do
    Api.stub(:call).and_return(:aye)
    Api.delete(:some_service, "/resource/path/foo/bar").should == :aye
  end


  it ".decode_credentials should be able to decode what .encode_credentials produces" do
    Api.decode_credentials(Api.encode_credentials("foo", "bar")).should == ["foo", "bar"]
  end

  it ".encode_credentials should encode username and password into Base64 form" do
    Api.encode_credentials("myuser", "mypassword").should ==
      ::Base64.strict_encode64("myuser:mypassword")
  end

  it ".decode_credentials should decode username and password from Base64" do
    Api.decode_credentials(::Base64.strict_encode64("myuser:mypassword")).should == 
      ['myuser', 'mypassword']
  end

  it ".decode_credentials, when given nil, should return empty credentials" do
    Api.decode_credentials(nil).should == ['', '']
  end
  
  
  describe ".permitted?" do
    
    it "should return a response with a status of 404 if the token is unknown" do
      Api.stub(:get).and_return(double(:status => 404))
      Api.permitted?('some-client-token').status.should == 404
    end
    
    it "should return a response with a status of 400 if the authentication has expired" do
      Api.stub(:get).and_return(double(:status => 400))
      Api.permitted?('some-client-token').status.should == 400
    end    
  
    it "should return a response with a status of 403 if the operation is denied" do
      Api.stub(:get).and_return(double(:status => 403))
      Api.permitted?('some-client-token').status.should == 403
    end
    
    it "should return a response with a status of 200 if the operation is authorized" do
      Api.stub(:get).and_return(double(:status => 200))
      Api.permitted?('some-client-token').status.should == 200
    end
    
  end


  describe "class method authorization_string" do

    it "should take the extra actions, the controller name and an action name" do
      Api.authorization_string({}, "fubars", "show").should be_a(String)
    end

    it "should take an optional app and an optional context" do
      Api.authorization_string({}, "fubars", "show", "some_app", "some_context").should be_a(String)
    end

    it "should put the app and context in the two last positions" do
      qs = Api.authorization_string({}, "fubars", "show", "some_app", "some_context").split(':')
      qs[4].should == 'some_app'
      qs[5].should == 'some_context'
    end

    it "should replace a blank app or context with asterisks" do
      qs = Api.authorization_string({}, "fubars", "show", nil, " ").split(':')
      qs[4].should == '*'
      qs[5].should == '*'
    end

    it "should take an optional service name" do
      Api.authorization_string({}, "fubars", "show", "*", "*", "foo").should == "foo:fubars:self:GET:*:*"
    end

    it "should default the service name to APP_NAME" do
      Api.authorization_string({}, "fubars", "show", "*", "*").should == "#{APP_NAME}:fubars:self:GET:*:*"
    end

    it "should return a string of six colon-separated parts" do
      qs = Api.authorization_string({}, "fubars", "show")
      qs.should be_a(String)
      qs.split(':').length.should == 6
    end

    it "should use the controller name as the resource name" do
      qs = Api.authorization_string({}, "fubars", "show", nil, nil, 'foo').split(':')
      qs[1].should == "fubars"
    end

  end


  describe "class method map_authorization" do

    it "should return an array of two strings" do
      m = Api.map_authorization({}, "fubars", "show")
      m.should be_an(Array)
      m.length.should == 2
      m[0].should be_a(String)
      m[1].should be_a(String)
    end

    it "should translate 'show'" do
      Api.map_authorization({}, "fubars", "show").should == ["self", "GET"]
    end

    it "should translate 'index'" do
      Api.map_authorization({}, "fubars", "index").should == ["self", "GET*"]
    end

    it "should translate 'create'" do
      Api.map_authorization({}, "fubars", "create").should == ["self", "POST"]
    end

    it "should translate 'update'" do
      Api.map_authorization({}, "fubars", "update").should == ["self", "PUT"]
    end

    it "should translate 'destroy'" do
      Api.map_authorization({}, "fubars", "destroy").should == ["self", "DELETE"]
    end

    it "should translate 'connect'" do
      Api.map_authorization({}, "fubars", "connect").should == ["connect", "PUT"]
    end

    it "should translate 'disconnect'" do
      Api.map_authorization({}, "fubars", "disconnect").should == ["connect", "DELETE"]
    end

    it "should raise an error for unknown actions" do
      expect { Api.map_authorization({}, "fubars", "blahonga") }.to raise_error
    end

    it "should insert the extra_action data appropriately" do
      Api.map_authorization({'fubars' => {'blahonga_create' => ['blahonga', 'POST']}}, 
                             "fubars", "blahonga_create").
        should == ['blahonga', 'POST']
    end

  end
     
  
end
