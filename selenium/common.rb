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
require_relative 'common/backend_client_mixin'
require_relative 'common/jstree_helper'
require_relative 'common/rspec_class_helpers'
require_relative 'common/driver'


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


def report_sleep
  puts "Total time spent sleeping: #{$sleep_time.inspect} seconds"
end



module SeleniumTest
  def self.save_screenshot(driver)
    outfile = "/tmp/#{Time.now.to_i}_#{$$}.png"
    puts "Saving screenshot to #{outfile}"
    driver.save_screenshot(outfile)
  end
end
