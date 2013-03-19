require "net/http"
require "json"
require "selenium-webdriver"
require "digest"
require "rspec"
require 'test_utils'
require 'config/config-distribution'


require_relative '../../common/test_utils'
require_relative '../../config/config-distribution'

$sleep_time = 0.0

$backend_port = TestUtils::free_port_from(3636)
$public_port = TestUtils::free_port_from(4546)
$backend = "http://localhost:#{$backend_port}"
$public = "http://localhost:#{$public_port}"
$expire = 300

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
      100
    end
  end

end


class Selenium::WebDriver::Driver
  def wait_for_ajax
    try = 0
    while (self.execute_script("return document.readyState") != "complete" or
      not self.execute_script("return window.$ == undefined || $.active == 0"))
      if (try > Selenium::Config.retries)
        raise "Retry limit hit on wait_for_ajax"
      end

      sleep(0.1)
      try += 1
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
          $sleep_time += 0.1
          sleep 0.1
          puts "find_element: #{try} misses on selector '#{selectors}'.  Retrying..." if (try % 5) == 0
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
          $sleep_time += 0.1
          sleep 0.1
          puts "click_and_wait_until_gone: #{try} hits selector '#{selector}'.  Retrying..." if (try % 5) == 0
        else
          raise Selenium::WebDriver::Error::NoSuchElementError.new(selector.inspect)
        end
      end
    rescue Selenium::WebDriver::Error::NoSuchElementError
      nil
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
        $sleep_time += 0.1
        sleep 0.1
      end
    end
  end


end


class Selenium::WebDriver::Element

  def find_element_with_text(xpath, pattern, noError = false, noRetry = false)
    Selenium::Config.retries.times do |try|

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

      $sleep_time += 0.1
      sleep 0.1
      puts "find_element_with_text: #{try} misses on selector ':xpath => #{xpath}'.  Retrying..." if (try % 10) == 0
    end

    return nil if noError
    raise Selenium::WebDriver::Error::NoSuchElementError.new("Could not find element for xpath: #{xpath} pattern: #{pattern}")
  end

end


RSpec.configure do |c|
  c.fail_fast = true
end


def cleanup
  $driver.quit if $driver

  TestUtils::kill($public_pid) if $public_pid
  TestUtils::kill($backend_pid) if $backend_pid
end



def selenium_init
  standalone = true

  if ENV["ASPACE_BACKEND_URL"] and ENV["ASPACE_PUBLIC_URL"]
    $backend = ENV["ASPACE_BACKEND_URL"]
    $public = ENV["ASPACE_PUBLIC_URL"]

    if ENV["ASPACE_SOLR_URL"]
      AppConfig[:solr_url] = ENV["ASPACE_SOLR_URL"]
    end

    standalone = false
  end

  AppConfig[:backend_url] = $backend

  (@backend, @public) = [false, false]
  if standalone
    puts "Starting backend and public using #{$backend} and #{$public}"
    $backend_pid = TestUtils::start_backend($backend_port,
                                            {
                                              :public_url => $public,
                                              :session_expire_after_seconds => $expire
                                            })
    $public_pid = TestUtils::start_public($public_port, $backend)
  end


  if ENV['TRAVIS']
    puts "Loading stable version of Firefox"
    system('wget', 'http://aspace.hudmol.com/firefox-16.0.tar.bz2')
    system('tar', 'xvjf', 'firefox-16.0.tar.bz2')
    ENV['PATH'] = (File.join(Dir.getwd, 'firefox') + ':' + ENV['PATH'])
  end


  $driver = Selenium::WebDriver.for :firefox
  $driver.manage.window.maximize

  # create a test repo
  ($test_repo, $test_repo_uri) = create_test_repo("repo_#{Time.now.to_i}_#{$$}", "description")
end


def assert(&block)
  try = 0

  begin
    block.call
  rescue
    try += 1
    if try < Selenium::Config.retries
      $sleep_time += 0.1
      sleep 0.1
      retry
    else
      puts "Assert giving up"
      raise $!
    end
  end
end


def admin_backend_request(req)
  res = Net::HTTP.post_form(URI("#{$backend}/users/admin/login"), :password => "admin")
  admin_session = JSON(res.body)["session"]

  req["X-ARCHIVESSPACE-SESSION"] = admin_session

  uri = URI("#{$backend}")

  Net::HTTP.start(uri.hostname, uri.port) do |http|
    res = http.request(req)

    if res.code != "200"
      raise "Bad response: #{res.body}"
    end

    res
  end
end


def create_test_repo(code, name, wait = true)
  create_repo = URI("#{$backend}/repositories")

  req = Net::HTTP::Post.new(create_repo.path)
  req.body = "{\"repo_code\": \"#{code}\", \"name\": \"#{name}\"}"

  response = admin_backend_request(req)
  repo_uri = JSON.parse(response.body)['uri']


  # Give the notification time to fire
  sleep 5 if wait

  [code, repo_uri]
end


def report_sleep
  puts "Total time spent sleeping: #{$sleep_time.inspect} seconds"
end
