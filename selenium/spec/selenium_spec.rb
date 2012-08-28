require "net/http"
require "selenium-webdriver"
require "digest"
require "rspec"
require_relative '../../common/test_utils'


$backend_port = 3636
$frontend_port = 3535
$backend = "http://localhost:#{$backend_port}"
$frontend = "http://localhost:#{$frontend_port}"


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
        return find_element_orig(*selectors)
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
      self.find_element(:id => sprintf(pattern, i)).send_keys elt
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



def logout(driver)
   ## Complete the logout process
   driver.find_element(:css, '.user-container .btn').click
   driver.find_element(:link, "Logout").click
   driver.find_element(:link, "Sign In")
end


RSpec.configure do |c|
  c.fail_fast = true
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
      @backend = TestUtils::start_backend($backend_port)
      @frontend = TestUtils::start_frontend($frontend_port, $backend)
    end

    while true
      begin
        Net::HTTP.get(URI($frontend))
        break
      rescue
        # Keep trying
        puts "Waiting for frontend (#{$!.inspect})"
        sleep(5)
      end
    end

    TestUtils::wait_for_url(URI($frontend))
    TestUtils::wait_for_url(URI($backend))

    @user = "testuser#{Time.now.to_i}"
    @driver = Selenium::WebDriver.for :firefox
    @driver.navigate.to $frontend
  end


  # Stop selenium, kill the dev servers
  after(:all) do
    @driver.quit

    TestUtils::kill(@backend) if @backend
    TestUtils::kill(@frontend) if @frontend
  end


  it "Fails logins with invalid credentials" do
    @driver.find_element(:link, "Sign In").click
    @driver.find_element(:id, 'user_username').send_keys "oopsie"
    @driver.find_element(:id, 'user_password').send_keys "daisies"

    @driver.find_element(:id, 'login').click

    @driver.find_element(:css => "p.help-inline.login-message").text.should eq('Login attempt failed')

    @driver.find_element(:link, "Sign In").click
  end


  it "Successfully creates a user" do
    @driver.find_element(:link, "Sign In").click
    @driver.find_element(:link, "Register now").click

    @driver.find_element(:id, "createuser_username").send_keys @user
    @driver.find_element(:id, "createuser_name").send_keys @user
    @driver.find_element(:id, "createuser_password").send_keys "testuser"
    @driver.find_element(:id, "createuser_confirm_password").send_keys "testuser"

    @driver.find_element(:id, 'create_account').click

    @driver.find_element(:css => "span.user-label").text.should match(/#{@user}/)
  end


  it "Can log out" do
    logout(@driver)
  end


  it "Can log in with the user just created" do
    @driver.find_element(:link, "Sign In").click
    @driver.find_element(:id, 'user_username').send_keys @user
    @driver.find_element(:id, 'user_password').send_keys "testuser"

    @driver.find_element(:id, 'login').click
  end


  it "Flags errors when creating a repository with missing fields" do
    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link, "Create a Repository").click
    @driver.find_element(:id => "repository_description").send_keys "missing repo code"
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
    @driver.find_element(:id => "repository_repo_code").send_keys test_repo_code_1
    @driver.find_element(:id => "repository_description").send_keys test_repo_name_1
    @driver.find_element(:css => "form#new_repository input[type='submit']").click
  end


  it "Can create and select a second repository" do
    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link, "Create a Repository").click
    @driver.find_element(:id => "repository_repo_code").send_keys test_repo_code_2
    @driver.find_element(:id => "repository_description").send_keys test_repo_name_2
    @driver.find_element(:css => "form#new_repository input[type='submit']").click

    ## Select the second repository
    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link_text => test_repo_code_2).click
  end


  it "Can opt to ignore warnings when creating an accession" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Accession").click

    @driver.find_element(:id => "accession_title").send_keys "Accession title"

    @driver.complete_4part_id("accession_id_%d")
    @driver.find_element(:id => "accession_accession_date").send_keys "2012-01-01"
    @driver.find_element(:css => "form#new_accession button[type='submit']").click

    @driver.find_element(:css => "div.alert-warning").text.should eq("Content Description - Property was missing\nCondition Description - Property was missing")

    # Save anyway
    @driver.find_element(:css => "div.alert-warning .btn-warning").click
  end


  it "Can successfully create an accession" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Accession").click

    @driver.find_element(:id => "accession_title").send_keys "Accession title"

    @driver.complete_4part_id("accession_id_%d")

    @driver.find_element(:id => "accession_accession_date").send_keys "2012-01-01"
    @driver.find_element(:id => "accession_content_description").send_keys "A box containing our own universe"
    @driver.find_element(:id => "accession_condition_description").send_keys "Slightly squashed"

    @driver.find_element(:css => "form#new_accession button[type='submit']").click
  end


  it "Can edit an accession once created" do
    @driver.find_element(:link, 'Edit Accession').click

    @driver.find_element(:id => 'accession_content_description').clear
    @driver.find_element(:id => 'accession_content_description').send_keys "Here is a description of this accession."
    @driver.find_element(:id => 'accession_condition_description').clear
    @driver.find_element(:id => 'accession_condition_description').send_keys "Here we note the condition of this accession."

    # note - the form is called 'new_accession' even though this is an edit form -jj
    @driver.find_element(:css => "form#new_accession button[type='submit']").click

    @driver.find_element(:css => 'body').text.should match(/Here is a description of this accession/)
  end


  it "Can edit an accession but cancel the edit" do
    @driver.find_element(:link, 'Edit Accession').click
    @driver.find_element(:id => 'accession_content_description').send_keys " moo"
    @driver.find_element(:link, "Cancel").click

    @driver.find_element(:css => 'body').text.should_not match(/Here is a description of this accession. moo/)
  end


  it "Notifies of errors and warnings when creating an invalid accession" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Collection").click

    @driver.find_element(:css => "form#new_collection button[type='submit']").click

    @driver.find_element(:css, "div.alert.alert-error").text.should eq('Identifier - Property is required but was missing')
    @driver.find_element(:css, "div.alert.alert-warning").text.should eq('Title - Property was missing')

    @driver.find_element(:css, "a.btn.btn-cancel").click
  end


  collection_title = "Pony Express"

  it "Can successfully create a collection" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Collection").click

    @driver.find_element(:id, "collection_title").send_keys collection_title
    @driver.complete_4part_id("collection_id_%d")
    @driver.find_element(:css => "form#new_collection button[type='submit']").click

    # The new collection shows up on the tree to the left
    @driver.find_element(:css => "a.jstree-clicked").text.strip.should eq(collection_title)
  end


  it "Gets errors if adding an empty child to a collection" do
    @driver.find_element(:link, "Add Child").click
    @driver.find_element(:link, "Analog Object").click

    # False start: create an object without filling it out
    @driver.click_and_wait_until_gone(:id => "createPlusOne")
    @driver.find_element(:css, "div.alert.alert-error").text.should eq('Ref ID - Property is required but was missing')
  end


  it "Can populate the archival object tree" do
    @driver.find_element(:id, "archival_object_title").clear
    @driver.find_element(:id, "archival_object_title").send_keys("Lost mail")
    @driver.find_element(:id, "archival_object_ref_id").send_keys(Digest::MD5.hexdigest("#{Time.now}"))
    @driver.click_and_wait_until_gone(:id => "createPlusOne")

    ["January", "February", "December"]. each do |month|

      @driver.find_element(:id, "archival_object_title").clear
      @driver.find_element(:id, "archival_object_title").send_keys(month)
      @driver.find_element(:id, "archival_object_ref_id").send_keys(Digest::MD5.hexdigest("#{month}#{Time.now}"))

      old_element = @driver.find_element(:id, "archival_object_title")
      @driver.click_and_wait_until_gone(:id => "createPlusOne")
    end
  end


  it "Can cancel edits to archival object records" do
    @driver.find_element(:id, "archival_object_title").clear
    @driver.find_element(:id, "archival_object_title").send_keys("unimportant change")
    @driver.find_element(:css, "a[title='December']").click
    @driver.find_element(:id, "dismissChangesButton").click

    # Last added node now selected
    @driver.find_element(:css => "a.jstree-clicked").text.strip.should eq('December')
  end


  it "Can add a child to an existing node and assign a subject" do
    @driver.find_element(:link, "Add Child").click
    @driver.find_element(:link, "Analog Object").click
    @driver.find_element(:id, "archival_object_title").clear
    @driver.find_element(:id, "archival_object_title").send_keys("Christmas cards")
    @driver.find_element(:id, "archival_object_ref_id").send_keys(Digest::MD5.hexdigest("#{Time.now}"))

    @driver.find_element(:css, ".linker-wrapper a.btn").click
    @driver.find_element(:css, "a.linker-create-btn").click
    @driver.find_element(:css, "form#new_subject .row-fluid:first-child input").send_keys("TestTerm123")
    @driver.find_element(:css, "form#new_subject .row-fluid:first-child .add-term-btn").click
    @driver.find_element(:css, "form#new_subject .row-fluid:last-child input").send_keys("FooTerm456")
    @driver.find_element(:id, "createAndLinkButton").click
  end


  it "Can remove the linked subject but find it using typeahead and re-add it" do
    # remove the subject
    @driver.find_element(:css, ".token-input-delete-token").click

    # search for the created subject
    @driver.find_element(:id, "token-input-").send_keys("Foo")
    @driver.find_element(:css, "li.token-input-dropdown-item2").click

    @driver.find_element(:css, "form#new_archival_object button[type='submit']").click

    # Verify that the change stuck
    @driver.navigate.refresh

    @driver.find_element(:css, "ul.token-input-list").text.should match(/FooTerm456/)
  end


  it "Can see our newly added collection in the browse list" do
    @driver.find_element(:link, "Browse").click
    @driver.find_element(:link, "Collections").click
    @driver.find_element_with_text('//td', /#{collection_title}/)
  end

  it "Can't see the collection in the browse list of a different repository" do
    ## Change repository
    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link_text => test_repo_code_1).click

    ## Check browse list for collections
    @driver.find_element(:link, "Browse").click
    @driver.find_element(:link, "Collections").click
    if @driver.find_element_with_text('//td', /#{collection_title}/, true) != nil
      puts "ERROR: #{collection_title} should not exist in collection Browse list!"
    end
  end

  it "Can log out once finished" do
    logout(@driver)
  end
end
