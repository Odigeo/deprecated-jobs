# Update the Gemfile
gem "ocean-rails", git: "git://github.com/OceanDev/ocean-rails.git"

# Install a .rvmrc file
run "rvm rvmrc create ruby-2.0.0-p195@rails-4.0.0"
# Select the ruby and gem bag
run "rvm use ruby-2.0.0-p195@rails-4.0.0"
# Run bundle install - we need the generators in it now
run "bundle install"

# Set up the application as a SOA service Rails application
generate "ocean_setup", app_name

# Install the required gems and package them with the app
run "bundle install"
run "bundle package --all"

# Remove the asset stuff from the application conf file
gsub_file "config/application.rb", 
          /    # Enable the asset pipeline.+config\.assets\.version = '1\.0'\s/m, ''

# Set up SQLite to run tests in memory
gsub_file "config/database.yml",
          /test:\s+adapter: sqlite3\s+database: db\/test.sqlite3/m,
          'test:
  adapter: sqlite3
  database: ":memory:"
  verbosity: quiet'

# Get the DBs in order
rake "db:migrate"
