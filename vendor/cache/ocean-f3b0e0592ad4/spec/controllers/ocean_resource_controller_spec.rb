require 'spec_helper'

describe TheModelsController do

  before :each do
  	@i = TheModelsController.new
  	@c = @i.class
  end


  it "should be available as a class method from any controller" do
  	@c.ocean_resource_controller
  end



  it "should accept an :extra_actions keyword arg" do
    @c.ocean_resource_controller extra_actions: {foo: [], bar: []}
    @c.ocean_resource_controller extra_actions: {}
  end

  it ":extra_actions should default to {}" do
  	@c.ocean_resource_controller
  	@c.ocean_resource_controller_extra_actions.should == {}
  end

  it ":extra_actions should be reachable through a class method" do
  	@c.ocean_resource_controller extra_actions: {foo: [], bar: []}
  	@c.ocean_resource_controller_extra_actions.should == {foo: [], bar: []}
    @c.ocean_resource_controller   # Restore class defaults
 end

  it "instances should have an extra_actions method" do
  	@c.ocean_resource_controller extra_actions: {gniff: [], gnoff: []}
  	@i.extra_actions.should == {gniff: [], gnoff: []}
    @c.ocean_resource_controller   # Restore class defaults
  end



  it "should accept a :required_attributes keyword arg" do
  	@c.ocean_resource_controller required_attributes: [:quux, :snarf]
  end

  it ":required_attributes should default to [:lock_version, :name, :description]" do
   	@c.ocean_resource_controller
 	  @c.ocean_resource_controller_required_attributes.should == [:lock_version, :name, :description]
  end
	
  it ":required_attributes should be reachable through a class method" do
  	@c.ocean_resource_controller required_attributes: [:quux, :snarf]
  	@c.ocean_resource_controller_required_attributes.should == [:quux, :snarf]
    @c.ocean_resource_controller   # Restore class defaults
  end



  it "instances should have a missing_attributes? method" do
  	@c.ocean_resource_controller required_attributes: [:blirg, :blorg]
    @i.params = {blirg: 2, blorg: 3, fnyyk: 4}
  	@i.missing_attributes?.should == false
    @c.ocean_resource_controller   # Restore class defaults
  end

end
