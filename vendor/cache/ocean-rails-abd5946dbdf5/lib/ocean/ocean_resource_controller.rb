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

      #
      # The presence of +ocean_resource_controller+ in a Rails controller declares
      # that the controller is an Ocean controller handling an Ocean resource. It takes
      # two keyword parameters:
      #
      # +required_attributes+: a list of keywords naming model attributes which must be
      # present in every update operation. If an API consumer submits data where any
      # of these attributes isn't present, an API error will be generated.
      #
      #   ocean_resource_controller required_attributes: [:lock_version, :title]
      #
      # +extra_actions+: a hash containing information about extra controller actions
      # apart from the standard Rails ones of +index+, +show+, +create+, +update+, and 
      # +destroy+. One entry per extra action is required in order to process authentication
      # requests. Here's an example:
      #
      #   ocean_resource_controller extra_actions: {'comments' =>       ['comments', "GET"],
      #                                             'comment_create' => ['comments', "POST"]}
      #
      # The above example declares that the controller has two non-standard actions called
      # +comments+ and +comments_create+, respectively. Their respective values indicate that
      # +comments+ will be called as the result of a +GET+ to the +comments+ hyperlink, and
      # that +comment_create+ will be called as the result of a +POST+ to the same hyperlink.
      # Thus, +extra_actions+ maps actions to hyperlink names and HTTP methods.
      #
      def ocean_resource_controller(required_attributes: [:lock_version, :name, :description],
                                    extra_actions:       {}
      	                           )
      	cattr_accessor :ocean_resource_controller_extra_actions
      	cattr_accessor :ocean_resource_controller_required_attributes
      	self.ocean_resource_controller_extra_actions = extra_actions
      	self.ocean_resource_controller_required_attributes = required_attributes
      end
    end


    #
    # Used in controller code internals to obtain the extra actions declared using
    # +ocean_resource_controller+.
    #
    def extra_actions
      self.class.ocean_resource_controller_extra_actions
    end


    #
    # Returns true if the params hash lacks a required attribute declared using
    # +ocean_resource_controller+.
    #
    def missing_attributes?
      self.class.ocean_resource_controller_required_attributes.each do |attr|
        return true unless params[attr]
      end
      return false
    end

  end
end


ActionController::Base.send :include, Ocean::OceanResourceController
