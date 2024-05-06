require 'capybara/rails'
require 'capybara-screenshot/rspec'
require 'launchy'

CHROME_OPTS  = ENV.fetch('CHROME_OPTS', '--headless,--disable-gpu,--window-size=1920x1080').split(',')
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

Capybara.raise_server_errors = false

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.include Capybara::DSL
  config.filter_rails_from_backtrace!

  config.after(:suite) do
    $server_pids.each do |pid|
      TestUtils.kill(pid)
    end
    begin
      puts "Halting Puma"
      $puma.halt
    rescue
    end
  end

  config.append_after(:each) do
    Capybara.reset_sessions!
  end

  config.fail_fast = true
end

# Puma server
$puma = nil
Capybara.register_server :as_puma do |app, port, host|
  require 'rack/handler/puma'
  options = { Host: host, Port: port, Threads: '1:8', workers: 0, daemon: false }
  conf = Rack::Handler::Puma.config(app, options)
  events_handler = Puma::Events.new(
    File.open(File.join(ASUtils.find_base_directory, "ci_logs", "puma.out"), 'w'),
    File.open(File.join(ASUtils.find_base_directory, "ci_logs", "puma_err.out"), 'w')
  )
  $puma = Puma::Server.new(
    conf.app,
    events_handler,
    conf.options
  ).tap do |s|
    s.binder.parse conf.options[:binds], (s.log_writer rescue s.events) # rubocop:disable Style/RescueModifier
    s.min_threads, s.max_threads = conf.options[:min_threads], conf.options[:max_threads] if s.respond_to? :min_threads=
  end
  $puma.run.join
end
Capybara.server = :as_puma

def finished_all_ajax_requests?
  request_count = page.evaluate_script('$.active').to_i
  request_count && request_count.zero?
rescue Timeout::Error
  puts 'timeout..'
end

Capybara.threadsafe = true
Capybara.save_path = File.join(ASUtils.find_base_directory, "ci_logs")
# Enables (in theory) viewing of HTML screenshots with assets (provided you run the public devserver)
Capybara.asset_host = 'http://localhost:3001'

Capybara::Screenshot.register_driver(:firefox) do |driver, path|
  driver.browser.save_screenshot(path)
end


cp_logger = Logger.new(File.join(ASUtils.find_base_directory, "ci_logs", "childprocess_gem.out"))
cp_logger.level = Logger::DEBUG
ChildProcess.logger = cp_logger
