require "net/http"
require "selenium-webdriver"
require "digest"
require "rspec"
require_relative '../../common/test_utils'


$backend_port = 3636
$frontend_port = 3535
$backend = "http://localhost:#{$backend_port}"
$frontend = "http://localhost:#{$frontend_port}"


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

    try = 0
    while self.find_element(*selector).equal? element
      if try < RETRIES
        try += 1
        sleep 0.5
      else
        raise Selenium::WebDriver::Error::NoSuchElementError.new(selector.inspect)
      end
    end
  end


  def complete_4part_id(pattern)
    accession_id = Digest::MD5.hexdigest("#{Time.now}#{$$}").scan(/.{6}/)[0...4]
    accession_id.each_with_index do |elt, i|
      self.find_element(:id => sprintf(pattern, i)).clear_and_send_keys elt
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

end


class Selenium::WebDriver::Element
  def clear_and_send_keys(keys)
    self.clear
    self.send_keys(keys)
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

  TestUtils::kill($backend_pid) if $backend_pid
  TestUtils::kill($frontend_pid) if $frontend_pid
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
    if not @last_example_ok and ENV['SCREENSHOT_ON_ERROR']
      outfile = "/tmp/#{Time.now.to_i}_#{$$}.png"
      puts "Saving screenshot to #{outfile}"
      @driver.save_screenshot(outfile)
    end

    cleanup
  end


  around(:each) do |example|
    begin
      @last_example_ok = false
      example.run
      @last_example_ok = true
    rescue
      cleanup
      raise $!
    end
  end


  ### Examples


  # Users and authentication

  it "fails logins with invalid credentials" do

    @driver.find_element(:link, "Sign In").click
    @driver.find_element(:id, 'user_username').clear_and_send_keys "oopsie"
    @driver.find_element(:id, 'user_password').clear_and_send_keys "daisies"
    @driver.find_element(:id, 'login').click

    @driver.find_element(:css => "p.help-inline.login-message").text.should eq('Login attempt failed')

    @driver.find_element(:link, "Sign In").click

  end


  it "can register a new user" do

    @driver.find_element(:link, "Sign In").click
    @driver.find_element(:link, "Register now").click

    @driver.find_element(:id, "createuser[username]").clear_and_send_keys @user
    @driver.find_element(:id, "createuser[name]").clear_and_send_keys @user
    @driver.find_element(:id, "createuser[password]").clear_and_send_keys "testuser"
    @driver.find_element(:id, "createuser[confirm_password]").clear_and_send_keys "testuser"

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
    @driver.find_element(:id, 'user_username').clear_and_send_keys "admin"
    @driver.find_element(:id, 'user_password').clear_and_send_keys "admin"

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
    @driver.find_element(:id => "repository_description").clear_and_send_keys "missing repo code"
    @driver.find_element(:css => "form#new_repository input[type='submit']").click

    @driver.find_element(:css => "div.alert.alert-error").text.should eq('Repository code - Property is required but was missing')
    @driver.find_element(:css => "div.modal-footer button.btn").click

  end


  it "can create a repository" do

    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link, "Create a Repository").click
    @driver.find_element(:id => "repository_repo_code").clear_and_send_keys test_repo_code_1
    @driver.find_element(:id => "repository_description").clear_and_send_keys test_repo_name_1
    @driver.find_element(:css => "form#new_repository input[type='submit']").click

  end


  it "can create a second repository" do

    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link, "Create a Repository").click
    @driver.find_element(:id => "repository_repo_code").clear_and_send_keys test_repo_code_2
    @driver.find_element(:id => "repository_description").clear_and_send_keys test_repo_name_2
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

    @driver.find_element(:id, 'new-member').clear_and_send_keys(@user)
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

    @driver.find_element(:id, 'new-member').clear_and_send_keys(@user)
    @driver.find_element(:id, 'add-new-member').click
    @driver.find_element(:css => 'input[type="submit"]').click

  end


  it "can log out of the admin account" do

    logout(@driver)

  end


  it "can log in with the user just created" do

    @driver.find_element(:link, "Sign In").click
    @driver.find_element(:id, 'user_username').clear_and_send_keys @user
    @driver.find_element(:id, 'user_password').clear_and_send_keys "testuser"
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

  it "reports errors and warnings when creating an invalid Subject" do
    @driver.find_element(:link => 'Create').click
    @driver.find_element(:link => 'Subject').click

    @driver.find_element(:css => '#external_documents h3 .btn').click

    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click

    # check messages
    @driver.find_element(:css, ".errors-terms_0_term").text.should eq("Term - Property was missing")
  end

  # Person Agents

  it "reports errors and warnings when creating an invalid Person Agent" do

    @driver.find_element(:link, 'Create').click
    @driver.execute_script("$('.nav .dropdown-submenu a:contains(Agent)').focus()"); 
    @driver.find_element(:link, 'Person').click
    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click
    @driver.find_element(:css, ".errors-names_0_rules").text.should eq('Rules - is required')
    @driver.find_element(:css, ".errors-names_0_primary_name").text.should eq('Primary Name - Property is required but was missing')

  end


  it "reports an error when Authority ID is provided without a Source" do

    @driver.find_element(:id => "agent[names][0][authority_id]").clear_and_send_keys "authid123"
    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click
    @driver.find_element(:css, ".errors-names_0_source").text.should eq('Source - is required')

  end


  it "reports an error when Source is provided without an Authority ID" do

    @driver.find_element(:id => "agent[names][0][authority_id]").clear_and_send_keys ""
    source_select = @driver.find_element(:id => "agent[names][0][source]")

    source_select.find_elements( :tag_name => "option" ).each do |option|
      option.click if option.attribute("value") === "local"
    end

    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click

    @driver.find_element(:css, ".errors-names_0_authority_id").text.should eq('Authority ID - is required')

  end


  it "updates Sort Name when other name fields are updated" do

    @driver.find_element(:id => "agent[names][0][primary_name]").clear_and_send_keys ["Hendrix", :tab]
    @driver.find_element(:id => "agent[names][0][rest_of_name]").clear_and_send_keys "woo"
    @driver.find_element(:id => "agent[names][0][rest_of_name]").clear
    sleep 2

    @driver.find_element(:id => "agent[names][0][sort_name]").attribute("value").should eq("Hendrix")
    @driver.find_element(:id => "agent[names][0][rest_of_name]").clear_and_send_keys ["Johnny Allen", :tab]
    @driver.find_element(:id => "agent[names][0][suffix]").clear_and_send_keys "woo"
    @driver.find_element(:id => "agent[names][0][suffix]").clear
    sleep 2

    @driver.find_element(:id => "agent[names][0][sort_name]").attribute("value").should eq("Hendrix, Johnny Allen")

  end


  it "changing Direct Order updates Sort Name" do

    direct_order_select = @driver.find_element(:id => "agent[names][0][direct_order]")
    direct_order_select.find_elements( :tag_name => "option" ).each do |option|
      option.click if option.attribute("value") === "inverted"
    end

    @driver.find_element(:id => "agent[names][0][sort_name]").attribute("value").should eq("Johnny Allen Hendrix")

  end


  it "can add a secondary name and validations match index of name form" do

    @driver.find_element(:css => '#secondary_names h3 .btn').click
    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click

    @driver.find_element(:css, ".errors-names_1_rules").text.should eq('Rules - is required')
    @driver.find_element(:css, ".errors-names_1_primary_name").text.should eq('Primary Name - Property is required but was missing')

    rules_select = @driver.find_element(:id => "agent[names][1][rules]")

    rules_select.find_elements( :tag_name => "option" ).each do |option|
      option.click if option.attribute("value") === "local"
    end

    @driver.find_element(:id => "agent[names][1][primary_name]").clear_and_send_keys "Hendrix"
    @driver.find_element(:id => "agent[names][1][rest_of_name]").clear_and_send_keys "Jimi"

  end


  it "can add a contact to a person" do

    @driver.find_element(:css => '#contacts h3 .btn').click
    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click

    @driver.find_element(:css, ".errors-agent_contacts_0_name").text.should eq('Contact Description - Property is required but was missing')

    @driver.find_element(:id => "agent[agent_contacts][0][name]").clear_and_send_keys "Email Address"
    @driver.find_element(:id => "agent[agent_contacts][0][email]").clear_and_send_keys "jimi@rocknrollheaven.com"

  end


  it "can save a person and view readonly view of person" do

    @driver.find_element(:id => "agent[names][0][authority_id]").clear_and_send_keys "authid123"
    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click

    @driver.find_element(:css => '.record-pane h2').text.should eq("Johnny Allen Hendrix Agent")

  end


  it "can present a person edit form" do

    @driver.find_element(:link, 'Edit').click
    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').text.should eq("Save Person")

  end

  it "can remove contact details" do

    @driver.find_element(:css => '#contacts .subform-remove').click
    @driver.find_element(:css => '#contacts .confirm-removal').click

    @driver.ensure_no_such_element(:id => "agent[agent_contacts][0][name]")

    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click

    @driver.ensure_no_such_element(:css => "#contacts h3")

  end


  it "displays the agent in the agent's index page" do

    @driver.find_element(:link, 'Browse Agents').click
    expect {
      @driver.find_element_with_text('//td', /Johnny Allen Hendrix/)
    }.to_not raise_error

  end


  # Accessions

  it "gives option to ignore warnings when creating an Accession" do

    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Accession").click
    @driver.find_element(:id => "accession[title]").clear_and_send_keys "Accession title"
    @driver.complete_4part_id("accession[id_%d]")
    @driver.find_element(:id => "accession[accession_date]").clear_and_send_keys "2012-01-01"
    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    @driver.find_element(:css => ".errors-content_description").text.should eq("Content Description - Property was missing")
    @driver.find_element(:css => ".errors-condition_description").text.should eq("Condition Description - Property was missing")

    # Save anyway
    @driver.find_element(:css => "div.alert-warning .btn-warning").click

  end


  it "can create an Accession" do

    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Accession").click
    @driver.find_element(:id => "accession[title]").clear_and_send_keys "Accession title"
    @driver.complete_4part_id("accession[id_%d]")
    @driver.find_element(:id => "accession[accession_date]").clear_and_send_keys "2012-01-01"
    @driver.find_element(:id => "accession[content_description]").clear_and_send_keys "A box containing our own universe"
    @driver.find_element(:id => "accession[condition_description]").clear_and_send_keys "Slightly squashed"
    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    @driver.find_element(:css => '.record-pane h2').text.should eq("Accession title Accession")

  end


  it "can present an Accession edit form" do

    @driver.find_element(:link, 'Edit').click
    @driver.find_element(:id => 'accession[content_description]').clear_and_send_keys "Here is a description of this accession."
    @driver.find_element(:id => 'accession[condition_description]').clear_and_send_keys "Here we note the condition of this accession."
    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    @driver.find_element(:css => 'body').text.should match(/Here is a description of this accession/)

  end


  it "can edit an Accession but cancel the edit" do

    @driver.find_element(:link, 'Edit').click
    @driver.find_element(:id => 'accession[content_description]').clear_and_send_keys " moo"
    @driver.find_element(:link, "Cancel").click

    @driver.find_element(:css => 'body').text.should_not match(/Here is a description of this accession. moo/)

  end


  it "can edit an Accession and two Extents" do

    @driver.find_element(:link, 'Edit').click

    # add the first extent
    @driver.find_element(:css => '#extent h3 .btn').click

    @driver.find_element(:id => 'accession[extents][0][number]').clear_and_send_keys "5"
    event_type_select = @driver.find_element(:id => "accession[extents][0][extent_type]")
    event_type_select.find_elements( :tag_name => "option" ).each do |option|
      option.click if option.attribute("value") === "volumes"
    end

    # add the second extent
    @driver.find_element(:css => '#extent h3 .btn').click
    @driver.find_element(:id => 'accession[extents][1][number]').clear_and_send_keys "10"

    @driver.find_element(:css => "form#accession_form button[type='submit']").click
  end


  it "can see two extents on the saved Accession" do

    extent_headings = @driver.blocking_find_elements(:css => '#extent .accordion-heading')
    extent_headings.length.should eq (2)

    extent_headings[0].text.should eq ("5 Volumes")
    extent_headings[1].text.should eq ("10 Cassettes")

  end


  it "can see remove an extent when editing an Accession" do

    @driver.find_element(:link, 'Edit').click
    @driver.find_element(:css => '#extent .subform-remove').click
    @driver.find_element(:css => '#extent .confirm-removal').click

    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    extent_headings = @driver.blocking_find_elements(:css => '#extent .accordion-heading')
    extent_headings.length.should eq (1)
    extent_headings[0].text.should eq ("10 Cassettes")

  end


  it "can create an Accession with some dates" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Accession").click

    # populate mandatory fields
    @driver.find_element(:id => "accession[title]").clear_and_send_keys "Accession with dates"

    @driver.complete_4part_id("accession[id_%d]")

    @driver.find_element(:id => "accession[accession_date]").clear_and_send_keys "2012-01-01"
    @driver.find_element(:id => "accession[content_description]").clear_and_send_keys "A box containing our own universe"
    @driver.find_element(:id => "accession[condition_description]").clear_and_send_keys "Slightly squashed"

    # add some dates!
    @driver.find_element(:css => '#dates h3 .btn').click
    @driver.find_element(:css => '#dates h3 .btn').click

    #populate the first date    
    date_label_select = @driver.find_element(:id => "accession[dates][0][label]")
    date_label_select.find_elements( :tag_name => "option" ).each do |option|
      option.click if option.attribute("value") === "digitized"
    end
    @driver.find_element(:css => "#date_type_0 label[href='#date_type_expression_0']").click
    sleep 2 # wait for dropdown/enabling of inputs
    @driver.find_element(:id => "accession[dates][0][expression]").clear_and_send_keys "The day before yesterday."

    #populate the second date    
    date_label_select = @driver.find_element(:id => "accession[dates][1][label]")
    date_label_select.find_elements( :tag_name => "option" ).each do |option|
      option.click if option.attribute("value") === "other"
    end
    @driver.find_element(:css => "#date_type_1 label[href='#date_type_inclusive_1']").click
    sleep 2 # wait for dropdown/enabling of inputs
    @driver.find_element(:id => "accession[dates][1][begin]_inclusive").clear_and_send_keys "2012-05-14"
    @driver.find_element(:id => "accession[dates][1][end]_inclusive").clear_and_send_keys "2013-05-14"

    # save!
    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    # check dates
    date_headings = @driver.blocking_find_elements(:css => '#dates .accordion-heading')
    date_headings.length.should eq (2)    
  end


  it "can delete an existing date when editing an Accession" do

    @driver.find_element(:link, 'Edit').click

    # remove the first date
    @driver.find_element(:css => '#dates .subform-remove').click
    @driver.find_element(:css => '#dates .confirm-removal').click

    # save!
    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    # check remaining date
    date_headings = @driver.blocking_find_elements(:css => '#dates .accordion-heading')
    date_headings.length.should eq (1)

  end


  it "Can create an Accession with some external documents" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Accession").click

    # populate mandatory fields
    @driver.find_element(:id => "accession[title]").clear_and_send_keys "Accession with external documents"

    @driver.complete_4part_id("accession[id_%d]")

    @driver.find_element(:id => "accession[accession_date]").clear_and_send_keys "2012-01-01"
    @driver.find_element(:id => "accession[content_description]").clear_and_send_keys "A box containing our own universe"
    @driver.find_element(:id => "accession[condition_description]").clear_and_send_keys "Slightly squashed"

    # add some external documents
    @driver.find_element(:css => '#external_documents h3 .btn').click
    @driver.find_element(:css => '#external_documents h3 .btn').click

    #populate the first external documents    
    @driver.find_element(:id => "accession[external_documents][0][title]").clear_and_send_keys "My URI document"
    @driver.find_element(:id => "accession[external_documents][0][location]").clear_and_send_keys "http://archivesspace.org"

    #populate the second external documents    
    @driver.find_element(:id => "accession[external_documents][1][title]").clear_and_send_keys "My other document"
    @driver.find_element(:id => "accession[external_documents][1][location]").clear_and_send_keys "a/file/path/or/something/"

    # save!
    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    # check external documents
    external_document_sections = @driver.blocking_find_elements(:css => '#external_documents .external-document')
    external_document_sections.length.should eq (2)
    external_document_sections[0].find_element(:link => "http://archivesspace.org")
  end


  it "can delete an existing external documents when editing an Accession" do

    @driver.find_element(:link, 'Edit').click

    # remove the first external documents
    @driver.find_element(:css => '#external_documents .subform-remove').click
    @driver.find_element(:css => '#external_documents .confirm-removal').click

    # save!
    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    # check remaining external documents
    external_document_sections = @driver.blocking_find_elements(:css => '#external_documents .external-document')
    external_document_sections.length.should eq (1)

  end


  # Resources


  it "reports errors and warnings when creating an invalid Resource" do

    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Resource").click
    @driver.find_element(:id, "resource[title]").clear
    @driver.find_element(:css => "form#new_resource button[type='submit']").click

    @driver.find_element(:css, "div.alert.alert-error").text.should eq('Identifier - Property is required but was missing')
    @driver.find_element(:css, "div.alert.alert-warning .errors-title").text.should eq('Title - Property was missing')
    @driver.find_element(:css, "div.alert.alert-warning .errors-extents_0_number").text.should eq("Number - Property was missing")

    @driver.find_element(:css, "a.btn.btn-cancel").click

  end


  resource_title = "Pony Express"

  it "can create a resource" do

    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Resource").click

    @driver.find_element(:id, "resource[title]").clear_and_send_keys(resource_title)
    @driver.complete_4part_id("resource[id_%d]")
    @driver.find_element(:id => "resource[extents][0][number]").clear_and_send_keys("10")
    @driver.find_element(:css => "form#new_resource button[type='submit']").click

    # The new Resource shows up on the tree
    @driver.find_element(:css => "a.jstree-clicked").text.strip.should eq(resource_title)

  end


  it "reports errors if adding an empty child to a Resource" do

    @driver.find_element(:link, "Add Child").click
    @driver.find_element(:link, "Analog Object").click

    # False start: create an object without filling it out
    @driver.click_and_wait_until_gone(:id => "createPlusOne")

    @driver.find_element(:css, "div.alert.alert-error").text.should eq('Ref ID - Property is required but was missing')

  end


  # Archival Object Trees

  it "can populate the archival object tree" do

    @driver.find_element(:id, "archival_object[title]").clear_and_send_keys("Lost mail")
    @driver.find_element(:id, "archival_object[ref_id]").clear_and_send_keys(Digest::MD5.hexdigest("#{Time.now}"))
    @driver.click_and_wait_until_gone(:id => "createPlusOne")

    ["January", "February", "December"]. each do |month|
      @driver.find_element(:id, "archival_object[title]").clear_and_send_keys(month)
      @driver.find_element(:id, "archival_object[ref_id]").clear_and_send_keys(Digest::MD5.hexdigest("#{month}#{Time.now}"))

      old_element = @driver.find_element(:id, "archival_object[title]")
      @driver.click_and_wait_until_gone(:id => "createPlusOne")
    end


    elements = @driver.blocking_find_elements(:css => "li.jstree-leaf").map{|li| li.text.strip}

    ["January", "February", "December"].each do |month|
      elements.any? {|elt| elt =~ /#{month}/}.should be_true
    end

  end


  # Archival Objects

  it "can cancel edits to Archival Objects" do

    @driver.find_element(:id, "archival_object[title]").clear_and_send_keys("unimportant change")
    @driver.find_element(:css, "a[title='December']").click
    @driver.find_element(:id, "dismissChangesButton").click

    # Last added node now selected
    @driver.find_element(:css => "a.jstree-clicked").text.strip.should eq('December')

  end


  it "can add a child to an existing node and assign a Subject" do

    @driver.find_element(:link, "Add Child").click
    @driver.find_element(:link, "Analog Object").click
    @driver.find_element(:id, "archival_object[title]").clear_and_send_keys("Christmas cards")
    @driver.find_element(:id, "archival_object[ref_id]").clear_and_send_keys(Digest::MD5.hexdigest("#{Time.now}"))

    @driver.find_element(:css, ".linker-wrapper a.btn").click
    @driver.find_element(:css, "a.linker-create-btn").click
    @driver.find_element(:css, "form#new_subject .row-fluid:first-child input").clear_and_send_keys("TestTerm123")
    @driver.find_element(:css, "form#new_subject .row-fluid:first-child .add-term-btn").click
    @driver.find_element(:css, "form#new_subject .row-fluid:last-child input").clear_and_send_keys("FooTerm456")
    @driver.find_element(:id, "createAndLinkButton").click

  end


  it "can remove the linked Subject but find it using typeahead and re-add it" do

    # remove the subject
    @driver.find_element(:css, ".token-input-delete-token").click

    # search for the created subject
    @driver.find_element(:id, "token-input-").clear_and_send_keys("Foo")
    @driver.find_element(:css, "li.token-input-dropdown-item2").click

    @driver.click_and_wait_until_gone(:css, "form#new_archival_object button[type='submit']")

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


  # Log out

  it "can log out once finished" do

    logout(@driver)

  end

end
