require 'capybara/rails'
require 'launchy'

# Headless chrome
Capybara.register_driver(:selenium_chrome) do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: %w[headless disable-gpu] }
  )

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    desired_capabilities: capabilities
  )
end

# Heady Chrome
Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

# We can use Headless Chrome, Regular Chrome, of FF (using geckodriver)
if ENV['SELENIUM_CHROME']
  Capybara.javascript_driver = :selenium_chrome
elsif ENV['SELENIUM_HEADY_CHROME']
  Capybara.javascript_driver = :chrome
elsif java.lang.System.getProperty('os.name').downcase == 'linux'
  ENV['PATH'] = "#{File.join(ASUtils.find_base_directory, 'selenium', 'bin', 'geckodriver', 'linux')}:#{ENV['PATH']}"
else #osx
  ENV['PATH'] = "#{File.join(ASUtils.find_base_directory, 'selenium', 'bin', 'geckodriver', 'osx')}:#{ENV['PATH']}"
end

# This should change once the app gets to a point where it's not just throwing
# tons of errors...
Capybara.raise_server_errors = false

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.include Capybara::DSL
end

# We use the Mizuno server.
Capybara.register_server :mizuno do |app, port, host|
  require 'rack/handler/mizuno'
  Rack::Handler.get('mizuno').run(app, port: port, host: host)
end
Capybara.server = :mizuno

def finished_all_ajax_requests?
  request_count = page.evaluate_script('$.active').to_i
  request_count && request_count.zero?
rescue Timeout::Error
  puts 'timeout..'
end
