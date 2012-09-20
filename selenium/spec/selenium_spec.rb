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
    accession_id = Digest::MD5.hexdigest("#{Time.now}").scan(/.{6}/)[0...4]
    accession_id.each_with_index do |elt, i|
      self.find_element(:id => sprintf(pattern, i)).clear_and_send_keys elt
    end
  end


  def find_element_with_text(xpath, pattern, noError = false)
    RETRIES.times do

      matches = self.find_elements(:xpath => xpath)
      matches.each do | match |
        return match if match.text =~ pattern
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

    @user = "testuser#{Time.now.to_i}"
    @driver = Selenium::WebDriver.for :firefox
    @driver.navigate.to $frontend
  end


  # Stop selenium, kill the dev servers
  after(:all) do
    cleanup
  end


  around(:each) do |example|
    begin
      example.run
    rescue
      cleanup
      raise $!
    end
  end


  it "Fails logins with invalid credentials" do
    @driver.find_element(:link, "Sign In").click
    @driver.find_element(:id, 'user_username').clear_and_send_keys "oopsie"
    @driver.find_element(:id, 'user_password').clear_and_send_keys "daisies"

    @driver.find_element(:id, 'login').click

    @driver.find_element(:css => "p.help-inline.login-message").text.should eq('Login attempt failed')

    @driver.find_element(:link, "Sign In").click
  end


  it "Successfully creates a user" do
    @driver.find_element(:link, "Sign In").click
    @driver.find_element(:link, "Register now").click

    @driver.find_element(:id, "createuser[username]").clear_and_send_keys @user
    @driver.find_element(:id, "createuser[name]").clear_and_send_keys @user
    @driver.find_element(:id, "createuser[password]").clear_and_send_keys "testuser"
    @driver.find_element(:id, "createuser[confirm_password]").clear_and_send_keys "testuser"

    @driver.find_element(:id, 'create_account').click

    @driver.find_element(:css => "span.user-label").text.should match(/#{@user}/)
  end


  it "Can log out" do
    logout(@driver)
  end


  it "Can log in with the user just created" do
    @driver.find_element(:link, "Sign In").click
    @driver.find_element(:id, 'user_username').clear_and_send_keys @user
    @driver.find_element(:id, 'user_password').clear_and_send_keys "testuser"

    @driver.find_element(:id, 'login').click
  end


  it "Flags errors when creating a repository with missing fields" do
    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link, "Create a Repository").click
    @driver.find_element(:id => "repository_description").clear_and_send_keys "missing repo code"
    @driver.find_element(:css => "form#new_repository input[type='submit']").click

    @driver.find_element(:css => "div.alert.alert-error").text.should eq('Repository code - Property is required but was missing')
    @driver.find_element(:css => "div.modal-footer button.btn").click
  end


  test_repo_code_1 = "test1#{Time.now.to_i}"
  test_repo_name_1 = "test repository 1 - #{Time.now}"
  test_repo_code_2 = "test2#{Time.now.to_i}"
  test_repo_name_2 = "test repository 2 - #{Time.now}"

  it "Can create a repository" do
    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link, "Create a Repository").click
    @driver.find_element(:id => "repository_repo_code").clear_and_send_keys test_repo_code_1
    @driver.find_element(:id => "repository_description").clear_and_send_keys test_repo_name_1
    @driver.find_element(:css => "form#new_repository input[type='submit']").click
  end


  it "Can create and select a second repository" do
    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link, "Create a Repository").click
    @driver.find_element(:id => "repository_repo_code").clear_and_send_keys test_repo_code_2
    @driver.find_element(:id => "repository_description").clear_and_send_keys test_repo_name_2
    @driver.find_element(:css => "form#new_repository input[type='submit']").click

    ## Select the second repository
    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link_text => test_repo_code_2).click
  end


  it "Notifies of errors and warnings when creating an invalid Person Agent" do
    @driver.find_element(:link, 'Create').click
    @driver.execute_script("$('.nav .dropdown-submenu a:contains(Agent)').focus()"); 
    @driver.find_element(:link, 'Person').click

    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click
    @driver.find_element(:css, ".errors-names_0_rules").text.should eq('Rules - is required')
    @driver.find_element(:css, ".errors-names_0_primary_name").text.should eq('Primary Name - Property is required but was missing')
  end


  it "Notifies error when Authority ID is provided without a Source" do
    @driver.find_element(:id => "agent[names][0][authority_id]").clear_and_send_keys "authid123"
    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click
    @driver.find_element(:css, ".errors-names_0_source").text.should eq('Source - is required')
  end

  it "Notifies error when Source is provided without an Authority ID" do
    @driver.find_element(:id => "agent[names][0][authority_id]").clear_and_send_keys ""

    source_select = @driver.find_element(:id => "agent[names][0][source]")
    source_select.find_elements( :tag_name => "option" ).each do |option|
      option.click if option.attribute("value") === "local"
    end

    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click
    @driver.find_element(:css, ".errors-names_0_authority_id").text.should eq('Authority ID - is required')
  end

  it "Sort name updates when other name fields are updated" do
    @driver.find_element(:id => "agent[names][0][primary_name]").clear_and_send_keys ["Hendrix", :tab]

    @driver.find_element(:id => "agent[names][0][sort_name]").attribute("value").should eq("Hendrix")

    @driver.find_element(:id => "agent[names][0][rest_of_name]").clear_and_send_keys ["Johnny Allen", :tab]

    @driver.find_element(:id => "agent[names][0][sort_name]").attribute("value").should eq("Hendrix, Johnny Allen")
  end

  it "Changing Direct Order update Sort Name" do
    direct_order_select = @driver.find_element(:id => "agent[names][0][direct_order]")
    direct_order_select.find_elements( :tag_name => "option" ).each do |option|
      option.click if option.attribute("value") === "inverted"
    end

    @driver.find_element(:id => "agent[names][0][sort_name]").attribute("value").should eq("Johnny Allen Hendrix")
  end

  it "Can add a secondary name and validations match index of name form" do
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

  it "Can add a contact to a person" do
    @driver.find_element(:css => '#contacts h3 .btn').click

    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click

    @driver.find_element(:css, ".errors-agent_contacts_0_name").text.should eq('Contact Description - Property is required but was missing')

    @driver.find_element(:id => "agent[agent_contacts][0][name]").clear_and_send_keys "Email Address"
    @driver.find_element(:id => "agent[agent_contacts][0][email]").clear_and_send_keys "jimi@rocknrollheaven.com"
  end

  it "Can save a person and view readonly view of person" do
    @driver.find_element(:id => "agent[names][0][authority_id]").clear_and_send_keys "authid123"
    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click

    @driver.find_element(:css => '.record-pane h2').text.should eq("Johnny Allen Hendrix Agent")
  end

  it "Allows edit of a person" do
    @driver.find_element(:link, 'Edit').click
  end

  it "Allows removal of the contact details" do
    @driver.find_element(:css => '#contacts .subform-remove').click
    expect {
      @driver.find_element(:id => "agent[agent_contacts][0][name]")
    }.to raise_error

    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click

    expect {
      @driver.find_element(:css => "#contacts h3")
    }.to raise_error
  end

  it "displays the agent in the agent's index page" do
    @driver.find_element(:link, 'Browse Agents').click
    @driver.find_element_with_text('//td', /Johnny Allen Hendrix/)
  end


  it "Can opt to ignore warnings when creating an accession" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Accession").click

    @driver.find_element(:id => "accession[title]").clear_and_send_keys "Accession title"

    @driver.complete_4part_id("accession[id_%d]")
    @driver.find_element(:id => "accession[accession_date]").clear_and_send_keys "2012-01-01"
    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    @driver.find_element(:css => ".errors-content_description").text.should eq("Content Description - Property was missing")
    @driver.find_element(:css => ".errors-condition_description").text.should eq("Condition Description - Property was missing")
    @driver.find_element(:css => ".errors-extents_0_number").text.should eq("Number - Property was missing")

    # Save anyway
    @driver.find_element(:css => "div.alert-warning .btn-warning").click
  end


  it "Can successfully create an accession" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Accession").click

    @driver.find_element(:id => "accession[title]").clear_and_send_keys "Accession title"

    @driver.complete_4part_id("accession[id_%d]")

    @driver.find_element(:id => "accession[accession_date]").clear_and_send_keys "2012-01-01"
    @driver.find_element(:id => "accession[content_description]").clear_and_send_keys "A box containing our own universe"
    @driver.find_element(:id => "accession[condition_description]").clear_and_send_keys "Slightly squashed"

    @driver.find_element(:id => "accession[extents][0][number]").clear_and_send_keys "10"

    @driver.find_element(:css => "form#accession_form button[type='submit']").click
  end


  it "Can edit an accession once created" do
    @driver.find_element(:link, 'Edit').click

    @driver.find_element(:id => 'accession[content_description]').clear_and_send_keys "Here is a description of this accession."
    @driver.find_element(:id => 'accession[condition_description]').clear_and_send_keys "Here we note the condition of this accession."

    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    @driver.find_element(:css => 'body').text.should match(/Here is a description of this accession/)
  end


  it "Can edit an accession but cancel the edit" do
    @driver.find_element(:link, 'Edit').click
    @driver.find_element(:id => 'accession[content_description]').clear_and_send_keys " moo"
    @driver.find_element(:link, "Cancel").click

    @driver.find_element(:css => 'body').text.should_not match(/Here is a description of this accession. moo/)
  end


  it "Can edit an accession and add another Extent" do
    @driver.find_element(:link, 'Edit').click
    @driver.find_element(:css => '#extent h3 .btn').click

    @driver.find_element(:id => 'accession[extents][1][number]').clear_and_send_keys "5"
    event_type_select = @driver.find_element(:id => "accession[extents][1][extent_type]")
    event_type_select.find_elements( :tag_name => "option" ).each do |option|
      option.click if option.attribute("value") === "volumes"
    end

    @driver.find_element(:css => "form#accession_form button[type='submit']").click
  end


  it "Can see two extents on the saved Accession" do
    extent_headings = @driver.find_elements(:css => '#extent .accordion-heading')
    extent_headings.length.should eq (2)
    extent_headings[0].text.should eq ("10 Cassettes")
    extent_headings[1].text.should eq ("5 Volumes")
  end


  it "Can see remove an extent when editing an Accession" do
    @driver.find_element(:link, 'Edit').click

    @driver.find_element(:css => '#extent .subform-remove').click

    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    extent_headings = @driver.find_elements(:css => '#extent .accordion-heading')
    
    extent_headings.length.should eq (1)
    extent_headings[0].text.should eq ("10 Cassettes")
  end


  it "Notifies of errors and warnings when creating an invalid resource" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Resource").click

    @driver.find_element(:id, "resource[title]").clear

    @driver.find_element(:css => "form#new_resource button[type='submit']").click

    @driver.find_element(:css, "div.alert.alert-error").text.should eq('Identifier - Property is required but was missing')
    @driver.find_element(:css, "div.alert.alert-warning .errors-title").text.should eq('Title - Property was missing')

    @driver.find_element(:css, "a.btn.btn-cancel").click
  end


  resource_title = "Pony Express"

  it "Can successfully create a resource" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Resource").click

    @driver.find_element(:id, "resource[title]").clear_and_send_keys(resource_title)
    @driver.find_element(:id, "resource[extents][0][number]").clear_and_send_keys("5")
    @driver.complete_4part_id("resource[id_%d]")
    @driver.find_element(:css => "form#new_resource button[type='submit']").click

    # The new resource shows up on the tree to the left
    @driver.find_element(:css => "a.jstree-clicked").text.strip.should eq(resource_title)
  end


  it "Gets errors if adding an empty child to a resource" do
    @driver.find_element(:link, "Add Child").click
    @driver.find_element(:link, "Analog Object").click

    # False start: create an object without filling it out
    @driver.click_and_wait_until_gone(:id => "createPlusOne")
    @driver.find_element(:css, "div.alert.alert-error").text.should eq('Ref ID - Property is required but was missing')
  end


  it "Can populate the archival object tree" do
    @driver.find_element(:id, "archival_object[title]").clear_and_send_keys("Lost mail")
    @driver.find_element(:id, "archival_object[ref_id]").clear_and_send_keys(Digest::MD5.hexdigest("#{Time.now}"))
    @driver.find_element(:id, "archival_object[extents][0][number]").clear_and_send_keys("10")
    @driver.click_and_wait_until_gone(:id => "createPlusOne")

    ["January", "February", "December"]. each do |month|

      @driver.find_element(:id, "archival_object[title]").clear_and_send_keys(month)
      @driver.find_element(:id, "archival_object[ref_id]").clear_and_send_keys(Digest::MD5.hexdigest("#{month}#{Time.now}"))
      @driver.find_element(:id, "archival_object[extents][0][number]").clear_and_send_keys("10")

      old_element = @driver.find_element(:id, "archival_object[title]")
      @driver.click_and_wait_until_gone(:id => "createPlusOne")
    end
  end


  it "Can cancel edits to archival object records" do
    @driver.find_element(:id, "archival_object[title]").clear_and_send_keys("unimportant change")
    @driver.find_element(:css, "a[title='December']").click
    @driver.find_element(:id, "dismissChangesButton").click

    # Last added node now selected
    @driver.find_element(:css => "a.jstree-clicked").text.strip.should eq('December')
  end


  it "Can add a child to an existing node and assign a subject" do
    @driver.find_element(:link, "Add Child").click
    @driver.find_element(:link, "Analog Object").click
    @driver.find_element(:id, "archival_object[title]").clear_and_send_keys("Christmas cards")
    @driver.find_element(:id, "archival_object[ref_id]").clear_and_send_keys(Digest::MD5.hexdigest("#{Time.now}"))
    @driver.find_element(:id, "archival_object[extents][0][number]").clear_and_send_keys("10")

    @driver.find_element(:css, ".linker-wrapper a.btn").click
    @driver.find_element(:css, "a.linker-create-btn").click
    @driver.find_element(:css, "form#new_subject .row-fluid:first-child input").clear_and_send_keys("TestTerm123")
    @driver.find_element(:css, "form#new_subject .row-fluid:first-child .add-term-btn").click
    @driver.find_element(:css, "form#new_subject .row-fluid:last-child input").clear_and_send_keys("FooTerm456")
    @driver.find_element(:id, "createAndLinkButton").click
  end


  it "Can remove the linked subject but find it using typeahead and re-add it" do
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


  it "Can see our newly added resource in the browse list" do
    @driver.find_element(:link, "Browse").click
    @driver.find_element(:link, "Resources").click
    @driver.find_element_with_text('//td', /#{resource_title}/)
  end

  it "Can't see the resource in the browse list of a different repository" do
    ## Change repository
    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link_text => test_repo_code_1).click

    ## Check browse list for resources
    @driver.find_element(:link, "Browse").click
    @driver.find_element(:link, "Resources").click
    if @driver.find_element_with_text('//td', /#{resource_title}/, true) != nil
      puts "ERROR: #{resource_title} should not exist in resource Browse list!"
    end
  end

  it "Can log out once finished" do
    logout(@driver)
  end
end
