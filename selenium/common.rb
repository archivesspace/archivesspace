require "net/http"
require "uri"
require "json"
require "selenium-webdriver"
require "digest"
require "rspec"
require "rspec/retry"
require 'test_utils'
require 'config/config-distribution'
require 'securerandom'

require_relative 'common/webdriver'
require_relative 'common/helper_mixin'

$server_pids = []
$sleep_time = 0.0


module Selenium
  module Config
    def self.retries
      100
    end
  end
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

  profile = Selenium::WebDriver::Firefox::Profile.new
  profile["browser.download.dir"] = Dir.tmpdir
  profile["browser.download.folderList"] = 2
  profile["browser.helperApps.alwaysAsk.force"] = false
  profile["browser.helperApps.neverAsk.saveToDisk"] = "application/pdf, application/xml"
  profile['pdfjs.disabled'] = true


  if ENV['FIREFOX_PATH']
    Selenium::WebDriver::Firefox.path = ENV['FIREFOX_PATH']
  end

  $driver = Selenium::WebDriver.for :firefox,:profile => profile
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
    if try < times #&& !ENV['ASPACE_TEST_NO_RETRIES']
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


def create_user
  user = "test user_#{SecureRandom.hex}"
  pass = "pass_#{SecureRandom.hex}"

  req = Net::HTTP::Post.new("/users?password=#{pass}")
  req.body = "{\"username\": \"#{user}\", \"name\": \"#{user}\"}"

  admin_backend_request(req)

  [user, pass]
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

def create_classification(values = {})
  default_values = { :title => "Classification #{SecureRandom.hex}",
                      :identifier => SecureRandom.hex
                    }
  values_to_post = default_values.merge(values)
  req = Net::HTTP::Post.new("#{$test_repo_uri}/classifications")
  req.body = values_to_post.to_json

  response = admin_backend_request(req)

  raise response.body if response.code != '200'
  uri = JSON.parse(response.body)['uri']

  [ uri, values_to_post[:title] ]
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


def create_resource(values = {}, repo = nil)

  # if we're passing a repo, we don't want to make a $test_repo, dig?
  if !$test_repo_uri && repo.nil?
    ($test_repo, $test_repo_uri) = create_test_repo("repo_#{SecureRandom.hex}", "description")
  end

  repo ||= $test_repo_uri

  default_values = {:title => "Test Resource #{SecureRandom.hex}",
    :id_0 => SecureRandom.hex, :level => "collection", :language => "eng",
    :dates => [ { :date_type => "single", :label => "creation", :expression => "1945" } ],
    :extents => [{:portion => "whole", :number => "1", :extent_type => "cassettes"}]}
  values_to_post = default_values.merge(values)

  req = Net::HTTP::Post.new("#{repo}/resources")
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
def login_as_archivist( create_new = false )
  if !$test_repo
    ($test_repo, $test_repo_uri) = create_test_repo("repo_#{SecureRandom.hex}", "description")
  end

  if !$archivist_user or create_new
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
  end
end
