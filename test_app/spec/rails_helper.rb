# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../config/environment", __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "spec_helper"
require "rspec/rails"
require "rspec/its"

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.before(:each) do
    Sapience.reset!
  end

  config.before(:suite) do
    FileUtils.cp(
      Rails.root.join("spec/fixtures/sapience.yml"),
      Rails.root.join("config/sapience.yml"),
    )
  end

  config.after(:suite) do
    FileUtils.rm(Rails.root.join("config/sapience.yml"))
  end
end
