require_relative 'webdriver'

class Driver

  def self.get(frontend = $frontend)
    instance = Driver.new(frontend)

    @current_instance = instance

    instance
  end

  def self.current_instance
    # A bit gross to do this, but we want to be able to access the last instance
    # for the sake of taking screenshots when things fail.
    @current_instance
  end

  def initialize(frontend = $frontend)
    @frontend = frontend
    profile = Selenium::WebDriver::Firefox::Profile.new
    FileUtils.rm("/tmp/firefox_console", :force => true)
    profile["webdriver.log.file"] = "/tmp/firefox_console"

    # Options: OFF SHOUT SEVERE WARNING INFO CONFIG FINE FINER FINEST ALL
    profile["webdriver.log.level"] = "ALL"
    profile["browser.download.dir"] = Dir.tmpdir
    profile["browser.download.folderList"] = 2
    profile["browser.helperApps.alwaysAsk.force"] = false
    profile["browser.helperApps.neverAsk.saveToDisk"] = "application/msword, application/csv, application/pdf, application/xml,  application/ris, text/csv, image/png, application/pdf, text/html, text/plain, application/zip, application/x-zip, application/x-zip-compressed"
    profile['pdfjs.disabled'] = true

    if java.lang.System.getProperty('os.name').downcase == 'linux'
      ENV['PATH'] = "#{File.join(ASUtils.find_base_directory, 'selenium', 'bin', 'geckodriver', 'linux')}:#{ENV['PATH']}"
    else #osx
      ENV['PATH'] = "#{File.join(ASUtils.find_base_directory, 'selenium', 'bin', 'geckodriver', 'osx')}:#{ENV['PATH']}"
    end


    if ENV['FIREFOX_PATH']
      Selenium::WebDriver::Firefox.path = ENV['FIREFOX_PATH']
    end

    @driver = Selenium::WebDriver.for :firefox,:profile => profile
    @wait   = Selenium::WebDriver::Wait.new(:timeout => 10)
    @driver.manage.window.maximize
  end

  def method_missing(meth, *args)
    @driver.send(meth, *args)
  end

  def login(user, expect_fail = false)
    self.go_home
    @driver.wait_for_ajax
    @driver.find_element(:link, "Sign In").click
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
      @driver.find_element(:link, "Sign In")
    rescue Exception => e
      if tries > 0
        puts "logout failed... try again! #{tries} tries left."
        tries -=1
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
      @driver.get("#{@frontend}#{json_obj.resource['ref'].sub(/\/repositories\/\d+/, '')}/edit#tree::archival_object_#{json_obj.uri.sub(/.*\//, '')}")
    else
      @driver.get("#{@frontend}#{json_obj.uri.sub(/\/repositories\/\d+/, '')}/edit")
    end
  end


  def get_view_page(json_obj)
    @driver.get("#{@frontend}#{json_obj.uri.sub(/\/repositories\/\d+/, '')}")
  end


  def select_repo(code)
    code = code.respond_to?(:repo_code) ? code.repo_code : code

    @driver.find_element(:link, 'Select Repository').click
    @driver.find_element(:css, '.select-a-repository').find_element(:id => "id").select_option_with_text(code)
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


  def login_to_repo(user, repo)
    tries = 5

    begin
      logout
      @driver.wait_for_ajax
    rescue # maybe we were already logged out
    end

    begin
      login(user)
      select_repo(repo)
    rescue # maybe we didn't quite log out
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
      is_spinner_visible = self.execute_script("return $('.spinner').is(':visible')")
      is_blockout_visible = self.execute_script("return $('.blockout').is(':visible')")
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
