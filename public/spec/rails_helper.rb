require 'capybara/rails'
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

Capybara.raise_server_errors = true

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.include Capybara::DSL
  config.filter_rails_from_backtrace!
end

def finished_all_ajax_requests?
  request_count = page.evaluate_script('$.active').to_i
  request_count && request_count.zero?
rescue Timeout::Error
  puts 'timeout..'
end
