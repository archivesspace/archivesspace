# frozen_string_literal: true

require 'byebug'
require 'capybara/cucumber'
require 'selenium-webdriver'
require 'capybara-screenshot/cucumber'

STAFF_URL = ENV.fetch('STAFF_URL', 'http://localhost:8080')
PUBLIC_URL = ENV.fetch('PUBLIC_URL', 'http://localhost:8081')

HEADLESS = ENV.fetch('HEADLESS', '--headless')

SCREENSHOTS_PATH = '/tmp/screenshots'

Capybara.register_driver :firefox do |app|
  options = Selenium::WebDriver::Firefox::Options.new
  options.add_argument(HEADLESS)

  profile = Selenium::WebDriver::Firefox::Profile.new
  profile['webdriver.log.level'] = 'ALL'
  profile['browser.download.dir'] = Dir.tmpdir
  profile['browser.download.folderList'] = 2
  profile['browser.helperApps.alwaysAsk.force'] = false
  profile['browser.helperApps.neverAsk.saveToDisk'] = 'application/msword, application/csv, application/pdf, application/xml,  application/ris, text/csv, image/png, application/pdf, text/html, text/plain, application/zip, application/x-zip, application/x-zip-compressed'
  profile['pdfjs.disabled'] = true
  options.profile = profile

  Capybara::Selenium::Driver.new(app, browser: :firefox, options:)
end

Capybara.register_driver :firefox_alternative_session do |app|
  options = Selenium::WebDriver::Firefox::Options.new
  options.add_argument(HEADLESS)

  Capybara::Selenium::Driver.new(app, browser: :firefox, options:)
end

Capybara.default_driver = :firefox
Capybara.default_max_wait_time = 15
Capybara.asset_host = 'http://localhost:8080' # Enables viewing of HTML screenshots with assets

BeforeAll do
  connection_error = "\nNo server found running on #{STAFF_URL}.\n\n"

  begin
    response = Net::HTTP.get_response(URI(STAFF_URL))

    raise connection_error if response.code != '200'
  rescue Errno::ECONNREFUSED, Errno::ECONNRESET
    raise connection_error
  end
end

Capybara.save_path = SCREENSHOTS_PATH

Capybara::Screenshot.register_driver(:firefox) do |driver, path|
  driver.browser.save_screenshot(path)
end

After do |scenario|
  if scenario.failed?
    uuid = SecureRandom.uuid

    scenario_name = scenario.name.downcase.gsub(' ', '_')

    Capybara::Screenshot.register_filename_prefix_formatter(:firefox) do |_example|
      scenario_name
    end

    timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
    filename = "#{scenario_name}-screenshot-#{timestamp}-#{uuid}.png"
    filepath = File.join(SCREENSHOTS_PATH, filename)
    page.save_screenshot(filepath) # rubocop:disable Lint/Debugger
  end
end
