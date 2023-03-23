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
  )
end

# Firefox
Capybara.register_driver :firefox do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :firefox,
    options: Selenium::WebDriver::Firefox::Options.new(args: FIREFOX_OPTS)
  )
end

if ENV['SELENIUM_CHROME']
  Capybara.javascript_driver = :chrome
else
  Capybara.javascript_driver = :firefox
end

Capybara.raise_server_errors = true

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include Capybara::DSL
  config.include ASpaceHelpers
end

# We use the Mizuno server.
# Capybara.register_server :mizuno do |app, port, host|
#   require 'rack/handler/mizuno'
#   Rack::Handler.get('mizuno').run(app, port: port, host: host)
# end
# Capybara.server = :mizuno

# Puma server
$puma = nil
Capybara.register_server :as_puma do |app, port, host|
  require 'rack/handler/puma'
  options = { Host: host, Port: port, Threads: '1:1', workers: 0, daemon: false }
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

Capybara.default_max_wait_time = ENV.fetch('CAPYBARA_DEFAULT_MAX_WAIT_TIME', 60).to_i
ActionController::Base.logger.level = Logger::ERROR
Rails.logger.level = Logger::ERROR
Rails::Controller::Testing.install

def wait_for_job_to_complete(page)
  job_id = page.current_path.sub(/^[^\d]*/, '')
  sanity_counter = 0
  complete = false
  while (sanity_counter < 20 && !complete) do
    begin
      job = JSONModel(:job).find(job_id)
      puts "JOB #{job.id} - STATUS #{job.status}"
      complete = ["completed", "failed"].include?(job.status)
    rescue => e
      puts "JSONModel(:job).find(#{job_id})"
      p e
    end
    return if complete
    sleep 1
    sanity_counter += 1
  end
end
