require "net/http"
require "json"
require "selenium-webdriver"
require "digest"
require "rspec"
require_relative '../../common/test_utils'


$backend_port = TestUtils::free_port_from(3636)
$frontend_port = TestUtils::free_port_from(4545)
$backend = "http://localhost:#{$backend_port}"
$frontend = "http://localhost:#{$frontend_port}"
$expire = 30

class RSpec::Core::Example
  def passed?
    @exception.nil?
  end

  def failed?
    !passed?
  end
end


module Selenium
  module WebDriver
    module Firefox
      class Binary

        # Searching the registry causes a EXCEPTION_ACCESS_VIOLATION under
        # Windows 7.  Skip this step and just look for Firefox in the usual
        # places.
        def self.windows_registry_path
          nil
        end
      end
    end
  end

  module Config
    def self.retries
      20
    end
  end

end


class Selenium::WebDriver::Driver
  def wait_for_ajax
    while (self.execute_script("return document.readyState") != "complete" or
           not self.execute_script("return window.$ == undefined || $.active == 0"))
      sleep(0.2)
    end
  end

  alias :find_element_orig :find_element
  def find_element(*selectors)
    wait_for_ajax

    try = 0
    while true
      begin
        elt = find_element_orig(*selectors)

        if not elt.displayed?
          raise Selenium::WebDriver::Error::NoSuchElementError.new("Not visible (yet?)")
        end

        return elt
      rescue Selenium::WebDriver::Error::NoSuchElementError => e
        if try < Selenium::Config.retries
          try += 1
          sleep 0.5
        else
          puts "Failed to find #{selectors}"

          raise e
        end
      end
    end
  end


  def blocking_find_elements(*selectors)
    # Hit with find_element first to invoke our usual retry logic
    find_element(*selectors)

    find_elements(*selectors)
  end


  def ensure_no_such_element(*selectors)
    wait_for_ajax

    begin
      find_element_orig(*selectors)
      raise "Element was supposed to be absent: #{selectors}"
    rescue Selenium::WebDriver::Error::NoSuchElementError => e
      return true
    end
  end


  def click_and_wait_until_gone(*selector)
    element = self.find_element(*selector)
    element.click

    begin
      try = 0
      while self.find_element_orig(*selector).equal? element
        if try < Selenium::Config.retries
          try += 1
          sleep 0.5
        else
          raise Selenium::WebDriver::Error::NoSuchElementError.new(selector.inspect)
        end
      end
    rescue Selenium::WebDriver::Error::NoSuchElementError
      nil
    end
  end


  def complete_4part_id(pattern)
    accession_id = Digest::MD5.hexdigest("#{Time.now}#{$$}").scan(/.{6}/)[0...4]
    accession_id.each_with_index do |elt, i|
      self.clear_and_send_keys([:id, sprintf(pattern, i)], elt)
    end
  end


  def find_element_with_text(xpath, pattern, noError = false, noRetry = false)
    self.find_element(:tag_name => "body").find_element_with_text(xpath, pattern, noError, noRetry)
  end


  def clear_and_send_keys(selector, keys)
    Selenium::Config.retries.times do
      begin
        elt = self.find_element(*selector)
        elt.clear
        elt.send_keys(keys)
        break
      rescue
        sleep 0.5
      end
    end
  end


end


class Selenium::WebDriver::Element

  def select_option(value)
    self.find_elements(:tag_name => "option").each do |option|
      if option.attribute("value") === value
        option.click
        return
      end
    end

    raise "Couldn't select value: #{value}"
  end


  def get_select_value
    self.find_elements(:tag_name => "option").each do |option|
      return option.attribute("value") if option.attribute("checked")
    end

    return ""
  end

  def nearest_ancestor(xpath)
    self.find_element(:xpath => './ancestor-or-self::' + xpath + '[1]')
  end


  def containing_subform
    nearest_ancestor('div[contains(@class, "subrecord-form-fields")]')
  end


  def find_element_with_text(xpath, pattern, noError = false, noRetry = false)
    Selenium::Config.retries.times do

      matches = self.find_elements(:xpath => xpath)
      begin
        matches.each do | match |
          return match if match.text =~ pattern
        end
      rescue
        # Ignore exceptions and retry
      end

      if noRetry
        return nil
      end

      sleep 0.5
    end

    return nil if noError
    raise Selenium::WebDriver::Error::NoSuchElementError.new("Could not find element for xpath: #{xpath} pattern: #{pattern}")
  end

end



def logout(driver)
  ## Complete the logout process
  driver.find_element(:css, '.user-container .btn').click
  driver.find_element(:link, "Logout").click
  driver.find_element(:link, "Sign In")
end


RSpec.configure do |c|
  c.fail_fast = true
end


def cleanup
  @driver.quit if @driver

  if ENV["COVERAGE_REPORTS"] == 'true'
    begin
      TestUtils::get(URI("#{$frontend}/test/shutdown"))
    rescue
      # Expected to throw an error here, but that's fine.
    end
  else
    TestUtils::kill($frontend_pid) if $frontend_pid
  end

  TestUtils::kill($backend_pid) if $backend_pid
end



def selenium_init
  standalone = true

  if ENV["ASPACE_BACKEND_URL"] and ENV["ASPACE_FRONTEND_URL"]
    $backend = ENV["ASPACE_BACKEND_URL"]
    $frontend = ENV["ASPACE_FRONTEND_URL"]
    standalone = false
  end

  (@backend, @frontend) = [false, false]
  if standalone
    puts "Starting backend and frontend using #{$backend} and #{$frontend}"
    $backend_pid = TestUtils::start_backend($backend_port,
                                            {
                                              :frontend_url => $frontend,
                                              :session_expire_after_seconds => $expire
                                            })
    $frontend_pid = TestUtils::start_frontend($frontend_port, $backend)
  end

  @user = "testuser#{Time.now.to_i}_#{$$}"
  @driver = Selenium::WebDriver.for :firefox
  @driver.navigate.to $frontend
end


def assert(&block)
  try = 0

  begin
    block.call
  rescue
    try += 1
    if try < 20
      sleep 0.5
      retry
    else
      raise $!
    end
  end
end
