# frozen_string_literal: true

require_relative 'webdriver'
require 'mechanize'
require 'tempfile'
require 'fileutils'

# Increase Selenium's HTTP read timeout from the default of 60.  Address
# Net::ReadTimeout errors on Travis.
module Selenium
  module WebDriver
    module Remote
      module Http
        class Default < Common
          def read_timeout
            120
          end
        end
      end
    end
  end
end

class Driver
  def self.get(frontend = $frontend)
    instance = Driver.new(frontend)

    @current_instance = instance

    instance
  end

  class << self
    attr_reader :current_instance
  end

  def initialize_ff
    profile = Selenium::WebDriver::Firefox::Profile.new
    FileUtils.rm('/tmp/firefox_console', force: true)
    profile['webdriver.log.file'] = '/tmp/firefox_console'

    # Options: OFF SHOUT SEVERE WARNING INFO CONFIG FINE FINER FINEST ALL
    profile['webdriver.log.level'] = 'ALL'
    profile['browser.download.dir'] = Dir.tmpdir
    profile['browser.download.folderList'] = 2
    profile['browser.helperApps.alwaysAsk.force'] = false
    profile['browser.helperApps.neverAsk.saveToDisk'] = 'application/msword, application/csv, application/pdf, application/xml,  application/ris, text/csv, image/png, application/pdf, text/html, text/plain, application/zip, application/x-zip, application/x-zip-compressed'
    profile['pdfjs.disabled'] = true
    options = Selenium::WebDriver::Firefox::Options.new(args: @firefox_opts)
    options.profile = profile
    Selenium::WebDriver.for :firefox, options: options
  end

  def initialize_chrome
    # Options: OFF SHOUT SEVERE WARNING INFO CONFIG FINE FINER FINEST ALL
    opts = Selenium::WebDriver::Chrome::Options.new(
      prefs: { download: { default_directory: Dir.tmpdir,
                           directory_upgrade: true,
                           extensions_to_open: '',
                           prompt_for_download: false } },
      args: @chrome_opts
    )
    Selenium::WebDriver.for :chrome, options: opts
  end

  def ff_or_chrome
    if ENV['SELENIUM_CHROME']
      initialize_chrome
    else
      # https://github.com/mozilla/geckodriver/issues/1354
      ENV['MOZ_HEADLESS_WIDTH'] = ENV.fetch('MOZ_HEADLESS_WIDTH', '1920')
      ENV['MOZ_HEADLESS_HEIGHT'] = ENV.fetch('MOZ_HEADLESS_WIDTH', '1080')
      initialize_ff
    end
  end

  def initialize(frontend = $frontend)
    @frontend = frontend

    @chrome_opts  = ENV.fetch('CHROME_OPTS', '--headless,--disable-gpu,--window-size=1920x1080').split(',')
    @firefox_opts = ENV.fetch('FIREFOX_OPTS', '-headless').split(',')

    @driver = ff_or_chrome
    @wait   = Selenium::WebDriver::Wait.new(timeout: 10)
    @driver.manage.window.maximize
  end

  def method_missing(meth, *args)
    @driver.send(meth, *args)
  end

  def login(user, expect_fail = false)
    go_home
    @driver.wait_for_ajax
    @driver.clear_and_send_keys([:id, 'user_username'], user.username)
    @driver.clear_and_send_keys([:id, 'user_password'], user.password)

    if expect_fail
      @driver.find_element(:id, 'login').click
    else
      @driver.click_and_wait_until_gone(:id, 'login')
    end

    self
  end

  def logout
    tries = 5
    begin
      @driver.manage.delete_all_cookies
      @driver.navigate.to @frontend
    rescue Exception => e
      if tries > 0
        puts "logout failed... try again! #{tries} tries left."
        tries -= 1
        retry
      else
        puts 'logout failed... no more trying'
        raise e
      end
    end

    self
  end

  def go_home
    @driver.get(@frontend)

    self
  end

  def get_edit_page(json_obj)
    if json_obj.jsonmodel_type == 'archival_object'
      @driver.get("#{@frontend}#{json_obj.resource['ref'].sub(%r{/repositories/\d+}, '')}/edit#tree::archival_object_#{json_obj.uri.sub(%r{.*/}, '')}")
    else
      @driver.get("#{@frontend}#{json_obj.uri.sub(%r{/repositories/\d+}, '')}/edit")
    end
  end

  def get_view_page(json_obj)
    @driver.get("#{@frontend}#{json_obj.uri.sub(%r{/repositories/\d+}, '')}")
  end

  def select_repo(code)
    code = code.respond_to?(:repo_code) ? code.repo_code : code

    @driver.find_element(:link, 'Select Repository').click
    @driver.find_element(:css, '.select-a-repository').find_element(id: 'id').select_option_with_text(code)
    @driver.click_and_wait_until_gone(:css, '.select-a-repository .btn-primary')

    if block_given?
      $test_repo_old = $test_repo
      $test_repo_uri_old = $test_repo_uri

      $test_repo = code
      $test_repo_uri = @test_repositories[code]
      yield

      $test_repo = $test_repo_old
      $test_repo_uri = $test_repo_uri_old
    end

    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /is now active/)
  end

  # so chrome in headless mode isn't dt d/l (down to download )
  # This is a hack that grabs the files and sticks it in the temp directory
  # pass in a link element...
  def download_file(el)
    if @driver.browser == :chrome
      mech_agent = Mechanize.new
      form = mech_agent.get(@frontend).form
      form.field_with(name: 'username').value = 'admin'
      form.field_with(name: 'password').value = 'admin'
      form.submit

      tmp = Tempfile.new('mech')
      begin
        dl = mech_agent.download(el['href'], tmp.path)
        FileUtils.mv(tmp.path, File.join(Dir.tmpdir, dl.response['content-disposition'].split('=').last))
      ensure
        tmp.close
        tmp.unlink
      end
    # not chrome we can just click it and quit it
    else
      el.click
    end
  end

  def login_to_repo(user, repo)
    tries = 5

    begin
      logout
      @driver.wait_for_ajax
    rescue StandardError # maybe we were already logged out
    end

    begin
      login(user)
      select_repo(repo)
    rescue StandardError # maybe we didn't quite log out
      tries -= 1
      if tries > 0
        logout
        @driver.wait_for_ajax
        retry
      end
    end

    self
  end

  SPINNER_RETRIES = 100

  def wait_for_spinner
    puts "    Awaiting spinner... (#{caller[0]})"

    SPINNER_RETRIES.times do
      is_spinner_visible = execute_script("return $('.spinner').is(':visible')")
      is_blockout_visible = execute_script("return $('.blockout').is(':visible')")
      break unless is_spinner_visible || is_blockout_visible

      sleep 0.2
    end
  end

  def generate_4part_id
    Digest::MD5.hexdigest("#{Time.now}#{SecureRandom.uuid}#{$$}").scan(/.{6}/)[0...1]
  end

  def attempt(times, &block)
    tries = times

    begin
      block.call(self)
    rescue Exception => e
      if tries > 0
        tries -= 1
        $sleep_time += 0.1
        sleep 0.5
        puts "Attempts remaining: #{tries}"
        retry
      else
        raise e
      end
    end
  end
end
