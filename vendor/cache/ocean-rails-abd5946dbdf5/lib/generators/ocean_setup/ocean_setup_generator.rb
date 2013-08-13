class OceanSetupGenerator < Rails::Generators::NamedBase #:nodoc: all

  source_root File.expand_path('../templates', __FILE__)

  def remove_unwanted_stuff
    remove_file "#{Rails.root}/app/assets"
    remove_file "#{Rails.root}/lib/assets"
    remove_file "#{Rails.root}/app/views/layouts"
    remove_file "#{Rails.root}/config/locales"
    remove_file "#{Rails.root}/public"
    remove_file "#{Rails.root}/config/initializers/session_store.rb"
    #remove_file "#{Rails.root}/config/initializers/secret_token.rb"
    remove_file "#{Rails.root}/test"
    remove_file "#{Rails.root}/vendor/assets"
    remove_file "#{Rails.root}/vendor/plugins"
    remove_file "#{Rails.root}/tmp/cache/assets"
  end

  def install_application_controller
    copy_file "application_controller.rb", "#{Rails.root}/app/controllers/application_controller.rb"
  end

  def install_application_helper
    copy_file "application_helper.rb", "#{Rails.root}/app/helpers/application_helper.rb"
  end

  def install_spec_helper_and_support_files
    copy_file "spec_helper.rb", "#{Rails.root}/spec/spec_helper.rb"
    copy_file "hyperlinks.rb", "#{Rails.root}/spec/support/hyperlinks.rb"
  end

  def install_routes_file
    template "routes.rb", "#{Rails.root}/config/routes.rb"
  end

  def install_alive_controller_and_specs
    copy_file "alive_controller.rb", "#{Rails.root}/app/controllers/alive_controller.rb"
    route 'get "/alive" => "alive#index"'
    copy_file "alive_routing_spec.rb", "#{Rails.root}/spec/routing/alive_routing_spec.rb"
    copy_file "alive_spec.rb", "#{Rails.root}/spec/requests/alive_spec.rb"
  end

  def turn_off_asset_pipeline
    application "# Disable the asset pipeline
    config.assets.enabled = false    
    "
  end

  def install_error_handling_and_specs
    application "# Handle our own exceptions internally, so we can return JSON error bodies
    config.exceptions_app = ->(env) { ErrorsController.action(:show).call(env) }
    "
    copy_file "errors_controller.rb", "#{Rails.root}/app/controllers/errors_controller.rb"
  end

  def turn_off_sessions_and_cookies
    application "# Turn off sessions
    config.session_store :disabled
    config.middleware.delete ActionDispatch::Cookies
    "
  end

  def install_generator_defaults
    application "# Defaults for generators
    config.generators do |g|
      g.assets false
      g.stylesheets false
      g.helper false
      g.test_framework :rspec, :fixture => true
      g.fixture_replacement :factory_girl    
    end
    "
  end

  def install_initializers
    copy_file "api_constants.rb",   "#{Rails.root}/config/initializers/api_constants.rb"
    template  "config.yml.example", "#{Rails.root}/config/config.yml.example"
    template  "config.yml.example", "#{Rails.root}/config/config.yml"
    copy_file "ocean_constants.rb", "#{Rails.root}/config/initializers/ocean_constants.rb"
    copy_file "zeromq_logger.rb",   "#{Rails.root}/config/initializers/zeromq_logger.rb"
  end

  def replace_gemfile
    remove_file "#{Rails.root}/Gemfile"
    copy_file "Gemfile", "#{Rails.root}/Gemfile"
  end

  def setup_git
    copy_file "gitignore", "#{Rails.root}/.gitignore"
    git :init
  end

end
