require 'ashttp'
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
require_relative 'common/backend_client_mixin'
require_relative 'common/tree_helper'
require_relative 'common/rspec_class_helpers'
require_relative 'common/driver'


$server_pids = []
$sleep_time = 0.0

module Selenium
  module Config
    def self.retries
      200
    end
  end
end


def cleanup
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

      if ENV['ASPACE_TEST_WITH_PRY']
        puts "Starting pry"
        binding.pry
      else
        raise $!
      end
    end
  end
end


def report_sleep
  puts "Total time spent sleeping: #{$sleep_time.inspect} seconds"
end



require 'uri'
require 'net/http'

module SeleniumTest

  def self.upload_file(path)
    uri = URI("http://aspace.hudmol.com/cgi-bin/store.cgi")

    req = Net::HTTP::Post.new(uri)
    req.body_stream = File.open(path, "rb")
    req.content_type = "application/octet-stream"
    req['Transfer-Encoding'] = 'chunked'

    ASHTTP.start_uri(uri) do |http|
      puts http.request(req).body
    end
  end

  def self.save_screenshot(driver)
    outfile = File.join( ENV['SCREENSHOT_DIR'] || Dir.tmpdir,  "#{Time.now.to_i}_#{$$}.png" ) 
    puts "Saving screenshot to #{outfile}"
    puts "Saving screenshot from Thread #{java.lang.Thread.currentThread.get_name}"

    driver.save_screenshot(outfile)

    # Send a copy of any screenshots to hudmol from Travis.  Feel free to zap
    # this if/when HM isn't development partner anymore!
    if ENV['TRAVIS']
      puts "Uploading screenshot..."
      upload_file(outfile)

      if ENV['INTEGRATION_LOGFILE'] &&
         File.exist?(ENV['INTEGRATION_LOGFILE']) &&
         !ENV['INTEGRATION_LOGFILE'].start_with?("/dev")
        upload_file(ENV['INTEGRATION_LOGFILE'])
      end
    end

      puts "save_screenshot complete"
  end
end
