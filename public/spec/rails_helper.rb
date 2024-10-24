require 'capybara/rails'
require 'capybara-screenshot/rspec'
require 'launchy'

CHROME_OPTS  = ENV.fetch('CHROME_OPTS', "--headless=new --no-sandbox --enable-logging --log-level=0 --v=1 --incognito --disable-extensions --auto-open-devtools-for-tabs --window-size=1920,1080 --disable-dev-shm-usage").split(' ')

FIREFOX_OPTS = ENV.fetch('FIREFOX_OPTS', '-headless --width=1920 --height=1080').split(' ')

# Chrome
Capybara.register_driver(:chrome) do |app|
  chrome_options = Selenium::WebDriver::Chrome::Options.new(args: CHROME_OPTS)

  chrome_options.browser_version = 'stable'

  chrome_options.logging_prefs = {
    browser: 'ALL', # Capture JavaScript errors
    driver: 'INFO', # Capture WebDriver errors
  }

  options = {
    browser: :chrome,
    options: chrome_options,
  }
  Capybara::Selenium::Driver.new(app, **options)
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
  options = Selenium::WebDriver::Firefox::Options.new.tap do |opts|
    FIREFOX_OPTS.each { |arg| opts.add_argument(arg) }
  end

  options.profile = profile

  Capybara::Selenium::Driver.new(
    app,
    browser: :firefox,
    options: options
  )
end

if ENV['SELENIUM_CHROME'] == 'true'
  Capybara.default_driver = :chrome
  Capybara.javascript_driver = :chrome
else
  Capybara.default_driver = :firefox
  Capybara.javascript_driver = :firefox
end

# Capybara screenshot
Capybara.threadsafe = true
Capybara.save_path = File.join(ASUtils.find_base_directory, "ci_logs")
Capybara.asset_host = 'http://localhost:3001' # Enables (in theory) viewing of HTML screenshots with assets (provided you run the public devserver)
Capybara::Screenshot.register_driver(:chrome) do |driver, path|
  driver.browser.save_screenshot(path)
end
Capybara::Screenshot.register_driver(:firefox) do |driver, path|
  driver.browser.save_screenshot(path)
end

if ENV['SELENIUM_CHROME'] == 'true'
  Capybara.default_driver = :chrome
  Capybara.javascript_driver = :chrome
else
  Capybara.default_driver = :firefox
  Capybara.javascript_driver = :firefox
end

Capybara.raise_server_errors = false

# Make sure server port used is the one AppConfig says it should be
Capybara.server_port = URI.parse(AppConfig[:public_url]).port

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.include Capybara::DSL
  config.filter_rails_from_backtrace!

  if Capybara.current_driver == :chrome
    log_files = {}
    available_log_types = Capybara.page.driver.send(:browser).logs.available_types

    available_log_types.each do |log_type|
      log_files[log_type] = File.new(File.join(ASUtils.find_base_directory, "ci_logs", "#{log_type}.log"), "w")
      log_files[log_type].sync = true
    end

    config.before(:each, js: true) do |example|
      available_log_types.each do |log_type|
        description = "Example: #{example.full_description}"
        log_files[log_type].puts description, "-"*description.length
      end
    end

    config.append_after(:each, js: true) do
      available_log_types.each do |log_type|
        Capybara.page.driver.send(:browser).logs.get(log_type).each do |log|
          log_files[log_type].puts log.to_s
        end
      end
    end

    config.append_after(:suite) do
      log_files.each_value do |file|
        file.close
      end
    end
  end

  config.append_after(:each, js: true) do
    Capybara.reset_sessions!

    # Make sure all browser windows except one are closed
    windows.reject(&:current?).each(&:close)
  end

  config.append_after(:suite) do
    $server_pids.each do |pid|
      TestUtils.kill(pid)
    end
    begin
      puts "Halting Puma"
      $puma.halt
    rescue
    end
  end

  config.fail_fast = false
end

# Puma server
$puma = nil
Capybara.register_server :as_puma do |app, port, host|
  require 'rack/handler/puma'

  log_writer = Puma::LogWriter.new(
    File.open(File.join(ASUtils.find_base_directory, "ci_logs", "puma.out"), 'w'),
    File.open(File.join(ASUtils.find_base_directory, "ci_logs", "puma_err.out"), 'w')
  )
  options = { Host: host, Port: port, Threads: '1:8', workers: 0, daemon: false, log_writer: log_writer }
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

def finished_all_ajax_requests?
  request_count = page.evaluate_script('$.active').to_i
  request_count && request_count.zero?
rescue Timeout::Error
  puts 'timeout..'
end

cp_logger = Logger.new(File.join(ASUtils.find_base_directory, "ci_logs", "childprocess_gem.out"))
cp_logger.level = Logger::DEBUG

ChildProcess.logger = cp_logger
