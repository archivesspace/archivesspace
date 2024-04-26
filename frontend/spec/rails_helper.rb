# frozen_string_literal: true
require 'exceptions'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'capybara-screenshot/rspec'
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
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile['webdriver.log.level'] = 'ALL'
  profile['browser.download.dir'] = Dir.tmpdir
  profile['browser.download.folderList'] = 2
  profile['browser.helperApps.alwaysAsk.force'] = false
  profile['browser.helperApps.neverAsk.saveToDisk'] = 'application/msword, application/csv, application/pdf, application/xml,  application/ris, text/csv, image/png, application/pdf, text/html, text/plain, application/zip, application/x-zip, application/x-zip-compressed'
  profile['pdfjs.disabled'] = true
  options = Selenium::WebDriver::Firefox::Options.new(args: FIREFOX_OPTS)
  options.profile = profile

  Capybara::Selenium::Driver.new(
    app,
    browser: :firefox,
    options: options
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

# Html pages saved after Capybara spec failures will reference this to load assets
# so running a local dev server will help displaying the page correctly in a browser
Capybara.asset_host = 'http://localhost:3000/'

Capybara::Screenshot.register_driver(:chrome) do |driver, path|
  driver.browser.save_screenshot(path)
end

Capybara::Screenshot.register_driver(:firefox) do |driver, path|
  driver.browser.save_screenshot(path)
end

# keep the last 30 screenshots / pages of capybara spec failures
Capybara::Screenshot.prune_strategy = :keep_last_run


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

# Puma server
$puma = nil
Capybara.register_server :as_puma do |app, port, host|
  require 'rack/handler/puma'
  options = { Host: host, Port: port, Threads: '1:8', workers: 0, daemon: false }
  conf = Rack::Handler::Puma.config(app, options)
  $puma = Puma::Server.new(
    conf.app,
    nil,
    conf.options
  ).tap do |s|
    s.binder.parse conf.options[:binds], (s.log_writer rescue s.events) # rubocop:disable Style/RescueModifier
    s.min_threads, s.max_threads = conf.options[:min_threads], conf.options[:max_threads] if s.respond_to? :min_threads=
  end
  $puma.run.join
end
Capybara.server = :as_puma

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
