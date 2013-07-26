#
# This is an "acts_as" type method to be used in ActiveRecord model
# definitions: "ocean_resource_controller".
#

module Ocean
  module OceanResourceController
    
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods

      def ocean_resource_controller(extra_actions:  {}, 
      	                            required_attributes: [:lock_version, :name, :description]
      	                           )
      	cattr_accessor :ocean_resource_controller_extra_actions
      	cattr_accessor :ocean_resource_controller_required_attributes
      	self.ocean_resource_controller_extra_actions = extra_actions
      	self.ocean_resource_controller_required_attributes = required_attributes
      end
    end


    def extra_actions
      self.class.ocean_resource_controller_extra_actions
    end

    def missing_attributes?
      self.class.ocean_resource_controller_required_attributes.each do |attr|
        return true unless params[attr]
      end
      return false
    end

  end
end


ActionController::Base.send :include, Ocean::OceanResourceController
