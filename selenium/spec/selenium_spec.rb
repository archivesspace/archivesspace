require "net/http"
require "selenium-webdriver"
require "digest"
require "rspec"
require_relative '../../common/test_utils'


$backend_port = 3636
$frontend_port = 3535
$backend = "http://localhost:#{$backend_port}"
$frontend = "http://localhost:#{$frontend_port}"


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
end


class Selenium::WebDriver::Driver
  RETRIES = 20

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
        if try < RETRIES
          try += 1
          sleep 0.5
        else
          puts "Failed to find #{selectors}"
          puts "Type a replacement for '#{selectors.inspect}'"
          replacement = [selectors.first, STDIN.readline.chomp]
          puts "Trying again with '#{replacement.inspect}'"
          return self.find_element(*replacement)

          # raise e
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
        if try < RETRIES
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
    RETRIES.times do

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


  def clear_and_send_keys(selector, keys)
    RETRIES.times do
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
  #@driver.quit if @driver

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



describe "ArchivesSpace user interface" do

  # Start the dev servers and Selenium
  before(:all) do
    standalone = true

    if ENV["ASPACE_BACKEND_URL"] and ENV["ASPACE_FRONTEND_URL"]
      $backend = ENV["ASPACE_BACKEND_URL"]
      $frontend = ENV["ASPACE_FRONTEND_URL"]
      standalone = false
    end

    (@backend, @frontend) = [false, false]
    if standalone
      $backend_pid = TestUtils::start_backend($backend_port)
      $frontend_pid = TestUtils::start_frontend($frontend_port, $backend)
    end

    @user = "testuser#{Time.now.to_i}_#{$$}"
    @driver = Selenium::WebDriver.for :firefox
    @driver.navigate.to $frontend
  end


  # Stop selenium, kill the dev servers
  after(:all) do
    cleanup
  end


  after(:each) do |group|
    begin
      if group.example.exception and ENV['SCREENSHOT_ON_ERROR']
        outfile = "/tmp/#{Time.now.to_i}_#{$$}.png"
        puts "Saving screenshot to #{outfile}"
        @driver.save_screenshot(outfile)
      end
    end
  end


  ### Examples


  # Users and authentication

  it "fails logins with invalid credentials" do
    @driver.find_element(:link, "Sign In").click
    @driver.clear_and_send_keys([:id, 'user_username'], "oopsie")
    @driver.clear_and_send_keys([:id, 'user_password'], "daisies")
    @driver.find_element(:id, 'login').click

    @driver.find_element(:css => "p.help-inline.login-message").text.should eq('Login attempt failed')

    @driver.find_element(:link, "Sign In").click
  end


  it "can register a new user" do
    @driver.find_element(:link, "Sign In").click
    @driver.find_element(:link, "Register now").click

    @driver.clear_and_send_keys([:id, "user_username_"], @user)
    @driver.clear_and_send_keys([:id, "user_name_"], @user)
    @driver.clear_and_send_keys([:id, "user_password_"], "testuser")
    @driver.clear_and_send_keys([:id, "user_confirm_password_"], "testuser")

    @driver.find_element(:id, 'create_account').click

    @driver.find_element(:css => "span.user-label").text.should match(/#{@user}/)
  end


  it "but they have no repositories yet!" do
    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:css, '.repository-container .dropdown-menu').text.should match(/No repositories/)
  end

  it "can log out" do
    logout(@driver)
    @driver.find_element(:link, "Sign In").text.should eq "Sign In"
  end


  it "logs in as admin" do
    @driver.find_element(:link, "Sign In").click
    @driver.clear_and_send_keys([:id, 'user_username'], "admin")
    @driver.clear_and_send_keys([:id, 'user_password'], "admin")

    @driver.find_element(:id, 'login').click
  end


  # Repositories

  test_repo_code_1 = "test1#{Time.now.to_i}_#{$$}"
  test_repo_name_1 = "test repository 1 - #{Time.now}"
  test_repo_code_2 = "test2#{Time.now.to_i}_#{$$}"
  test_repo_name_2 = "test repository 2 - #{Time.now}"


  it "flags errors when creating a repository with missing fields" do
    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link, "Create a Repository").click
    @driver.clear_and_send_keys([:id, "repository_description_"], "missing repo code")
    @driver.find_element(:css => "form#new_repository input[type='submit']").click

    @driver.find_element(:css => "div.alert.alert-error").text.should eq('Repository code - Property is required but was missing')
    @driver.find_element(:css => "div.modal-footer button.btn").click
  end


  it "can create a repository" do
    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link, "Create a Repository").click
    @driver.clear_and_send_keys([:id, "repository_repo_code_"], test_repo_code_1)
    @driver.clear_and_send_keys([:id, "repository_description_"], test_repo_name_1)
    @driver.find_element(:css => "form#new_repository input[type='submit']").click

  end


  it "can create a second repository" do
    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link, "Create a Repository").click
    @driver.clear_and_send_keys([:id, "repository_repo_code_"], test_repo_code_2)
    @driver.clear_and_send_keys([:id, "repository_description_"], test_repo_name_2)
    @driver.find_element(:css => "form#new_repository input[type='submit']").click
  end


  it "can select either of the created repositories" do
    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link_text => test_repo_code_2).text.should eq test_repo_code_2
    @driver.find_element(:link_text => test_repo_code_2).click
    @driver.find_element(:css, 'span.current-repository-id').text.should eq test_repo_code_2

    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link_text => test_repo_code_1).text.should eq test_repo_code_1
    @driver.find_element(:link_text => test_repo_code_1).click
    @driver.find_element(:css, 'span.current-repository-id').text.should eq test_repo_code_1

    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link_text => test_repo_code_2).click
    @driver.find_element(:css, 'span.current-repository-id').text.should eq test_repo_code_2
  end


  it "can assign the test user to the archivist group" do
    @driver.find_element(:link, "Admin").click
    @driver.find_element(:link, "Groups").click

    row = @driver.find_element_with_text('//tr', /repository-archivists/)
    row.find_element(:css, '.btn').click

    @driver.clear_and_send_keys([:id, 'new-member'],(@user))
    @driver.find_element(:id, 'add-new-member').click
    @driver.find_element(:css => 'input[type="submit"]').click
  end


  it "can assign the test user to the viewers group of the first repository" do
    # Select the first repository
    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link_text => test_repo_code_1).click

    @driver.find_element(:link, "Admin").click
    @driver.find_element(:link, "Groups").click

    row = @driver.find_element_with_text('//tr', /repository-viewers/)
    row.find_element(:css, '.btn').click

    @driver.clear_and_send_keys([:id, 'new-member'],(@user))
    @driver.find_element(:id, 'add-new-member').click
    @driver.find_element(:css => 'input[type="submit"]').click
  end


  it "can log out of the admin account" do
    logout(@driver)
  end


  it "can log in with the user just created" do
    @driver.find_element(:link, "Sign In").click
    @driver.clear_and_send_keys([:id, 'user_username'], @user)
    @driver.clear_and_send_keys([:id, 'user_password'], "testuser")
    @driver.find_element(:id, 'login').click

    @driver.find_element(:css => "span.user-label").text.should match(/#{@user}/)
  end


  it "doesn't see the 'Create' menu in the first repository" do
    # Wait until we're marked as logged in
    @driver.find_element_with_text('//span', /#{@user}/)

    if not @driver.find_element_with_text('//span', /#{test_repo_code_1}/, true, true)
      @driver.find_element(:css, '.repository-container .btn').click

      # Select the first repo since it wasn't selected already
      @driver.find_element(:link_text => test_repo_code_1).click
      @driver.find_element_with_text('//span[class="current-repository-id"]', /#{test_repo_code_1}/)
    end

    @driver.ensure_no_such_element(:link, "Create")
  end


  it "can select the second repository and find the create link" do
    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link_text => test_repo_code_2).click

    # Wait until it's selected
    @driver.find_element_with_text('//span', /#{test_repo_code_2}/)
    @driver.find_element(:link, "Create")
  end


  # Subjects

## fix in process ##   it "reports errors and warnings when creating an invalid Subject" do
## fix in process ##     @driver.find_element(:link => 'Create').click
## fix in process ##     @driver.find_element(:link => 'Subject').click
## fix in process ## 
## fix in process ##     @driver.find_element(:css => '#subject_external_documents_ .subrecord-form-heading .btn').click
## fix in process ## 
## fix in process ##     @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click
## fix in process ## 
## fix in process ##     # check messages
## fix in process ##     @driver.find_element(:css, ".errors-terms_0_term").text.should eq("Term - Property was missing")
## fix in process ##   end

  # Person Agents

## debug ##   it "reports errors and warnings when creating an invalid Person Agent" do
## debug ##     @driver.find_element(:link, 'Create').click
## debug ##     @driver.execute_script("$('.nav .dropdown-submenu a:contains(Agent)').focus()"); 
## debug ##     @driver.find_element(:link, 'Person').click
## debug ##     @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click
## debug ##     @driver.find_element_with_text('//div[contains(@class, "error")]', /Rules - is required/)
## debug ##     @driver.find_element_with_text('//div[contains(@class, "error")]', /Primary Name - Property is required but was missing/)
## debug ##   end
## debug ## 
## debug ## 
## debug ##   it "reports an error when Authority ID is provided without a Source" do
## debug ##     @driver.clear_and_send_keys([:id, "agent_names__0__authority_id_"], "authid123")
## debug ##     @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click
## debug ##     @driver.find_element_with_text('//div[contains(@class, "error")]', /Source - is required/)
## debug ##   end
## debug ## 
## debug ## 
## debug ##   it "reports an error when Source is provided without an Authority ID" do
## debug ##     @driver.clear_and_send_keys([:id, "agent_names__0__authority_id_"], "")
## debug ##     source_select = @driver.find_element(:id => "agent_names__0__source_")
## debug ## 
## debug ##     source_select.find_elements( :tag_name => "option" ).each do |option|
## debug ##       option.click if option.attribute("value") === "local"
## debug ##     end
## debug ## 
## debug ##     @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click
## debug ## 
## debug ##     @driver.find_element_with_text('//div[contains(@class, "error")]', /Authority ID - is required/)
## debug ##   end
## debug ## 
## debug ## 
## debug ##   it "updates Sort Name when other name fields are updated" do
## debug ##     @driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], ["Hendrix", :tab])
## debug ##     @driver.clear_and_send_keys([:id, "agent_names__0__rest_of_name_"], "woo")
## debug ##     @driver.find_element(:id => "agent_names__0__rest_of_name_").clear
## debug ##     sleep 2
## debug ## 
## debug ##     @driver.find_element(:id => "agent_names__0__sort_name_").attribute("value").should eq("Hendrix")
## debug ##     @driver.clear_and_send_keys([:id, "agent_names__0__rest_of_name_"], ["Johnny Allen", :tab])
## debug ##     @driver.clear_and_send_keys([:id, "agent_names__0__suffix_"], "woo")
## debug ##     @driver.find_element(:id => "agent_names__0__suffix_").clear
## debug ##     sleep 2
## debug ## 
## debug ##     @driver.find_element(:id => "agent_names__0__sort_name_").attribute("value").should eq("Hendrix, Johnny Allen")
## debug ##   end
## debug ## 
## debug ## 
## debug ##   it "changing Direct Order updates Sort Name" do
## debug ##     direct_order_select = @driver.find_element(:id => "agent_names__0__direct_order_")
## debug ##     direct_order_select.find_elements( :tag_name => "option" ).each do |option|
## debug ##       option.click if option.attribute("value") === "inverted"
## debug ##     end
## debug ## 
## debug ##     @driver.find_element(:id => "agent_names__0__sort_name_").attribute("value").should eq("Johnny Allen Hendrix")
## debug ##   end
## debug ## 
## debug ## 
## debug ##   it "can add a secondary name and validations match index of name form" do
## debug ##     @driver.find_element(:css => '#names .subrecord-form-heading .btn').click
## debug ##     @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click
## debug ## 
## debug ##     @driver.find_element_with_text('//div[contains(@class, "error")]', /Rules - is required/)
## debug ##     @driver.find_element_with_text('//div[contains(@class, "error")]', /Primary Name - Property is required but was missing/)
## debug ## 
## debug ##     rules_select = @driver.find_element(:id => "agent_names__1__rules_")
## debug ## 
## debug ##     rules_select.find_elements( :tag_name => "option" ).each do |option|
## debug ##       option.click if option.attribute("value") === "local"
## debug ##     end
## debug ## 
## debug ##     @driver.clear_and_send_keys([:id, "agent_names__1__primary_name_"], "Hendrix")
## debug ##     @driver.clear_and_send_keys([:id, "agent_names__1__rest_of_name_"], "Jimi")
## debug ##   end
## debug ## 
## debug ## 
## debug ##   it "can add a contact to a person" do
## debug ##     @driver.find_element(:css => '#contacts .subrecord-form-heading .btn').click
## debug ##     @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click
## debug ## 
## debug ##     @driver.find_element_with_text('//div[contains(@class, "error")]', /Contact Description - Property is required but was missing/)
## debug ## 
## debug ##     @driver.clear_and_send_keys([:id, "agent_agent_contacts__0__name_"], "Email Address")
## debug ##     @driver.clear_and_send_keys([:id, "agent_agent_contacts__0__email_"], "jimi@rocknrollheaven.com")
## debug ##   end
## debug ## 
## debug ## 
## debug ##   it "can save a person and view readonly view of person" do
## debug ##     @driver.clear_and_send_keys([:id, "agent_names__0__authority_id_"], "authid123")
## debug ##     @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click
## debug ## 
## debug ##     @driver.find_element(:css => '.record-pane h2').text.should eq("Johnny Allen Hendrix Agent")
## debug ##   end
## debug ## 
## debug ## 
## debug ##   it "can present a person edit form" do
## debug ##     @driver.find_element(:link, 'Edit').click
## debug ##     @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').text.should eq("Save Person")
## debug ##   end
## debug ## 
## debug ##   it "can remove contact details" do
## debug ##     @driver.find_element(:css => '#contacts .subrecord-form-remove').click
## debug ##     @driver.find_element(:css => '#contacts .confirm-removal').click
## debug ## 
## debug ##     sleep(1)
## debug ## 
## debug ##     @driver.ensure_no_such_element(:id => "agent_agent_contacts__0__name_")
## debug ## 
## debug ##     @driver.click_and_wait_until_gone(:css => '#archivesSpaceSidebar button.btn-primary')
## debug ## 
## debug ##     @driver.ensure_no_such_element(:css => "#contacts h3")
## debug ##   end
## debug ## 
## debug ## 
## debug ##   it "displays the agent in the agent's index page" do
## debug ##     @driver.find_element(:link, 'Browse Agents').click
## debug ##     expect {
## debug ##       @driver.find_element_with_text('//td', /Johnny Allen Hendrix/)
## debug ##     }.to_not raise_error
## debug ##   end
## debug ## 

  # Accessions

  accession_title = "Exciting new stuff"

  it "gives option to ignore warnings when creating an Accession" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Accession").click
    @driver.clear_and_send_keys([:id, "accession_title_"], accession_title)
    @driver.complete_4part_id("accession_id_%d_")
    @driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    @driver.find_element_with_text('//div[contains(@class, "warning")]', /Content Description - Property was missing/)
    @driver.find_element_with_text('//div[contains(@class, "warning")]', /Condition Description - Property was missing/)

    # Save anyway
    @driver.find_element(:css => "div.alert-warning .btn-warning").click
  end


  it "can create an Accession" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Accession").click
    @driver.clear_and_send_keys([:id, "accession_title_"], accession_title)
    @driver.complete_4part_id("accession_id_%d_")
    @driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
    @driver.clear_and_send_keys([:id, "accession_content_description_"], "A box containing our own universe")
    @driver.clear_and_send_keys([:id, "accession_condition_description_"], "Slightly squashed")
    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    @driver.find_element(:css => '.record-pane h2').text.should eq("#{accession_title} Accession")
  end


  it "can present an Accession edit form" do
    @driver.find_element(:link, 'Edit').click
    @driver.clear_and_send_keys([:id, 'accession_content_description_'], "Here is a description of this accession.")
    @driver.clear_and_send_keys([:id, 'accession_condition_description_'], "Here we note the condition of this accession.")
    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    @driver.find_element(:css => 'body').text.should match(/Here is a description of this accession/)
  end


  it "can edit an Accession but cancel the edit" do
    @driver.find_element(:link, 'Edit').click
    @driver.clear_and_send_keys([:id, 'accession_content_description_'], " moo")
    @driver.find_element(:link, "Cancel").click

    @driver.find_element(:css => 'body').text.should_not match(/Here is a description of this accession. moo/)
  end


  it "can edit an Accession and two Extents" do
    @driver.find_element(:link, 'Edit').click

    # add the first extent
    @driver.find_element(:css => '#accession_extents_ .subrecord-form-heading .btn').click

    @driver.clear_and_send_keys([:id, 'accession_extents__0__number_'], "5")
    event_type_select = @driver.find_element(:id => "accession_extents__0__extent_type_")
    event_type_select.find_elements( :tag_name => "option" ).each do |option|
      option.click if option.attribute("value") === "volumes"
    end

    # add the second extent
    @driver.find_element(:css => '#accession_extents_ .subrecord-form-heading .btn').click
    @driver.clear_and_send_keys([:id, 'accession_extents__1__number_'], "10")

    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    @driver.find_element(:css => '.record-pane h2').text.should eq("#{accession_title} Accession")
  end


  it "can see two extents on the saved Accession" do
    extent_headings = @driver.blocking_find_elements(:css => '#accession_extents_ .accordion-heading')

    extent_headings.length.should eq (2)

    extent_headings[0].text.should eq ("5 Volumes")
    extent_headings[1].text.should eq ("10 Cassettes")
  end


  it "can see remove an extent when editing an Accession" do
    @driver.find_element(:link, 'Edit').click
    @driver.blocking_find_elements(:css => '#accession_extents_ .subrecord-form-remove')[0].click
    @driver.find_element(:css => '#accession_extents_ .confirm-removal').click

    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    extent_headings = @driver.blocking_find_elements(:css => '#accession_extents_ .accordion-heading')
    extent_headings.length.should eq (1)
    extent_headings[0].text.should eq ("10 Cassettes")
  end


  it "can create an Accession with some dates" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Accession").click

    # populate mandatory fields
    @driver.clear_and_send_keys([:id, "accession_title_"], "Accession with dates")

    @driver.complete_4part_id("accession_id_%d_")

    @driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
    @driver.clear_and_send_keys([:id, "accession_content_description_"], "A box containing our own universe")
    @driver.clear_and_send_keys([:id, "accession_condition_description_"], "Slightly squashed")

    # add some dates!
    @driver.find_element(:css => '#accession_dates_ .subrecord-form-heading .btn').click
    @driver.find_element(:css => '#accession_dates_ .subrecord-form-heading .btn').click

    #populate the first date    
    date_label_select = @driver.find_element(:id => "accession_dates__0__label_")
    date_label_select.find_elements( :tag_name => "option" ).each do |option|
      option.click if option.attribute("value") === "digitized"
    end
    @driver.find_element(:css => "#accession_dates__0__date_type__expression").find_element(:xpath => "./parent::*").click
    sleep 2 # wait for dropdown/enabling of inputs
    @driver.clear_and_send_keys([:id, "accession_dates__0__expression_"], "The day before yesterday.")

    #populate the second date    
    date_label_select = @driver.find_element(:id => "accession_dates__1__label_")
    date_label_select.find_elements( :tag_name => "option" ).each do |option|
      option.click if option.attribute("value") === "other"
    end
    @driver.find_element(:css => "#accession_dates__1__date_type__inclusive").find_element(:xpath => "./parent::*").click
    sleep 2 # wait for dropdown/enabling of inputs
    @driver.clear_and_send_keys([:id, "accession_dates__1__begin__inclusive"], "2012-05-14")
    @driver.clear_and_send_keys([:id, "accession_dates__1__end__inclusive"], "2013-05-14")

    # save!
    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    # check dates
    date_headings = @driver.blocking_find_elements(:css => '#accession_dates_ .accordion-heading')
    date_headings.length.should eq (2)    
  end


  it "can delete an existing date when editing an Accession" do
    @driver.find_element(:link, 'Edit').click

    # remove the first date
    @driver.find_element(:css => '#accession_dates_ .subrecord-form-remove').click
    @driver.find_element(:css => '#accession_dates_ .confirm-removal').click

    # save!
    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    # check remaining date
    date_headings = @driver.blocking_find_elements(:css => '#accession_dates_ .accordion-heading')
    date_headings.length.should eq (1)
  end


  it "can create an Accession with some external documents" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Accession").click

    # populate mandatory fields
    @driver.clear_and_send_keys([:id, "accession_title_"], "Accession with external documents")

    @driver.complete_4part_id("accession_id_%d_")

    @driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
    @driver.clear_and_send_keys([:id, "accession_content_description_"], "A box containing our own universe")
    @driver.clear_and_send_keys([:id, "accession_condition_description_"], "Slightly squashed")

    # add some external documents
    @driver.find_element(:css => '#accession_external_documents_ .subrecord-form-heading .btn').click
    @driver.find_element(:css => '#accession_external_documents_ .subrecord-form-heading .btn').click

    #populate the first external documents    
    @driver.clear_and_send_keys([:id, "accession_external_documents__0__title_"], "My URI document")
    @driver.clear_and_send_keys([:id, "accession_external_documents__0__location_"], "http://archivesspace.org")

    #populate the second external documents    
    @driver.clear_and_send_keys([:id, "accession_external_documents__1__title_"], "My other document")
    @driver.clear_and_send_keys([:id, "accession_external_documents__1__location_"], "a/file/path/or/something/")

    # save!
    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    # check external documents
    external_document_sections = @driver.blocking_find_elements(:css => '#accession_external_documents_ .external-document')
    external_document_sections.length.should eq (2)
    external_document_sections[0].find_element(:link => "http://archivesspace.org")
  end


  it "can delete an existing external documents when editing an Accession" do
    @driver.find_element(:link, 'Edit').click

    # remove the first external documents
    @driver.find_element(:css => '#accession_external_documents_ .subrecord-form-remove').click
    @driver.find_element(:css => '#accession_external_documents_ .confirm-removal').click

    # save!
    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    # check remaining external documents
    external_document_sections = @driver.blocking_find_elements(:css => '#accession_external_documents_ .external-document')
    external_document_sections.length.should eq (1)
  end


  it "can create a subject and link to an Accession" do

    @driver.find_element(:link, 'Edit').click

    @driver.find_element(:css, ".linker-wrapper a.btn").click
    @driver.find_element(:css, "a.linker-create-btn").click
    @driver.clear_and_send_keys([:css, "form#new_subject .row-fluid:first-child input"], "AccessionTermABC")
    @driver.find_element(:css, "form#new_subject .row-fluid:first-child .add-term-btn").click
    @driver.clear_and_send_keys([:css, "form#new_subject .row-fluid:last-child input"], "AccessionTermDEF")
    @driver.find_element(:id, "createAndLinkButton").click

    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    @driver.find_element(:css => ".label-and-value .token").text.should eq("AccessionTermABC -- AccessionTermDEF")
  end


  it "can add a rights statement to an Accession" do
    @driver.find_element(:link, 'Edit').click

    # add a rights sub record
    @driver.find_element(:css => '#accession_rights_statements_ .subrecord-form-heading .btn').click

    @driver.clear_and_send_keys([:id, "accession_rights_statements__0__identifier_"],(Digest::MD5.hexdigest("#{Time.now}")))
    ip_status_select = @driver.find_element(:id => "accession_rights_statements__0__ip_status_")
    ip_status_select.find_elements( :tag_name => "option" ).each do |option|
      option.click if option.attribute("value") === "copyrighted"
    end
    @driver.clear_and_send_keys([:id, "accession_rights_statements__0__jurisdiction_"], "AU")
    @driver.find_element(:id, "accession_rights_statements__0__active_").click

    # add an external document
    @driver.find_element(:css => "#accession_rights_statements__0__external_documents_ .subrecord-form-heading .btn").click
    @driver.clear_and_send_keys([:id, "accession_rights_statements__0__external_documents__0__title_"], "Agreement")
    @driver.clear_and_send_keys([:id, "accession_rights_statements__0__external_documents__0__location_"], "http://locationof.agreement.com")

    # save changes
    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    # check the show page
    @driver.find_element(:id, "accession_rights_statements_")
    @driver.find_element(:id, "rights_statement_0")
  end


  # Resources


  it "reports errors and warnings when creating an invalid Resource" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Resource").click
    @driver.find_element(:id, "resource_title_").clear
    @driver.find_element(:css => "form#new_resource button[type='submit']").click

    @driver.find_element_with_text('//div[contains(@class, "error")]', /Identifier - Property is required but was missing/)
    @driver.find_element_with_text('//div[contains(@class, "warning")]', /Title - Property was missing/)
    @driver.find_element_with_text('//div[contains(@class, "warning")]', /Number - Property was missing/)

    @driver.find_element(:css, "a.btn.btn-cancel").click
  end


  resource_title = "Pony Express"

  it "can create a resource" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Resource").click

    @driver.clear_and_send_keys([:id, "resource_title_"],(resource_title))
    @driver.complete_4part_id("resource_id_%d_")
    @driver.clear_and_send_keys([:id, "resource_extents__0__number_"], "10")
    @driver.find_element(:css => "form#new_resource button[type='submit']").click

    # The new Resource shows up on the tree
    @driver.find_element(:css => "a.jstree-clicked").text.strip.should eq(resource_title)
  end


  it "reports errors if adding an empty child to a Resource" do
    @driver.find_element(:link, "Add Child").click
    @driver.find_element(:link, "Analog Object").click

    # False start: create an object without filling it out
    @driver.click_and_wait_until_gone(:id => "createPlusOne")

    @driver.find_element_with_text('//div[contains(@class, "error")]', /Ref ID - Property is required but was missing/)
  end


  # Archival Object Trees

  it "can populate the archival object tree" do
    @driver.clear_and_send_keys([:id, "archival_object_title_"], "Lost mail")
    @driver.clear_and_send_keys([:id, "archival_object_ref_id_"],(Digest::MD5.hexdigest("#{Time.now}")))
    @driver.click_and_wait_until_gone(:id => "createPlusOne")

    ["January", "February", "December"]. each do |month|

      # Wait for the new empty form to be populated.  There's a tricky race
      # condition here that I can't quite track down, so here's my blunt
      # instrument fix.
      @driver.find_element(:xpath, "//input[@value='New Archival Object']")

      @driver.clear_and_send_keys([:id, "archival_object_title_"],(month))
      @driver.clear_and_send_keys([:id, "archival_object_ref_id_"],(Digest::MD5.hexdigest("#{month}#{Time.now}")))

      old_element = @driver.find_element(:id, "archival_object_title_")
      @driver.click_and_wait_until_gone(:id => "createPlusOne")
    end


    elements = @driver.blocking_find_elements(:css => "li.jstree-leaf").map{|li| li.text.strip}

    ["January", "February", "December"].each do |month|
      elements.any? {|elt| elt =~ /#{month}/}.should be_true
    end
  end


  # Archival Objects

  it "can cancel edits to Archival Objects" do
    @driver.clear_and_send_keys([:id, "archival_object_title_"], "unimportant change")
    @driver.find_element(:css, "a[title='December']").click
    @driver.find_element(:id, "dismissChangesButton").click

    # Last added node now selected
    @driver.find_element(:css => "a.jstree-clicked").text.strip.should eq('December')
  end


  it "can add a child to an existing node and assign a Subject" do
    @driver.find_element(:link, "Add Child").click
    @driver.find_element(:link, "Analog Object").click
    @driver.clear_and_send_keys([:id, "archival_object_title_"], "Christmas cards")
    @driver.clear_and_send_keys([:id, "archival_object_ref_id_"],(Digest::MD5.hexdigest("#{Time.now}")))

    @driver.find_element(:css, ".linker-wrapper a.btn").click
    @driver.find_element(:css, "a.linker-create-btn").click
    @driver.clear_and_send_keys([:css, "form#new_subject .row-fluid:first-child input"], "TestTerm123")
    @driver.find_element(:css, "form#new_subject .row-fluid:first-child .add-term-btn").click
    @driver.clear_and_send_keys([:css, "form#new_subject .row-fluid:last-child input"], "FooTerm456")
    @driver.find_element(:id, "createAndLinkButton").click
  end


  it "can remove the linked Subject but find it using typeahead and re-add it" do
    # remove the subject
    @driver.find_element(:css, ".token-input-delete-token").click

    # search for the created subject
    @driver.clear_and_send_keys([:id, "token-input-"], "FooTerm456")
    @driver.find_element(:css, "li.token-input-dropdown-item2").click

    @driver.find_element(:css, "form#new_archival_object button[type='submit']").click

    @driver.wait_for_ajax

    # Verify that the change stuck
    @driver.navigate.refresh

    @driver.find_element(:css, "ul.token-input-list").text.should match(/FooTerm456/)
  end


  # More Resources

  it "shows our newly added Resource in the browse list" do
    @driver.find_element(:link, "Browse").click
    @driver.find_element(:link, "Resources").click
    @driver.find_element_with_text('//td', /#{resource_title}/)
  end


  it "doesn't show the resource in the browse list of a different Repository" do
    ## Change repository
    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link_text => test_repo_code_1).click

    ## Check browse list for Resources
    @driver.find_element(:link, "Browse").click
    @driver.find_element(:link, "Resources").click

    @driver.find_element_with_text('//td', /#{resource_title}/, true, true).should be_nil
  end


  it "can edit a Resource and add another Extent" do
    ## Change back to the populated repository
    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link_text => test_repo_code_2).click

    ## Check browse list for Resources
    @driver.find_element(:link, "Browse").click
    @driver.find_element(:link, "Resources").click

    @driver.find_element(:link, 'View').click
    @driver.find_element(:link, 'Edit').click
    @driver.find_element(:css => '#resource_extents_ .subrecord-form-heading .btn').click

    @driver.clear_and_send_keys([:id, 'resource_extents__1__number_'], "5")
    event_type_select = @driver.find_element(:id => "resource_extents__1__extent_type_")
    event_type_select.find_elements( :tag_name => "option" ).each do |option|
      option.click if option.attribute("value") === "volumes"
    end

    @driver.find_element(:css => "form#new_resource button[type='submit']").click

    @driver.find_element_with_text('//div', /Resource Saved/).should_not be_nil

    @driver.find_element(:link, 'Finish Editing').click
  end


  it "can see two Extents on the saved Resource" do
    extent_headings = @driver.blocking_find_elements(:css => '#resource_extents_ .accordion-heading')

    extent_headings.length.should eq (2)
    extent_headings[0].text.should eq ("10 Cassettes")
    extent_headings[1].text.should eq ("5 Volumes")
  end


  it "can remove an Extent when editing a Resource" do
    @driver.find_element(:link, 'Edit').click

    @driver.blocking_find_elements(:css => '#resource_extents_ .subrecord-form-remove')[1].click
    @driver.find_element(:css => '#resource_extents_ .confirm-removal').click
    @driver.find_element(:css => "form#new_resource button[type='submit']").click

    @driver.find_element(:link, 'Finish Editing').click

    extent_headings = @driver.blocking_find_elements(:css => '#resource_extents_ .accordion-heading')

    extent_headings.length.should eq (1)
    extent_headings[0].text.should eq ("10 Cassettes")
  end


  # Log out

  it "can log out once finished" do
    logout(@driver)
  end

end
