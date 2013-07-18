require "ocean/api"
require "ocean/api_resource"
require "ocean/ocean_resource_model" if defined? ActiveRecord
require "ocean/ocean_resource_controller" if defined? ActionController
require "ocean/ocean_application_controller"
require "ocean/zero_log"
require "ocean/zeromq_logger"
require "ocean/selective_rack_logger"
require "ocean/flooding"

INVALIDATE_MEMBER_DEFAULT =     ["($|/|\\?)"]
INVALIDATE_COLLECTION_DEFAULT = ["($|\\?)"]

module Ocean
  class Railtie < Rails::Railtie
    # Silence the /alive action
    initializer "ocean.swap_logging_middleware" do |app|
      app.middleware.swap Rails::Rack::Logger, SelectiveRackLogger
    end
    # Make sure the generators use the gem's templates first
    config.app_generators do |g|
      g.templates.unshift File::expand_path('../templates', __FILE__)
    end 
  end
end
