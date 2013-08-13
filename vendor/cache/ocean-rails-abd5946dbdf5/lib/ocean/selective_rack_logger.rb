#
# This custom Rack middleware is used to turn off logging of requests made to
# <code>/alive</code> by Varnish every 15 seconds in order to detect 
# failing instances for failover purposes.
#
class SelectiveRackLogger < Rails::Rack::Logger

  #
  # Initialises the selective Rack logger.
  #
  def initialize(app, opts = {})
    @app = app
    super
  end

  #
  # Suppresses logging of /alive requests from Varnish.
  #
  def call(env)
    if env['PATH_INFO'] == "/alive"
      old_level = Rails.logger.level
      Rails.logger.level = 1234567890              # > 5
      begin
        @app.call(env)                             # returns [..., ..., ...]
      ensure
        Rails.logger.level = old_level
      end
    else
      super(env)                                   # returns [..., ..., ...]
    end
  end

end
