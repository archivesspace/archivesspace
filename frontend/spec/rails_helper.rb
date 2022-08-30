# frozen_string_literal: true
require 'exceptions'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'rails-controller-testing'
require 'selenium-webdriver'
require_relative 'selenium/common/webdriver'
require 'aspace_helper'

CHROME_OPTS  = ENV.fetch('CHROME_OPTS', '--headless,--disable-gpu,--window-size=1920x1080,--no-sandbox,--disable-dev-shm-usage,--remote-debugging-port=9222').split(',')
FIREFOX_OPTS = ENV.fetch('FIREFOX_OPTS', '-headless').split(',')
# https://github.com/mozilla/geckodriver/issues/1354
ENV['MOZ_HEADLESS_WIDTH'] = ENV.fetch('MOZ_HEADLESS_WIDTH', '1920')
ENV['MOZ_HEADLESS_HEIGHT'] = ENV.fetch('MOZ_HEADLESS_HEIGHT', '1080')

# Chrome
Capybara.register_driver(:chrome) do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: Selenium::WebDriver::Chrome::Options.new(args: CHROME_OPTS)
  ).extend DriverMixin
end

# Firefox
Capybara.register_driver :firefox do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :firefox,
    options: Selenium::WebDriver::Firefox::Options.new(args: FIREFOX_OPTS)
  ).extend DriverMixin
end

if ENV['SELENIUM_CHROME']
  Capybara.javascript_driver = :chrome
else
  Capybara.javascript_driver = :firefox
end

# This should change once the app gets to a point where it's not just throwing
# tons of errors...
Capybara.raise_server_errors = false


RSpec.configure do |config|
  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  config.include Capybara::DSL
  config.include ASpaceHelpers
end

# We use the Mizuno server.
Capybara.register_server :mizuno do |app, port, host|
  require 'rack/handler/mizuno'
  Rack::Handler.get('mizuno').run(app, port: port, host: host)
end
Capybara.server = :mizuno
Capybara.default_max_wait_time = 10

ActionController::Base.logger.level = Logger::ERROR
Rails.logger.level = Logger::ERROR
Rails::Controller::Testing.install

def wait_for_job_to_complete(page)
  job_id = page.current_path.sub(/^[^\d]*/, '')
  sanity_counter = 0
  complete = false
  while (sanity_counter < 100 && !complete) do
    begin
      job = JSONModel(:job).find(job_id)
      complete = ["completed", "failed"].include?(job.status)
    rescue
    end
    return if complete
    sleep 1
    sanity_counter += 1
  end
end
