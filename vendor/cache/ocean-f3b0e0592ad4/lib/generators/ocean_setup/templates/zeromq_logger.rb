
if Rails.env == 'production'

  # Use a different logger for distributed setups
  Rails.logger = ActiveSupport::TaggedLogging.new(ZeromqLogger.new)
  Rails.logger.level = Logger::INFO
  Rails.logger.log_tags = []

  # Announce us
  Rails.logger.info "Initialising"

  # Make sure we log our exit
  at_exit { Rails.logger.info "Exiting" }

end
