require "net/http"
require "uri"
require "json"
require "selenium-webdriver"
require "digest"
require "rspec"
require 'test_utils'
require 'config/config-distribution'
require 'securerandom'

$server_pids = []
$sleep_time = 0.0


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
      10
    end
  end

end


class Selenium::WebDriver::Driver
  def wait_for_ajax
    try = 0
    while (self.execute_script("return document.readyState") != "complete" or
      not self.execute_script("return window.$ == undefined || $.active == 0"))
      if (try > Selenium::Config.retries)
        puts "Retry limit hit on wait_for_ajax.  Going ahead anyway."
        break
      end

      sleep(0.5)
      try += 1
    end

    raise_javascript_errors
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
          sleep 0.5
          puts "find_element: #{try} misses on selector '#{selectors}'.  Retrying..." if (try % 5) == 0
        else
          puts "Failed to find #{selectors}"

          if ENV['SCREENSHOT_ON_ERROR']
            SeleniumTest.save_screenshot
          end

          raise e
        end
      end
    end
  end


  def find_last_element(*selectors)
    result = blocking_find_elements(*selectors)

    result[result.length - 1]
  end


  def blocking_find_elements(*selectors)
    # Hit with find_element first to invoke our usual retry logic
    find_element(*selectors)

    find_elements(*selectors)
  end


  def ensure_no_such_text(xpath, pattern, noError = false, noRetry = true )
    wait_for_ajax 
    begin
      element = self.find_element(:tag_name => "body").find_element_with_text(xpath, pattern, noError, noRetry)

      if element.nil? or !element.displayed?
        true 
      else
        raise "Element was supposed to be absent: #{xpath} #{pattern}"
      end
    rescue Selenium::WebDriver::Error::NoSuchElementError => e
      return true
    end
  end


  def ensure_no_such_element(*selectors)
    wait_for_ajax

    begin
      element = find_element_orig(*selectors)

      if element.displayed?
        raise "Element was supposed to be absent: #{selectors}"
      else
        true
      end
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
          sleep 0.5
          puts "click_and_wait_until_gone: #{try} hits selector '#{selector}'.  Retrying..." if (try % 5) == 0
        else
          raise Selenium::WebDriver::Error::NoSuchElementError.new(selector.inspect)
        end
      end
    rescue Selenium::WebDriver::Error::NoSuchElementError
      nil
    end
  end


  def generate_4part_id
    Digest::MD5.hexdigest("#{Time.now}#{SecureRandom.uuid}#{$$}").scan(/.{6}/)[0...1]
  end

  def complete_4part_id(pattern, accession_id = nil)
    # Was 4, but now that the input boxes are disabled this wasn't filling out the last 3.
    accession_id ||= generate_4part_id
    accession_id.each_with_index do |elt, i|
      self.clear_and_send_keys([:id, sprintf(pattern, i)], elt)
    end

    accession_id
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
        sleep 0.3
      end
    end
  end

  def raise_javascript_errors
    errors = $driver.execute_script("return window.hasOwnProperty('TEST_ERRORS') ? TEST_ERRORS : []")
    raise "Javascript errors present: #{errors.inspect}" if errors.length > 0
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


  def select_option_with_text(value)
    self.find_elements(:tag_name => "option").each do |option|
      if option.text === value
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


  def find_last_element(*selectors)
    result = find_elements(*selectors)

    result[result.length - 1]
  end


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
      sleep 0.5
      puts "find_element_with_text: #{try} misses on selector ':xpath => #{xpath}'.  Retrying..." if (try % 10) == 0
    end

    return nil if noError
    raise Selenium::WebDriver::Error::NoSuchElementError.new("Could not find element for xpath: #{xpath} pattern: #{pattern}")
  end

end



def login(user, pass)
  $driver.navigate.to $frontend

  $driver.find_element(:link, "Sign In").click
  $driver.clear_and_send_keys([:id, 'user_username'], user)
  $driver.clear_and_send_keys([:id, 'user_password'], pass)
  $driver.find_element(:id, 'login').click
end


def logout
  $driver.navigate.to $frontend
  ## Complete the logout process
  user_menu = $driver.find_elements(:css, '.user-container .dropdown-menu.pull-right').first
  if !user_menu || !user_menu.displayed?
    $driver.find_element(:css, 'body').find_element(:css, '.user-container .btn.dropdown-toggle').click
  end

  $driver.find_element(:link, "Logout").click
  $driver.find_element(:link, "Sign In")
end


# Drop a call to this into a Selenium test block to work with the browser
# interactively.  Useful during test development!
def debug_repl
  $stderr.puts("Debug REPL active.  Type :eof to abort")
  while true
    line = $stdin.readline
    break if line.strip == ":eof"
    begin
      puts eval(line).inspect
    rescue
      puts $!
    end
  end
end


RSpec.configure do |c|
  c.fail_fast = true
end


def cleanup
  $driver.quit if $driver

  if ENV["COVERAGE_REPORTS"] == 'true'
    begin
      TestUtils::get(URI("#{$frontend}/test/shutdown"))
    rescue
      # Expected to throw an error here, but that's fine.
    end
  end

  $server_pids.each do |pid|
    TestUtils::kill(pid)
  end
end



def selenium_init(backend_fn, frontend_fn)
  standalone = true

  if ENV["ASPACE_BACKEND_URL"] and ENV["ASPACE_FRONTEND_URL"]
    $backend = ENV["ASPACE_BACKEND_URL"]
    $frontend = ENV["ASPACE_FRONTEND_URL"]

    if ENV["ASPACE_SOLR_URL"]
      AppConfig[:solr_url] = ENV["ASPACE_SOLR_URL"]
    end

    AppConfig[:help_enabled] = true
    AppConfig[:help_url] = "http://localhost:9999/help_stub"
    AppConfig[:help_topic_prefix] = "?topic="

    standalone = false
  end


  AppConfig[:backend_url] = $backend

  (@backend, @frontend) = [false, false]
  if standalone
    puts "Starting backend and frontend using #{$backend} and #{$frontend}"
    $server_pids << backend_fn.call
    $server_pids << frontend_fn.call
  end

  @user = "testuser#{Time.now.to_i}_#{$$}"


  if ENV['TRAVIS'] && ENV['WITH_FIREFOX']
    puts "Loading stable version of Firefox and nodejs"
    Dir.chdir('/var/tmp') do
      firefox_archive = "firefox-16.0.tar.bz2"
      if `uname --machine`.strip == "x86_64"
        firefox_archive = "firefox_x86_64-16.0.tar.bz2"
      end

      system('wget', "http://aspace.hudmol.com/#{firefox_archive}")
      system('tar', 'xvjf', firefox_archive)
      ENV['PATH'] = (File.join(Dir.getwd, 'firefox') + ':' + ENV['PATH'])


      puts "Path now: #{ENV['PATH']}"
      puts "Firefox version:"
      system('firefox', '--version')
    end
  end

  system("rm #{File.join(Dir.tmpdir, '*.pdf')}")
  system("rm #{File.join(Dir.tmpdir, '*.xml')}")

  puts "get profile"
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile["browser.download.dir"] = Dir.tmpdir 
  profile["browser.download.folderList"] = 2
  profile["browser.helperApps.alwaysAsk.force"] = false
  profile["browser.helperApps.neverAsk.saveToDisk"] = "application/pdf, application/xml"
  profile['pdfjs.disabled'] = true

  puts profile.inspect
  puts "get driver"
  $driver = Selenium::WebDriver.for :firefox,:profile => profile
  puts "got driver"
  $wait   = Selenium::WebDriver::Wait.new(:timeout => 10)
  $driver.manage.window.maximize
end


def assert(times = nil, &block)
  try = 0
  times ||= Selenium::Config.retries

  begin
    block.call
  rescue
    try += 1
    if try < times
      $sleep_time += 0.1
      sleep 0.5
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
  req["X-ARCHIVESSPACE-PRIORITY"] = "high"

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


def create_user
  user = "test user_#{SecureRandom.hex}"
  pass = "pass_#{SecureRandom.hex}"

  req = Net::HTTP::Post.new("/users?password=#{pass}")
  req.body = "{\"username\": \"#{user}\", \"name\": \"#{user}\"}"

  admin_backend_request(req)

  [user, pass]
end


def select_repo(code)
  $driver.find_element(:link, 'Select Repository').click
  $driver.find_element(:css, '.select-a-repository').find_element(:id => "id").select_option_with_text(code)
  $driver.find_element(:css, '.select-a-repository .btn-primary').click
end


def add_user_to_archivists(user, repo)
  add_user_to_group(user, repo, 'repository-archivists')
end


def add_user_to_managers(user, repo)
  add_user_to_group(user, repo, 'repository-managers')
end

def add_user_to_viewers(user, repo)
  add_user_to_group(user, repo, 'repository-viewers')
end
	

def add_user_to_group(user, repo, group_code)
  req = Net::HTTP::Get.new("#{repo}/groups")

  groups = admin_backend_request(req)

  uri = JSON.parse(groups.body).find {|group| group['group_code'] == group_code}['uri']

  req = Net::HTTP::Get.new(uri)
  group = JSON.parse(admin_backend_request(req).body)
  group['member_usernames'] = [user]

  req = Net::HTTP::Post.new(uri)
  req.body = group.to_json

  admin_backend_request(req)
end


def create_accession(values = {})
  accession_data = {:id_0 => SecureRandom.hex, :accession_date => "2000-01-01"}.merge(values)

  title = accession_data[:title]

  req = Net::HTTP::Post.new("#{$test_repo_uri}/accessions")
  req.body = accession_data.to_json

  response = admin_backend_request(req)

  raise response.body if response.code != '200'

  title
end


def create_digital_object(values = {})
  default_values = { :title => "Digital Object #{SecureRandom.hex}",
                      :digital_object_id => SecureRandom.hex
                    }
  values_to_post = default_values.merge(values)
  req = Net::HTTP::Post.new("#{$test_repo_uri}/digital_objects")
  req.body = values_to_post.to_json

  response = admin_backend_request(req)

  raise response.body if response.code != '200'
  uri = JSON.parse(response.body)['uri']

  [ uri, values_to_post[:title] ]
end


def create_resource(values = {})
  if !$test_repo
    ($test_repo, $test_repo_uri) = create_test_repo("repo_#{SecureRandom.hex}", "description")
  end

  default_values = {:title => "Test Resource #{SecureRandom.hex}",
    :id_0 => SecureRandom.hex, :level => "collection", :language => "eng",
    :dates => [ { :date_type => "single", :label => "creation", :expression => "1945" } ],
    :extents => [{:portion => "whole", :number => "1", :extent_type => "files"}]}
  values_to_post = default_values.merge(values)

  req = Net::HTTP::Post.new("#{$test_repo_uri}/resources")
  req.body = values_to_post.to_json

  response = admin_backend_request(req)

  raise response.body if response.code != '200'

  uri = JSON.parse(response.body)['uri']

  [uri, values_to_post[:title]]
end


def create_archival_object(values = {})

  if !$test_repo
    ($test_repo, $test_repo_uri) = create_test_repo("repo_#{SecureRandom.hex}", "description")
  end

  if not values.has_key?(:resource)
    # need to create a resource
    resource_uri, resource_title = create_resource
    values[:resource] = {:ref => resource_uri}
  end

  default_values = {:title => "Test Archival Object #{SecureRandom.hex}", :level => "item"}
  values_to_post = default_values.merge(values)

  req = Net::HTTP::Post.new("#{$test_repo_uri}/archival_objects")
  req.body = values_to_post.to_json

  response = admin_backend_request(req)

  raise response.body if response.code != '200'

  uri = JSON.parse(response.body)['uri']

  [uri, values_to_post[:title]]
end


def create_agent(name, values = {})
  req = Net::HTTP::Post.new("/agents/people")
  req.body = {
    "agent_contacts" => [],
    "agent_type" => "agent_person",
    "names" => [
      {
        "name_order" => "inverted",
        "authority_id" => SecureRandom.hex,
        "primary_name" => name,
        "rest_of_name" => name,
        "sort_name" => name,
        "sort_name_auto_generate" => false,
        "source" => "local"
      }
    ],
  }.merge(values).to_json


  response = admin_backend_request(req)

  raise response.body if response.code != '200'

  uri = JSON.parse(response.body)['uri']

  [uri, name]
end


def create_subject(values = {})
  subject_hash = {
    "source" => "local",
    "terms" => [{
                  "term" => SecureRandom.hex,
                  "term_type" => "cultural_context",
                  "vocabulary" => "/vocabularies/1"
                }],
    "vocabulary" => "/vocabularies/1"
  }.merge(values)

  req = Net::HTTP::Post.new("/subjects")
  req.body = subject_hash.to_json

  response = admin_backend_request(req)

  raise response.body if response.code != '200'

  [JSON.parse(response.body)['uri'], subject_hash["terms"].map{|t| t["term"]}.join(" -- ")]
end


# A few globals here to allow things to be re-used between nested suites.
def login_as_archivist
  if !$test_repo
    ($test_repo, $test_repo_uri) = create_test_repo("repo_#{SecureRandom.hex}", "description")
  end

  if !$archivist_user
    ($archivist_user, $archivist_pass) = create_user
    add_user_to_archivists($archivist_user, $test_repo_uri)
  end


  login($archivist_user, $archivist_pass)

  select_repo($test_repo)
end

def login_as_viewer
  if !$test_repo
    ($test_repo, $test_repo_uri) = create_test_repo("repo_#{SecureRandom.hex}", "description")
  end

  if !$viewer_user
    ($viewer_user, $viewer_pass) = create_user
    add_user_to_viewers($viewer_user, $test_repo_uri)
  end


  login($viewer_user, $viewer_pass)

  select_repo($test_repo)
end


def login_as_repo_manager
  if !$test_repo
    ($test_repo, $test_repo_uri) = create_test_repo("repo_#{SecureRandom.hex}", "description")
  end

  if !$repo_manager_user
    ($repo_manager_user, $repo_manager_password) = create_user
    add_user_to_managers($repo_manager_user, $test_repo_uri)
  end


  login($repo_manager_user, $repo_manager_password)

  select_repo($test_repo)
end


def login_as_admin
  if !$test_repo
    ($test_repo, $test_repo_uri) = create_test_repo("repo_#{SecureRandom.hex}", "description")
  end

  login("admin", "admin")

  select_repo($test_repo)
end


def report_sleep
  puts "Total time spent sleeping: #{$sleep_time.inspect} seconds"
end



module SeleniumTest
  def self.save_screenshot
    outfile = "/tmp/#{Time.now.to_i}_#{$$}.png"
    puts "Saving screenshot to #{outfile}"
    $driver.save_screenshot(outfile)

    if ENV['TRAVIS']
      # Send it back to the hudmol devserver
      system('curl', '-H', 'Content-Type: application/octet-stream',
             '--data-binary', "@#{outfile}", 'http://aspace.hudmol.com/cgi-bin/store.cgi')
    end
  end
end
