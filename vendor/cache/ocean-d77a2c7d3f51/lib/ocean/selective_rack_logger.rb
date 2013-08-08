class SelectiveRackLogger < Rails::Rack::Logger

  def initialize(app, opts = {})
    @app = app
    super
  end

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
