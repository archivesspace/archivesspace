require_relative 'spec_helper'

describe "ArchivesSpace user interface" do

  # Start the dev servers and Selenium
  before(:all) do
    selenium_init
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


  it "automatically refreshes the repository list when a new repo gets added" do
    new_repo_code = "webhooktest1#{Time.now.to_i}_#{$$}"
    new_repo_name = "webhook test repository - #{Time.now}"

    # Hit the backend API directly to create a repository from outside the browser
    res = Net::HTTP.post_form(URI("#{$backend}/users/admin/login"), :password => "admin")
    admin_session = JSON(res.body)["session"]

    create_repo = URI("#{$backend}/repositories")

    req = Net::HTTP::Post.new(create_repo.path)
    req["X-ARCHIVESSPACE-SESSION"] = admin_session
    req.body = "{\"repo_code\": \"#{new_repo_code}\", \"description\": \"#{new_repo_name}\"}"

    Net::HTTP.start(create_repo.hostname, create_repo.port) do |http|
      res = http.request(req)

      if res.code != "200"
        raise "Bad response: #{res.body}"
      end
    end

    # Give the webhook time to fire
    sleep 5

    @driver.navigate.refresh

    # Verify that the new repo has shown up
    @driver.find_element(:css, '.repository-container .btn').click
    @driver.find_element(:link_text => new_repo_code).text.should eq(new_repo_code)
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


  it "reports errors when attempting to create a Group with missing data" do
    @driver.find_element(:link, "Admin").click
    @driver.find_element(:link, "Groups").click
    @driver.find_element(:link, "Create Group").click
    @driver.find_element(:css => "form#new_group input[type='submit']").click
    expect {
      @driver.find_element_with_text('//div[contains(@class, "error")]', /Group code - Property is required but was missing/)
    }.to_not raise_error
    @driver.find_element(:link, "Cancel").click
  end


  it "can create a new Group" do
    @driver.find_element(:link, "Create Group").click
    @driver.clear_and_send_keys([:id, 'group_group_code_'], "goo")
    @driver.clear_and_send_keys([:id, 'group_description_'], "Goo group to group goo")
    @driver.find_element(:id, "view_repository").click
    @driver.find_element(:css => "form#new_group input[type='submit']").click
    expect {
      @driver.find_element_with_text('//tr', /goo/)
    }.to_not raise_error
  end


  it "reports errors when attempting to update a Group with missing data" do
    @driver.find_element_with_text('//tr', /goo/).find_element(:link, "Edit").click
    @driver.clear_and_send_keys([:id, 'group_description_'], "")
    @driver.find_element(:css => "form#new_group input[type='submit']").click
    expect {
      @driver.find_element_with_text('//div[contains(@class, "error")]', /Description - Property is required but was missing/)
    }.to_not raise_error
    @driver.find_element(:link, "Cancel").click
  end


  it "can edit a Group" do
    @driver.find_element_with_text('//tr', /goo/).find_element(:link, "Edit").click
    @driver.clear_and_send_keys([:id, 'group_description_'], "Group to gather goo")
    @driver.find_element(:css => "form#new_group input[type='submit']").click
    expect {
      @driver.find_element_with_text('//tr', /Group to gather goo/)
    }.to_not raise_error
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

  it "reports errors and warnings when creating an invalid Subject" do
    @driver.find_element(:link => 'Create').click
    @driver.find_element(:link => 'Subject').click

    @driver.find_element(:css => '#subject_external_documents_ .subrecord-form-heading .btn').click

    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click

    # check messages
    @driver.find_element_with_text('//div[contains(@class, "warning")]', /Term - Property was missing/)
  end

  # Person Agents

  it "reports errors and warnings when creating an invalid Person Agent" do
    @driver.find_element(:link, 'Create').click
    @driver.execute_script("$('.nav .dropdown-submenu a:contains(Agent)').focus()");
    @driver.find_element(:link, 'Person').click
    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Rules - is required/)
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Primary Name - Property is required but was missing/)
  end


  it "reports an error when Authority ID is provided without a Source" do
    @driver.clear_and_send_keys([:id, "agent_names__0__authority_id_"], "authid123")
    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Source - is required/)
  end


  it "reports an error when Source is provided without an Authority ID" do
    @driver.clear_and_send_keys([:id, "agent_names__0__authority_id_"], "")
    source_select = @driver.find_element(:id => "agent_names__0__source_")

    source_select.select_option("local")

    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click

    @driver.find_element_with_text('//div[contains(@class, "error")]', /Authority ID - is required/)
  end


  it "updates Sort Name when other name fields are updated" do
    @driver.clear_and_send_keys([:id, "agent_names__0__authority_id_"], "authid123")
    @driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], ["Hendrix", :tab])
    @driver.clear_and_send_keys([:id, "agent_names__0__rest_of_name_"], "woo")
    @driver.find_element(:id => "agent_names__0__rest_of_name_").clear
    sleep 2

    @driver.find_element(:id => "agent_names__0__sort_name_").attribute("value").should eq("Hendrix")
    @driver.clear_and_send_keys([:id, "agent_names__0__rest_of_name_"], ["Johnny Allen", :tab])
    @driver.clear_and_send_keys([:id, "agent_names__0__suffix_"], "woo")
    @driver.find_element(:id => "agent_names__0__suffix_").clear
    sleep 2

    @driver.find_element(:id => "agent_names__0__sort_name_").attribute("value").should eq("Hendrix, Johnny Allen")
  end


  it "changing Direct Order updates Sort Name" do
    direct_order_select = @driver.find_element(:id => "agent_names__0__direct_order_")
    direct_order_select.find_elements( :tag_name => "option" ).each do |option|
      option.click if option.attribute("value") === "inverted"
    end

    @driver.find_element(:id => "agent_names__0__sort_name_").attribute("value").should eq("Johnny Allen Hendrix")
  end


  it "can add a secondary name and validations match index of name form" do
    @driver.find_element(:css => '#names .subrecord-form-heading .btn').click
    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click

    @driver.find_element_with_text('//div[contains(@class, "error")]', /Rules - is required/)
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Primary Name - Property is required but was missing/)

    rules_select = @driver.find_element(:id => "agent_names__1__rules_")

    rules_select.find_elements( :tag_name => "option" ).each do |option|
      option.click if option.attribute("value") === "local"
    end

    @driver.clear_and_send_keys([:id, "agent_names__1__primary_name_"], "Hendrix")
    @driver.clear_and_send_keys([:id, "agent_names__1__rest_of_name_"], ["Jimi", :tab])
    # ensure sort_name is generated by javascript
    @driver.clear_and_send_keys([:id, "agent_names__1__suffix_"], "woo")
    @driver.find_element(:id => "agent_names__1__suffix_").clear
    sleep 2
    @driver.find_element(:id => "agent_names__1__sort_name_").attribute("value").should eq("Hendrix, Jimi")
  end


  it "can add a contact to a person" do
    @driver.find_element(:css => '#contacts .subrecord-form-heading .btn').click
    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click

    @driver.find_element_with_text('//div[contains(@class, "error")]', /Contact Description - Property is required but was missing/)

    @driver.clear_and_send_keys([:id, "agent_agent_contacts__0__name_"], "Email Address")
    @driver.clear_and_send_keys([:id, "agent_agent_contacts__0__email_"], "jimi@rocknrollheaven.com")
  end


  it "can save a person and view readonly view of person" do
    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click

    @driver.find_element(:css => '.record-pane h2').text.should eq("Johnny Allen Hendrix Agent")
  end


  it "can present a person edit form" do
    @driver.find_element(:link, 'Edit').click
    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').text.should eq("Save Person")
  end


  it "reports errors when updating a Person Agent with invalid data" do
    @driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], "")
    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Primary Name - Property is required but was missing/)
      .text.should match(/Primary Name - Property is required but was missing/)
    @driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], "Hendrix")
  end


  it "can remove contact details" do
    @driver.find_element(:css => '#contacts .subrecord-form-remove').click
    @driver.find_element(:css => '#contacts .confirm-removal').click

    sleep(1)

    @driver.ensure_no_such_element(:id => "agent_agent_contacts__0__name_")

    @driver.click_and_wait_until_gone(:css => '#archivesSpaceSidebar button.btn-primary')

    @driver.ensure_no_such_element(:css => "#contacts h3")
  end


  it "displays the agent in the agent's index page" do
    @driver.find_element(:link, 'Browse Agents').click
    expect {
      @driver.find_element_with_text('//td', /Johnny Allen Hendrix/)
    }.to_not raise_error
  end


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


  it "reports errors when updating an Accession with invalid data" do
    @driver.find_element(:link, 'Edit').click
    @driver.clear_and_send_keys([:id, "accession_title_"], "")
    @driver.find_element(:css => "form#accession_form button[type='submit']").click
    expect {
      @driver.find_element_with_text('//div[contains(@class, "error")]', /Title - Property is required but was missing/)
    }.to_not raise_error
    # cancel first to back out bad change
    @driver.find_element(:link, "Cancel").click
    # cancel second to leave edit mode without saving
    @driver.find_element(:link, "Cancel").click
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

    me = "#{$$}.#{Time.now.to_i}"

    @driver.find_element(:link, 'Edit').click

    @driver.find_element(:css, ".linker-wrapper a.btn").click
    @driver.find_element(:css, "a.linker-create-btn").click
    @driver.clear_and_send_keys([:css, "form#new_subject .row-fluid:first-child input"], "#{me}AccessionTermABC")
    @driver.find_element(:css, "form#new_subject .row-fluid:first-child .add-term-btn").click
    @driver.clear_and_send_keys([:css, "form#new_subject .row-fluid:last-child input"], "#{me}AccessionTermDEF")
    @driver.find_element(:id, "createAndLinkButton").click

    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    @driver.find_element(:css => ".label-and-value .token").text.should eq("#{me}AccessionTermABC -- #{me}AccessionTermDEF")
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


  it "can show a browse list of Accessions" do
    @driver.find_element(:link, "Browse").click
    @driver.find_element(:link, "Accessions").click
    expect {
      @driver.find_element_with_text('//td', /#{accession_title}/)
    }.to_not raise_error
  end


  # Events

  it "creates an event and links it to an agent and accession" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Event").click
    @driver.find_element(:id, "event_event_type_").select_option('virus check')
    @driver.clear_and_send_keys([:id, "event_outcome_"], "A good outcome")
    @driver.clear_and_send_keys([:id, "event_outcome_note_"], "OK, that's a lie: all test subjects perished.")

    @driver.find_element(:id, "event_date__date_type__single").click
    @driver.clear_and_send_keys([:id, "event_date__begin__single"], ["2000-01-01", :tab])

    agent_subform = @driver.find_element(:id, "event_linked_agents__0__role_").
                            nearest_ancestor('div[contains(@class, "subrecord-form-container")]')

    @driver.find_element(:id, "event_linked_agents__0__role_").select_option('recipient')
    agent_subform.find_element(:id, "token-input-").send_keys("Johnny")
    @driver.find_element(:css, "li.token-input-dropdown-item2").click

    record_subform = @driver.find_element(:id, "event_linked_records__0__role_").
                             nearest_ancestor('div[contains(@class, "subrecord-form-container")]')

    record_subform.find_element(:id, "token-input-").send_keys("Accession with dates")
    @driver.find_element(:css, "li.token-input-dropdown-item2").click

    @driver.find_element(:css => "form#new_event button[type='submit']").click
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


  it "reports warnings when updating a Resource with invalid data" do
    @driver.clear_and_send_keys([:id, "resource_title_"],"")
    @driver.find_element(:css => "form#new_resource button[type='submit']").click
    expect {
      @driver.find_element_with_text('//div[contains(@class, "warning")]', /Title - Property was missing/)
    }.to_not raise_error
    @driver.clear_and_send_keys([:id, "resource_title_"],(resource_title))
    @driver.find_element(:css => "form#new_resource button[type='submit']").click
  end


  it "reports errors if adding an empty child to a Resource" do
    @driver.find_element(:link, "Add Child").click
    @driver.find_element(:link, "Archival Object").click

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


  it "reports warnings when updating an Archival Object with invalid data" do
    aotitle = @driver.find_element(:css, "h2").text.sub(/ +Archival Object/, "")
    @driver.clear_and_send_keys([:id, "archival_object_title_"], "")
    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click
    expect {
      @driver.find_element_with_text('//div[contains(@class, "warning")]', /Title - Property was missing/)
    }.to_not raise_error
    @driver.clear_and_send_keys([:id, "archival_object_title_"], aotitle)
    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click
  end

  it "can update an existing Archival Object" do
    aotitle = @driver.find_element(:css, "h2").text.sub(/ +Archival Object/, "")
    puts "aotitle: #{aotitle}"
    @driver.clear_and_send_keys([:id, "archival_object_title_"], "save this please")
    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click
    @driver.find_element(:css, "h2").text.should eq("save this please Archival Object")
    @driver.find_element(:css => "div.alert.alert-success").text.should eq('Archival Object Saved')
    @driver.clear_and_send_keys([:id, "archival_object_title_"], aotitle)
    @driver.find_element(:css => '#archivesSpaceSidebar button.btn-primary').click
  end


  it "can add a child to an existing node and assign a Subject" do
    @driver.find_element(:link, "Add Child").click
    @driver.find_element(:link, "Archival Object").click
    @driver.clear_and_send_keys([:id, "archival_object_title_"], "Christmas cards")
    @driver.clear_and_send_keys([:id, "archival_object_ref_id_"],(Digest::MD5.hexdigest("#{Time.now}")))

    @driver.find_element(:css, ".linker-wrapper a.btn").click
    @driver.find_element(:css, "a.linker-create-btn").click
    @driver.clear_and_send_keys([:css, "form#new_subject .row-fluid:first-child input"], "#{$$}TestTerm123")
    @driver.find_element(:css, "form#new_subject .row-fluid:first-child .add-term-btn").click
    @driver.clear_and_send_keys([:css, "form#new_subject .row-fluid:last-child input"], "#{$$}FooTerm456")
    @driver.find_element(:id, "createAndLinkButton").click
  end


  it "can remove the linked Subject but find it using typeahead and re-add it" do
    # remove the subject
    @driver.find_element(:css, ".token-input-delete-token").click

    # search for the created subject
    @driver.clear_and_send_keys([:id, "token-input-"], "#{$$}FooTerm456")
    @driver.find_element(:css, "li.token-input-dropdown-item2").click

    @driver.click_and_wait_until_gone(:css, "form#new_archival_object button[type='submit']")

    # so the subject is here now
    @driver.find_element(:css, "ul.token-input-list").text.should match(/#{$$}FooTerm456/)

    # refresh the page and verify that the change really stuck
    @driver.navigate.refresh

    @driver.find_element(:css, "ul.token-input-list").text.should match(/#{$$}FooTerm456/)
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


  it "can attach notes to resources" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Resource").click

    @driver.clear_and_send_keys([:id, "resource_title_"], "a resource with notes")
    @driver.complete_4part_id("resource_id_%d_")
    @driver.clear_and_send_keys([:id, "resource_extents__0__number_"], "10")

    add_note = proc do |type|
      @driver.find_element(:css => '#notes .subrecord-form-heading .btn').click
      @driver.find_element(:css => '#notes .subrecord-selector select').select_option(type)
      @driver.find_element(:css => '#notes .subrecord-selector .btn').click
    end

    3.times do
      add_note.call("note_multipart")
    end

    @driver.blocking_find_elements(:css => '#notes .subrecord-form-fields').length.should eq(3)
  end


  it "confirms before removing a note entry" do
    notes = @driver.blocking_find_elements(:css => '#notes .subrecord-form-fields')

    notes[0].find_element(:css => '.subrecord-form-remove').click

    # Get a confirmation
    @driver.find_element(:css => '.subrecord-form-removal-confirmation')

    # Now remove the second note
    notes[1].find_element(:css => '.subrecord-form-remove').click

    # Verify that the first confirmation is now gone
    @driver.find_elements(:css => '.subrecord-form-removal-confirmation').length.should be < 2

    # Confirm
    @driver.find_element(:css => '.subrecord-form-removal-confirmation .btn-primary').click

    # Take out the first note too
    notes[0].find_element(:css => '.subrecord-form-remove').click
    @driver.find_element(:css => '.subrecord-form-removal-confirmation .btn-primary').click

    # One left!
    @driver.blocking_find_elements(:css => '#notes .subrecord-form-fields').length.should eq(1)

    # Fill it out
    @driver.clear_and_send_keys([:id, 'resource_notes__2__label_'],
                                "A multipart note")

    @driver.clear_and_send_keys([:id, 'resource_notes__2__content_'],
                                "Some note content")


    # Save the resource
    @driver.find_element(:css => "form#new_resource button[type='submit']").click
    @driver.find_element(:link, 'Finish Editing').click
  end


  it "can edit an existing resource note to add subparts after saving" do
    @driver.find_element(:link, 'Edit').click

    notes = @driver.blocking_find_elements(:css => '#notes .subrecord-form-fields')

    # Add a sub note
    notes[0].find_element(:css => '.subrecord-form-heading .btn').click
    notes[0].find_element(:css => '.subrecord-selector select').select_option('note_bibliography')
    notes[0].find_element(:css => '.add-sub-note-btn').click

    @driver.find_element(:id => 'resource_notes__0__subnotes__1__label_')
    @driver.clear_and_send_keys([:id, 'resource_notes__0__subnotes__1__label_'], "Bibliography label")
    @driver.clear_and_send_keys([:id, 'resource_notes__0__subnotes__1__content_'], "Bibliography content")

    2.times do
      notes[0].find_element(:css => '.add-item-btn').click
    end

    @driver.clear_and_send_keys([:id, 'resource_notes__0__subnotes__1__items__2_'], "Bib item 1")
    @driver.clear_and_send_keys([:id, 'resource_notes__0__subnotes__1__items__3_'], "Bib item 2")


    notes[0].find_element(:css => '.subrecord-form-heading .btn').click
    notes[0].find_element(:css => '.subrecord-selector select').select_option('note_index')
    notes[0].find_element(:css => '.add-sub-note-btn').click

    @driver.clear_and_send_keys([:id, 'resource_notes__0__subnotes__4__label_'], "Index item")
    @driver.clear_and_send_keys([:id, 'resource_notes__0__subnotes__4__content_'], "Index content")

    2.times do
      @driver.find_element(:id => 'resource_notes__0__subnotes__4__label_').
              containing_subform.
              find_element(:css => '.add-item-btn').
              click
    end

    [5, 6]. each do |i|
      ["value", "type", "reference", "reference_text"].each do |field|
        @driver.clear_and_send_keys([:id, "resource_notes__0__subnotes__4__items__#{i}__#{field}_"],
                                    "pogo")
      end
    end

    # Save the resource
    @driver.find_element(:css => "form#new_resource button[type='submit']").click
    @driver.find_element(:link, 'Finish Editing').click

    @driver.find_element_with_text("//div", /pogo/)
  end


  it "can add a top-level bibliography too" do
    @driver.find_element(:link, 'Edit').click

    add_note_button = @driver.find_element(:css => '#notes > .subrecord-form-heading .btn').click
    @driver.find_element(:css => '#notes > .subrecord-form-heading select').select_option("note_bibliography")
    @driver.find_element(:css => '#notes > .subrecord-form-heading .subrecord-selector .btn').click

    @driver.clear_and_send_keys([:id, 'resource_notes__5__label_'], "Top-level bibliography label")
    @driver.clear_and_send_keys([:id, 'resource_notes__5__content_'], "Top-level bibliography content")

    form = @driver.find_element(:id => 'resource_notes__5__content_').nearest_ancestor('div[contains(@class, "subrecord-form-container")]')

    2.times do
      form.find_element(:css => '.add-item-btn').click
    end

    @driver.clear_and_send_keys([:id, 'resource_notes__5__items__6_'], "Top-level bib item 1")
    @driver.clear_and_send_keys([:id, 'resource_notes__5__items__7_'], "Top-level bib item 2")

    # Save the resource
    @driver.find_element(:css => "form#new_resource button[type='submit']").click
    @driver.find_element(:link, 'Finish Editing').click
  end


  it "can add a deaccession record" do
    @driver.find_element(:link, 'Edit').click

    @driver.find_element(:css => '#resource_deaccessions_ .subrecord-form-heading .btn').click

    @driver.find_element(:id => 'resource_deaccessions__0__date__label_').get_select_value.should eq("deaccession")

    @driver.clear_and_send_keys([:id, 'resource_deaccessions__0__description_'], "Lalala describing the deaccession")
    @driver.find_element(:css => "#resource_deaccessions__0__date__date_type__single").find_element(:xpath => "./parent::*").click
    sleep 2 # wait for dropdown/enabling of inputs
    @driver.clear_and_send_keys([:id, 'resource_deaccessions__0__date__begin__single'], "2012-05-14")


    # Save the resource
    @driver.find_element(:css => "form#new_resource button[type='submit']").click
    @driver.find_element(:link, 'Finish Editing').click

    @driver.blocking_find_elements(:css => '#resource_deaccessions_').length.should eq(1)
  end



  # Digital Objects

  it "reports errors and warnings when creating an invalid Digital Object" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Digital Object").click
    @driver.find_element(:id, "digital_object_title_").clear
    @driver.find_element(:css => "form#new_digital_object button[type='submit']").click

    @driver.find_element_with_text('//div[contains(@class, "error")]', /Identifier - Property is required but was missing/)

    @driver.find_element(:css, "a.btn.btn-cancel").click
  end


  digital_object_title = "Pony Express Digital Image"

  it "can create a digital_object" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Digital Object").click

    @driver.clear_and_send_keys([:id, "digital_object_title_"],(digital_object_title))
    @driver.clear_and_send_keys([:id, "digital_object_digital_object_id_"],(Digest::MD5.hexdigest("#{Time.now}")))

    @driver.find_element(:css => "form#new_digital_object button[type='submit']").click

    # The new Digital Object shows up on the tree
    @driver.find_element(:css => "a.jstree-clicked").text.strip.should eq(digital_object_title)
  end


  it "reports errors if adding an empty child to a Digital Object" do
    @driver.find_element(:link, "Add Child").click
    @driver.find_element(:link, "Digital Object Component").click

    # False start: create an object without filling it out
    @driver.click_and_wait_until_gone(:id => "createPlusOne")

    @driver.find_element_with_text('//div[contains(@class, "error")]', /Identifier - Property is required but was missing/)
  end


  # Digital Object Component Nodes in Tree

  it "can populate the archival object tree" do
    @driver.clear_and_send_keys([:id, "digital_object_component_title_"], "JPEG 2000 Verson of Image")
    @driver.clear_and_send_keys([:id, "digital_object_component_component_id_"],(Digest::MD5.hexdigest("#{Time.now}")))

    @driver.click_and_wait_until_gone(:id => "createPlusOne")

    ["PNG format", "GIF format", "BMP format"].each_with_index do |thing, idx|

      # Wait for the new empty form to be populated.  There's a tricky race
      # condition here that I can't quite track down, so here's my blunt
      # instrument fix.
      @driver.find_element(:xpath, "//input[@value='New Digital Object Component']")

      @driver.clear_and_send_keys([:id, "digital_object_component_title_"],(thing))
      @driver.clear_and_send_keys([:id, "digital_object_component_label_"],(thing))
      @driver.clear_and_send_keys([:id, "digital_object_component_component_id_"],(Digest::MD5.hexdigest("#{thing}#{Time.now}")))

      if idx < 2
        @driver.click_and_wait_until_gone(:id => "createPlusOne")
      else
        @driver.find_element(:css => "form#new_digital_object_component button[type='submit']").click
      end
    end


    elements = @driver.blocking_find_elements(:css => "li.jstree-leaf").map{|li| li.text.strip}

    ["PNG format", "GIF format", "BMP format"].each do |thing|
      elements.any? {|elt| elt =~ /#{thing}/}.should be_true
    end

  end


  # Log out

  it "can log out once finished" do
    logout(@driver)
  end

end
