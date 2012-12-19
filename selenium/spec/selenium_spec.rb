require_relative 'spec_helper'
require_relative '../../indexer/periodic_indexer'

describe "ArchivesSpace user interface" do

  # Start the dev servers and Selenium
  before(:all) do
    selenium_init
    state = Object.new.instance_eval do
      @store = {}

      def get_last_mtime(repo, record_type)
        @store[[repo[:repo_code], record_type]].to_i || 0
      end

      def set_last_mtime(repo, record_type, time)
        @store[[repo[:repo_code], record_type]] = time
      end

      self
    end

    @indexer = PeriodicIndexer.get_indexer(state)
  end


  # Stop selenium, kill the dev servers
  after(:all) do
    report_sleep
    cleanup
  end


  def self.xdescribe(*stuff)
  end

  after(:each) do |group|
    if group.example.exception and ENV['SCREENSHOT_ON_ERROR']
      outfile = "/tmp/#{Time.now.to_i}_#{$$}.png"
      puts "Saving screenshot to #{outfile}"
      $driver.save_screenshot(outfile)
    end
  end


  describe "Repositories" do

    before(:all) do
      @test_repo_code_1 = "test1#{Time.now.to_i}_#{$$}"
      @test_repo_name_1 = "test repository 1 - #{Time.now}"
      @test_repo_code_2 = "test2#{Time.now.to_i}_#{$$}"
      @test_repo_name_2 = "test repository 2 - #{Time.now}"

      login("admin", "admin")
    end

    after(:all) do
      logout
    end


    it "flags errors when creating a repository with missing fields" do
      $driver.find_element(:css, '.repository-container .btn').click
      $driver.find_element(:link, "Create a Repository").click
      $driver.clear_and_send_keys([:id, "repository_description_"], "missing repo code")
      $driver.find_element(:css => "form#new_repository input[type='submit']").click

      assert { $driver.find_element(:css => "div.alert.alert-error").text.should eq('Repository code - Property is required but was missing') }
      $driver.find_element(:css => "div.modal-footer button.btn").click
    end


    it "can create a repository" do
      $driver.find_element(:css, '.repository-container .btn').click
      $driver.find_element(:link, "Create a Repository").click
      $driver.clear_and_send_keys([:id, "repository_repo_code_"], @test_repo_code_1)
      $driver.clear_and_send_keys([:id, "repository_description_"], @test_repo_name_1)
      $driver.find_element(:css => "form#new_repository input[type='submit']").click
    end


    it "can create a second repository" do
      $driver.find_element(:css, '.repository-container .btn').click
      $driver.find_element(:link, "Create a Repository").click
      $driver.clear_and_send_keys([:id, "repository_repo_code_"], @test_repo_code_2)
      $driver.clear_and_send_keys([:id, "repository_description_"], @test_repo_name_2)
      $driver.find_element(:css => "form#new_repository input[type='submit']").click
    end


    it "can select either of the created repositories" do
      $driver.find_element(:css, '.repository-container .btn').click
      assert { $driver.find_element(:link_text => @test_repo_code_2).text.should eq @test_repo_code_2 }
      $driver.find_element(:link_text => @test_repo_code_2).click
      assert { $driver.find_element(:css, 'span.current-repository-id').text.should eq @test_repo_code_2 }


      $driver.find_element(:css, '.repository-container .btn').click
      assert { $driver.find_element(:link_text => @test_repo_code_1).text.should eq @test_repo_code_1 }
      $driver.find_element(:link_text => @test_repo_code_1).click
      assert { $driver.find_element(:css, 'span.current-repository-id').text.should eq @test_repo_code_1 }


      $driver.find_element(:css, '.repository-container .btn').click
      $driver.find_element(:link_text => @test_repo_code_2).click
      assert { $driver.find_element(:css, 'span.current-repository-id').text.should eq @test_repo_code_2 }
    end


    it "automatically refreshes the repository list when a new repo gets added" do
      new_repo_code = "webhooktest1#{Time.now.to_i}_#{$$}"
      new_repo_name = "webhook test repository - #{Time.now}"

      create_test_repo(new_repo_code, new_repo_name)

      $driver.navigate.refresh

      # Verify that the new repo has shown up
      $driver.find_element(:css, '.repository-container .btn').click
      assert { $driver.find_element(:link_text => new_repo_code).text.should eq(new_repo_code) }
    end
  end


  describe "Groups" do

    before(:all) do
      @can_manage_repo = "group_manage#{Time.now.to_i}_#{$$}"
      @can_view_repo = "group_view#{Time.now.to_i}_#{$$}"

      (@user, @pass) = create_user

      create_test_repo(@can_manage_repo, "manage", false)
      create_test_repo(@can_view_repo, "view", false)
      # wait for webhook to fire (which can take up to 5 seconds)
      sleep 5
      login("admin", "admin")
    end


    after(:all) do
      logout
    end


    it "can assign a user to the archivist group" do
      select_repo(@can_manage_repo)

      $driver.find_element(:css, '.repository-container .btn').click
      $driver.find_element(:link, "Manage Groups").click

      row = $driver.find_element_with_text('//tr', /repository-archivists/)
      row.find_element(:css, '.btn').click

      $driver.clear_and_send_keys([:id, 'new-member'],(@user))
      $driver.find_element(:id, 'add-new-member').click
      $driver.find_element(:css => 'input[type="submit"]').click
    end


    it "can assign the test user to the viewers group of the first repository" do
      select_repo(@can_view_repo)

      $driver.find_element(:css, '.repository-container .btn').click
      $driver.find_element(:link, "Manage Groups").click

      row = $driver.find_element_with_text('//tr', /repository-viewers/)
      row.find_element(:css, '.btn').click

      $driver.clear_and_send_keys([:id, 'new-member'],(@user))
      $driver.find_element(:id, 'add-new-member').click
      $driver.find_element(:css => 'input[type="submit"]').click
    end


    it "reports errors when attempting to create a Group with missing data" do
      $driver.find_element(:css, '.repository-container .btn').click
      $driver.find_element(:link, "Manage Groups").click
      $driver.find_element(:link, "Create Group").click
      $driver.find_element(:css => "form#new_group input[type='submit']").click
      expect {
        $driver.find_element_with_text('//div[contains(@class, "error")]', /Group code - Property is required but was missing/)
      }.to_not raise_error
      $driver.find_element(:link, "Cancel").click
    end


    it "can create a new Group" do
      $driver.find_element(:link, "Create Group").click
      $driver.clear_and_send_keys([:id, 'group_group_code_'], "goo")
      $driver.clear_and_send_keys([:id, 'group_description_'], "Goo group to group goo")
      $driver.find_element(:id, "view_repository").click
      $driver.find_element(:css => "form#new_group input[type='submit']").click


      expect {
        $driver.find_element_with_text('//tr', /goo/)
      }.to_not raise_error
    end


    it "reports errors when attempting to update a Group with missing data" do
      $driver.find_element_with_text('//tr', /goo/).find_element(:link, "Edit").click
      $driver.clear_and_send_keys([:id, 'group_description_'], "")
      $driver.find_element(:css => "form#new_group input[type='submit']").click
      expect {
        $driver.find_element_with_text('//div[contains(@class, "error")]', /Description - Property is required but was missing/)
      }.to_not raise_error
      $driver.find_element(:link, "Cancel").click
    end


    it "can edit a Group" do
      $driver.find_element_with_text('//tr', /goo/).find_element(:link, "Edit").click
      $driver.clear_and_send_keys([:id, 'group_description_'], "Group to gather goo")
      $driver.find_element(:css => "form#new_group input[type='submit']").click
      expect {
        $driver.find_element_with_text('//tr', /Group to gather goo/)
      }.to_not raise_error
    end


    it "can log out of the admin account" do
      logout
    end


    it "can log in with the user just created" do
      $driver.find_element(:link, "Sign In").click
      $driver.clear_and_send_keys([:id, 'user_username'], @user)
      $driver.clear_and_send_keys([:id, 'user_password'], @pass)
      $driver.find_element(:id, 'login').click

      assert { $driver.find_element(:css => "span.user-label").text.should match(/#{@user}/) }
    end


    it "doesn't see the 'Create' menu in the first repository" do
      # Wait until we're marked as logged in
      $driver.find_element_with_text('//span', /#{@user}/)

      select_repo(@can_view_repo)

      $driver.ensure_no_such_element(:link, "Create")
    end


    it "can select the second repository and find the create link" do
      select_repo(@can_manage_repo)

      # Wait until it's selected
      $driver.find_element_with_text('//span', /#{@can_manage_repo}/)
      $driver.find_element(:link, "Create")
    end
  end


  describe "Subjects" do

    before(:all) do
      login_as_archivist
    end

    after(:all) do
      logout
    end

    it "reports errors and warnings when creating an invalid Subject" do
      $driver.find_element(:link => 'Create').click
      $driver.find_element(:link => 'Subject').click

      $driver.find_element(:css => '#subject_external_documents_ .subrecord-form-heading .btn').click

      $driver.find_element(:css => "form .record-pane button[type='submit']").click

      # check messages
      expect {
        $driver.find_element_with_text('//div[contains(@class, "error")]', /Term - Property is required but was missing/)
      }.to_not raise_error
    end


    it "can create a new Subject" do
      now = "#{$$}.#{Time.now.to_i}"

      $driver.find_element(:link => 'Create').click
      $driver.find_element(:link => 'Subject').click
      $driver.clear_and_send_keys([:id, "subject_terms__0__term_"], "just a term really #{now}")
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
      assert { $driver.find_element(:css => '.record-pane h2').text.should eq("just a term really #{now} Subject") }
    end


    it "can present a browse list of Subjects" do
      $driver.find_element(:link => 'Browse').click
      $driver.find_element(:link => 'Subjects').click

      expect {
        $driver.find_element_with_text('//tr', /just a term really/)
      }.to_not raise_error
    end

  end


  describe "Agents" do

    before(:all) do
      login_as_archivist
    end

    after(:all) do
      logout
    end


    it "reports errors and warnings when creating an invalid Person Agent" do
      $driver.find_element(:link, 'Create').click
      $driver.execute_script("$('.nav .dropdown-submenu a:contains(Agent)').focus()");
      $driver.find_element(:link, 'Person').click
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Sort Name - Property is required but was missing/)
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Primary Name - Property is required but was missing/)
    end


    it "reports an error when Authority ID is provided without a Source" do
      $driver.clear_and_send_keys([:id, "agent_names__0__authority_id_"], "authid123")
      $driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], ["Hendrix", :tab])
      assert {
        $driver.find_element(:id => "agent_names__0__sort_name_").attribute("value").should eq("Hendrix")
      }
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Source - is required/)
    end


    it "reports an error when Source is provided without an Authority ID" do
      $driver.clear_and_send_keys([:id, "agent_names__0__authority_id_"], "")
      source_select = $driver.find_element(:id => "agent_names__0__source_")

      source_select.select_option("local")

      $driver.find_element(:css => "form .record-pane button[type='submit']").click

      $driver.find_element_with_text('//div[contains(@class, "error")]', /Authority ID - is required/)
    end


    it "updates Sort Name when other name fields are updated" do
      $driver.clear_and_send_keys([:id, "agent_names__0__authority_id_"], "authid123")
      $driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], ["Hendrix", :tab])
      $driver.clear_and_send_keys([:id, "agent_names__0__rest_of_name_"], "woo")
      $driver.find_element(:id => "agent_names__0__rest_of_name_").clear

      assert {
        $driver.find_element(:id => "agent_names__0__sort_name_").attribute("value").should eq("Hendrix")
      }

      $driver.clear_and_send_keys([:id, "agent_names__0__rest_of_name_"], ["Johnny Allen", :tab])
      $driver.clear_and_send_keys([:id, "agent_names__0__suffix_"], "woo")
      $driver.find_element(:id => "agent_names__0__suffix_").clear


      assert {
        $driver.find_element(:id => "agent_names__0__sort_name_").attribute("value").should eq("Hendrix, Johnny Allen")
      }
    end


    it "changing Direct Order updates Sort Name" do
      direct_order_select = $driver.find_element(:id => "agent_names__0__direct_order_")
      direct_order_select.find_elements( :tag_name => "option" ).each do |option|
        option.click if option.attribute("value") === "inverted"
      end

      $driver.find_element(:id => "agent_names__0__sort_name_").attribute("value").should eq("Johnny Allen Hendrix")
    end


    it "can add a secondary name and validations match index of name form" do
      $driver.find_element(:css => '#names .subrecord-form-heading .btn').click
      $driver.find_element(:css => "form .record-pane button[type='submit']").click

      $driver.find_element_with_text('//div[contains(@class, "error")]', /Sort Name - Property is required but was missing/)
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Primary Name - Property is required but was missing/)

      rules_select = $driver.find_element(:id => "agent_names__1__rules_")

      rules_select.find_elements( :tag_name => "option" ).each do |option|
        option.click if option.attribute("value") === "local"
      end

      $driver.clear_and_send_keys([:id, "agent_names__1__primary_name_"], "Hendrix")

      $driver.clear_and_send_keys([:id, "agent_names__1__rest_of_name_"], ["Jimi", :tab])
      # ensure sort_name is generated by javascript
      $driver.clear_and_send_keys([:id, "agent_names__1__suffix_"], "woo")
      $driver.find_element(:id => "agent_names__1__suffix_").clear

      assert {
        $driver.find_element(:id => "agent_names__1__sort_name_").attribute("value").should eq("Hendrix, Jimi")
      }
    end


    it "can add a contact to a person" do
      $driver.find_element(:css => '#contacts .subrecord-form-heading .btn').click
      $driver.find_element(:css => "form .record-pane button[type='submit']").click

      $driver.find_element_with_text('//div[contains(@class, "error")]', /Contact Description - Property is required but was missing/)

      $driver.clear_and_send_keys([:id, "agent_agent_contacts__0__name_"], "Email Address")
      $driver.clear_and_send_keys([:id, "agent_agent_contacts__0__email_"], "jimi@rocknrollheaven.com")
    end


    it "can save a person and view readonly view of person" do
      $driver.find_element(:css => "form .record-pane button[type='submit']").click

      assert { $driver.find_element(:css => '.record-pane h2').text.should eq("Johnny Allen Hendrix Agent") }
    end


    it "can present a person edit form" do
      $driver.find_element(:link, 'Edit').click
      assert { $driver.find_element(:css => "form .record-pane button[type='submit']").text.should eq("Save Person") }
    end


    it "reports errors when updating a Person Agent with invalid data" do
      $driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], "")
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Primary Name - Property is required but was missing/)
      $driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], ["Hendrix", :tab])
      # ensure sort_name is generated by javascript
      $driver.clear_and_send_keys([:id, "agent_names__0__suffix_"], "woo")
      $driver.find_element(:id => "agent_names__0__suffix_").clear

      assert { $driver.find_element(:id => "agent_names__0__sort_name_").attribute("value").should eq("Johnny Allen Hendrix") }
    end


    it "can remove contact details" do
      $driver.find_element(:css => '#contacts .subrecord-form-remove').click
      $driver.find_element(:css => '#contacts .confirm-removal').click

      assert {
        $driver.ensure_no_such_element(:id => "agent_agent_contacts__0__name_")
      }

      $driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

      $driver.ensure_no_such_element(:css => "#contacts h3")
    end


    it "can add an external document to an Agent" do
      $driver.find_element(:link, 'Edit').click
      $driver.find_element(:css => '#agent_external_documents_ .subrecord-form-heading .btn').click

      $driver.clear_and_send_keys([:id, "agent_external_documents__0__title_"], "My URI document")
      $driver.clear_and_send_keys([:id, "agent_external_documents__0__location_"], "http://archivesspace.org")

      $driver.find_element(:css => "form .record-pane button[type='submit']").click

      # check external documents
      external_document_sections = $driver.blocking_find_elements(:css => '#agent_external_documents_ .external-document')
      external_document_sections.length.should eq (1)
      external_document_sections[0].find_element(:link => "http://archivesspace.org")
    end


    it "displays the agent in the agent's index page" do
      $driver.find_element(:link, 'Agents').click
      expect {
        $driver.find_element_with_text('//td', /Johnny Allen Hendrix/)
      }.to_not raise_error
    end

  end


  describe "Accessions" do

    before(:all) do
      login_as_archivist
      @accession_title = "Exciting new stuff - \u2603"
    end


    after(:all) do
      logout
    end


    it "gives option to ignore warnings when creating an Accession" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Accession").click
      $driver.clear_and_send_keys([:id, "accession_title_"], @accession_title)
      $driver.complete_4part_id("accession_id_%d_")
      $driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
      $driver.find_element(:css => "form#accession_form button[type='submit']").click

      $driver.find_element_with_text('//div[contains(@class, "warning")]', /Content Description - Property was missing/)
      $driver.find_element_with_text('//div[contains(@class, "warning")]', /Condition Description - Property was missing/)

      # Save anyway
      $driver.find_element(:css => "div.alert-warning .btn-warning").click
    end


    it "can create an Accession" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Accession").click
      $driver.clear_and_send_keys([:id, "accession_title_"], @accession_title)
      $driver.complete_4part_id("accession_id_%d_")
      $driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
      $driver.clear_and_send_keys([:id, "accession_content_description_"], "A box containing our own universe")
      $driver.clear_and_send_keys([:id, "accession_condition_description_"], "Slightly squashed")
      $driver.find_element(:css => "form#accession_form button[type='submit']").click

      assert { $driver.find_element(:css => '.record-pane h2').text.should eq("#{@accession_title} Accession") }
    end


    it "is presented an Accession edit form" do
      $driver.clear_and_send_keys([:id, 'accession_content_description_'], "Here is a description of this accession.")
      $driver.clear_and_send_keys([:id, 'accession_condition_description_'], "Here we note the condition of this accession.")
      $driver.find_element(:css => "form#accession_form button[type='submit']").click

      $driver.find_element(:link, 'Finish Editing').click

      assert { $driver.find_element(:css => 'body').text.should match(/Here is a description of this accession/) }
    end


    it "can edit an Accession but cancel the edit" do
      $driver.find_element(:link, 'Edit').click
      $driver.clear_and_send_keys([:id, 'accession_content_description_'], " moo")
      $driver.find_element(:link, "Revert Changes").click

      # Skip over Firefox's "you're navigating away" warning.
      $driver.switch_to.alert.accept

      $driver.find_element(:link, 'Finish Editing').click

      assert { $driver.find_element(:css => 'body').text.should_not match(/Here is a description of this accession. moo/) }
    end


    it "reports errors when updating an Accession with invalid data" do
      $driver.find_element(:link, 'Edit').click
      $driver.clear_and_send_keys([:id, "accession_title_"], "")
      $driver.find_element(:css => "form#accession_form button[type='submit']").click
      expect {
        $driver.find_element_with_text('//div[contains(@class, "error")]', /Title - Property is required but was missing/)
      }.to_not raise_error
      # cancel first to back out bad change
      $driver.find_element(:link, "Revert Changes").click

      # Skip over Firefox's "you're navigating away" warning.
      $driver.switch_to.alert.accept

      # cancel second to leave edit mode
      $driver.find_element(:link, 'Finish Editing').click
    end


    it "can edit an Accession and two Extents" do
      $driver.find_element(:link, 'Edit').click

      # add the first extent
      $driver.find_element(:css => '#accession_extents_ .subrecord-form-heading .btn').click

      $driver.clear_and_send_keys([:id, 'accession_extents__0__number_'], "5")
      event_type_select = $driver.find_element(:id => "accession_extents__0__extent_type_")
      event_type_select.find_elements( :tag_name => "option" ).each do |option|
        option.click if option.attribute("value") === "volumes"
      end

      # add the second extent
      $driver.find_element(:css => '#accession_extents_ .subrecord-form-heading .btn').click
      $driver.clear_and_send_keys([:id, 'accession_extents__1__number_'], "10")

      $driver.find_element(:css => "form#accession_form button[type='submit']").click

      $driver.find_element(:link, 'Finish Editing').click

      assert { $driver.find_element(:css => '.record-pane h2').text.should eq("#{@accession_title} Accession") }
    end


    it "can see two extents on the saved Accession" do
      extent_headings = $driver.blocking_find_elements(:css => '#accession_extents_ .accordion-heading')

      extent_headings.length.should eq (2)

      assert { extent_headings[0].text.should eq ("5 Volumes") }
      assert { extent_headings[1].text.should eq ("10 Cassettes") }
    end


    it "can remove an extent when editing an Accession" do
      $driver.find_element(:link, 'Edit').click
      $driver.blocking_find_elements(:css => '#accession_extents_ .subrecord-form-remove')[0].click
      $driver.find_element(:css => '#accession_extents_ .confirm-removal').click

      $driver.find_element(:css => "form#accession_form button[type='submit']").click

      $driver.find_element(:link, 'Finish Editing').click

      extent_headings = $driver.blocking_find_elements(:css => '#accession_extents_ .accordion-heading')
      extent_headings.length.should eq (1)
      assert { extent_headings[0].text.should eq ("10 Cassettes") }
    end


    it "can create an Accession with some dates" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Accession").click

      # populate mandatory fields
      $driver.clear_and_send_keys([:id, "accession_title_"], "Accession with dates")

      $driver.complete_4part_id("accession_id_%d_")

      $driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
      $driver.clear_and_send_keys([:id, "accession_content_description_"], "A box containing our own universe")
      $driver.clear_and_send_keys([:id, "accession_condition_description_"], "Slightly squashed")

      # add some dates!
      $driver.find_element(:css => '#accession_dates_ .subrecord-form-heading .btn').click
      $driver.find_element(:css => '#accession_dates_ .subrecord-form-heading .btn').click

      #populate the first date
      $driver.find_element(:id => "accession_dates__0__label_").select_option("digitized")
      $driver.clear_and_send_keys([:id, "accession_dates__0__expression_"], "The day before yesterday.")

      #populate the second date
      $driver.find_element(:id => "accession_dates__1__label_").select_option("other")
      $driver.find_element(:id => "accession_dates__1__date_type_").select_option("inclusive")
      $driver.clear_and_send_keys([:id, "accession_dates__1__begin_"], "2012-05-14")
      $driver.clear_and_send_keys([:id, "accession_dates__1__end_"], "2013-05-14")

      # save!
      $driver.find_element(:css => "form#accession_form button[type='submit']").click

      $driver.find_element(:link, 'Finish Editing').click

      # check dates
      date_headings = $driver.blocking_find_elements(:css => '#accession_dates_ .accordion-heading')
      date_headings.length.should eq (2)
    end


    it "can delete an existing date when editing an Accession" do
      $driver.find_element(:link, 'Edit').click

      # remove the first date
      $driver.find_element(:css => '#accession_dates_ .subrecord-form-remove').click
      $driver.find_element(:css => '#accession_dates_ .confirm-removal').click

      # save!
      $driver.find_element(:css => "form#accession_form button[type='submit']").click

      $driver.find_element(:link, 'Finish Editing').click

      # check remaining date
      date_headings = $driver.blocking_find_elements(:css => '#accession_dates_ .accordion-heading')
      date_headings.length.should eq (1)
    end


    it "can create an Accession with some external documents" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Accession").click

      # populate mandatory fields
      $driver.clear_and_send_keys([:id, "accession_title_"], "Accession with external documents")

      $driver.complete_4part_id("accession_id_%d_")

      $driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
      $driver.clear_and_send_keys([:id, "accession_content_description_"], "A box containing our own universe")
      $driver.clear_and_send_keys([:id, "accession_condition_description_"], "Slightly squashed")

      # add some external documents
      $driver.find_element(:css => '#accession_external_documents_ .subrecord-form-heading .btn').click
      $driver.find_element(:css => '#accession_external_documents_ .subrecord-form-heading .btn').click

      #populate the first external documents
      $driver.clear_and_send_keys([:id, "accession_external_documents__0__title_"], "My URI document")
      $driver.clear_and_send_keys([:id, "accession_external_documents__0__location_"], "http://archivesspace.org")

      #populate the second external documents
      $driver.clear_and_send_keys([:id, "accession_external_documents__1__title_"], "My other document")
      $driver.clear_and_send_keys([:id, "accession_external_documents__1__location_"], "a/file/path/or/something/")

      # save!
      $driver.find_element(:css => "form#accession_form button[type='submit']").click

      $driver.find_element(:link, 'Finish Editing').click

      # check external documents
      external_document_sections = $driver.blocking_find_elements(:css => '#accession_external_documents_ .external-document')
      external_document_sections.length.should eq (2)
      external_document_sections[0].find_element(:link => "http://archivesspace.org")
    end


    it "can delete an existing external documents when editing an Accession" do
      $driver.find_element(:link, 'Edit').click

      # remove the first external documents
      $driver.find_element(:css => '#accession_external_documents_ .subrecord-form-remove').click
      $driver.find_element(:css => '#accession_external_documents_ .confirm-removal').click

      # save!
      $driver.find_element(:css => "form#accession_form button[type='submit']").click

      $driver.find_element(:link, 'Finish Editing').click

      # check remaining external documents
      external_document_sections = $driver.blocking_find_elements(:css => '#accession_external_documents_ .external-document')
      external_document_sections.length.should eq (1)
    end


    it "can create a subject and link to an Accession" do

      me = "#{$$}.#{Time.now.to_i}"

      $driver.find_element(:link, 'Edit').click

      $driver.find_element(:css => '#accession_subjects_ .subrecord-form-heading .btn').click

      $driver.find_element(:css => '#accession_subjects_ .dropdown-toggle').click

      $driver.find_element(:css, "a.linker-create-btn").click
      $driver.clear_and_send_keys([:css, "form#new_subject .row-fluid:first-child input"], "#{me}AccessionTermABC")
      $driver.find_element(:css, "form#new_subject .row-fluid:first-child .add-term-btn").click
      $driver.clear_and_send_keys([:css, "form#new_subject .row-fluid:last-child input"], "#{me}AccessionTermDEF")
      $driver.find_element(:id, "createAndLinkButton").click

      $driver.find_element(:css => "form#accession_form button[type='submit']").click

      $driver.find_element(:link, 'Finish Editing').click

      assert { $driver.find_element(:css => "#subjects .token").text.should eq("#{me}AccessionTermABC -- #{me}AccessionTermDEF") }
    end


    it "can add a rights statement to an Accession" do
      $driver.find_element(:link, 'Edit').click

      # add a rights sub record
      $driver.find_element(:css => '#accession_rights_statements_ .subrecord-form-heading .btn').click

      $driver.find_element(:id => "accession_rights_statements__0__rights_type_").select_option("intellectual_property")
      $driver.find_element(:id => "accession_rights_statements__0__ip_status_").select_option("copyrighted")
      $driver.find_element(:id => "accession_rights_statements__0__jurisdiction_").select_option("AU")
      $driver.find_element(:id, "accession_rights_statements__0__active_").click

      # add an external document
      $driver.find_element(:css => "#accession_rights_statements__0__external_documents_ .subrecord-form-heading .btn").click
      $driver.clear_and_send_keys([:id, "accession_rights_statements__0__external_documents__0__title_"], "Agreement")
      $driver.clear_and_send_keys([:id, "accession_rights_statements__0__external_documents__0__location_"], "http://locationof.agreement.com")

      # save changes
      $driver.find_element(:css => "form#accession_form button[type='submit']").click

      $driver.find_element(:link, 'Finish Editing').click

      # check the show page
      $driver.find_element(:id, "accession_rights_statements_")
      $driver.find_element(:id, "rights_statement_0")
    end


    it "can show a browse list of Accessions" do
      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Accessions").click
      expect {
        $driver.find_element_with_text('//td', /#{@accession_title}/)
      }.to_not raise_error
    end
  end


  describe "Collection Management Records" do

    before(:all) do
      login_as_archivist
      @accession_title = create_accession("CMRs link to this accession")
      @indexer.run_index_round
    end


    after(:all) do
      logout
    end


    it "displays validation errors when saving an empty collection management record" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Collection Management Record").click

      $driver.find_element(:css => "form#new_collection_management button[type='submit']").click

      expect {
        $driver.find_element_with_text('//div[contains(@class, "error")]', /Record - Property is required/)
      }.to_not raise_error
    end


    it "creates a valid collection management record with a record link" do

      $driver.clear_and_send_keys([:id, "collection_management_cataloged_note_"], "Testing the CMR")
      $driver.clear_and_send_keys([:id, "collection_management_processing_total_extent_"], "Full")
      $driver.find_element(:id, "collection_management_processing_total_extent_type_").select_option('sheets')

      $driver.clear_and_send_keys([:css, "#collection_management_linked_records_ #token-input-collection_management_linked_records__0__ref_"], @accession_title)
      $driver.find_element(:css, "li.token-input-dropdown-item2").click

      $driver.click_and_wait_until_gone(:css => "form#new_collection_management button[type='submit']")

      # so the subject is here now
      assert {  $driver.find_element_with_text('//td', /Accession: #{@accession_title}/) }
    end
  end


  describe "Events" do

    before(:all) do
      login_as_archivist
      @accession_title = create_accession("Events link to this accession")
      @agent_name = create_agent("Geddy Lee")
      @indexer.run_index_round
    end


    after(:all) do
      logout
    end


    it "creates an event and links it to an agent and accession" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Event").click
      $driver.find_element(:id, "event_event_type_").select_option('virus check')
      $driver.clear_and_send_keys([:id, "event_outcome_"], "A good outcome")
      $driver.clear_and_send_keys([:id, "event_outcome_note_"], "OK, that's a lie: all test subjects perished.")

      $driver.find_element(:id, "event_date__date_type_").select_option("single")
      $driver.clear_and_send_keys([:id, "event_date__begin_"], ["2000-01-01", :tab])

      agent_subform = $driver.find_element(:id, "event_linked_agents__0__role_").
                              nearest_ancestor('div[contains(@class, "subrecord-form-container")]')

      $driver.find_element(:id, "event_linked_agents__0__role_").select_option('recipient')

      token_input = agent_subform.find_element(:id, "token-input-event_linked_agents__0__ref_")
      token_input.clear
      token_input.click
      token_input.send_keys("Geddy")
      $driver.find_element(:css, "li.token-input-dropdown-item2").click

      record_subform = $driver.find_element(:id, "event_linked_records__0__role_").
                               nearest_ancestor('div[contains(@class, "subrecord-form-container")]')

      token_input = record_subform.find_element(:id, "token-input-event_linked_records__0__ref_")
      token_input.clear
      token_input.click
      token_input.send_keys(@accession_title)
      $driver.find_element(:css, "li.token-input-dropdown-item2").click

      $driver.find_element(:css => "form#new_event button[type='submit']").click
    end
  end


  describe "Resources and archival object trees" do

    before(:all) do
      login_as_archivist
    end


    after(:all) do
      logout
    end


    it "reports errors and warnings when creating an invalid Resource" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Resource").click
      $driver.find_element(:id, "resource_title_").clear
      $driver.find_element(:css => "form#resource_form button[type='submit']").click

      $driver.find_element_with_text('//div[contains(@class, "error")]', /Title - Property is required but was missing/)
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Number - Property is required but was missing/)
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Language - Property is required but was missing/)

      $driver.find_element(:css, "a.btn.btn-cancel").click
    end


    resource_title = "Pony Express"

    it "can create a resource" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Resource").click

      $driver.clear_and_send_keys([:id, "resource_title_"],(resource_title))
      $driver.complete_4part_id("resource_id_%d_")
      $driver.find_element(:id, "resource_language_").select_option("eng")
      $driver.find_element(:id, "resource_level_").select_option("collection")
      $driver.clear_and_send_keys([:id, "resource_extents__0__number_"], "10")
      $driver.find_element(:css => "form#resource_form button[type='submit']").click

      # The new Resource shows up on the tree
      assert { $driver.find_element(:css => "a.jstree-clicked").text.strip.should eq(resource_title) }
    end


    it "reports warnings when updating a Resource with invalid data" do
      $driver.clear_and_send_keys([:id, "resource_title_"],"")
      $driver.find_element(:css => "form#resource_form button[type='submit']").click
      expect {
        $driver.find_element_with_text('//div[contains(@class, "error")]', /Title - Property is required but was missing/)
      }.to_not raise_error
      $driver.clear_and_send_keys([:id, "resource_title_"],(resource_title))
      $driver.find_element(:css => "form#resource_form button[type='submit']").click
    end


    it "reports errors if adding an empty child to a Resource" do
      $driver.find_element(:link, "Add Child").click
      $driver.find_element(:link, "Archival Object").click

      $driver.clear_and_send_keys([:id, "archival_object_title_"], "")

      # False start: create an object without filling it out
      $driver.click_and_wait_until_gone(:id => "createPlusOne")

      $driver.find_element_with_text('//div[contains(@class, "error")]', /Title - Property is required but was missing/)
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Level - Property is required but was missing/)
    end


    # Archival Object Trees

    it "can populate the archival object tree" do
      $driver.clear_and_send_keys([:id, "archival_object_title_"], "Lost mail")
      $driver.find_element(:id, "archival_object_level_").select_option("item")

      $driver.click_and_wait_until_gone(:id => "createPlusOne")

      ["January", "February", "December"]. each do |month|

        # Wait for the new empty form to be populated.  There's a tricky race
        # condition here that I can't quite track down, so here's my blunt
        # instrument fix.
        $driver.find_element(:xpath, "//input[@value='New Archival Object']")

        $driver.clear_and_send_keys([:id, "archival_object_title_"],(month))
        $driver.find_element(:id, "archival_object_level_").select_option("item")

        old_element = $driver.find_element(:id, "archival_object_title_")
        $driver.click_and_wait_until_gone(:id => "createPlusOne")
      end


      elements = $driver.blocking_find_elements(:css => "li.jstree-leaf").map{|li| li.text.strip}

      ["January", "February", "December"].each do |month|
        elements.any? {|elt| elt =~ /#{month}/}.should be_true
      end
    end


    it "can cancel edits to Archival Objects" do
      $driver.clear_and_send_keys([:id, "archival_object_title_"], "unimportant change")
      $driver.find_element_with_text("//div[@id='archives_tree']//a", /December/).click
      $driver.find_element(:id, "dismissChangesButton").click

      # Last added node now selected
      assert { $driver.find_element(:css => "a.jstree-clicked").text.strip.should eq('December') }
    end


    it "reports warnings when updating an Archival Object with invalid data" do
      aotitle = $driver.find_element(:css, "h2").text.sub(/ +Archival Object/, "")
      $driver.clear_and_send_keys([:id, "archival_object_title_"], "")
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
      expect {
        $driver.find_element_with_text('//div[contains(@class, "error")]', /Title - Property is required but was missing/)
      }.to_not raise_error
      $driver.clear_and_send_keys([:id, "archival_object_title_"], aotitle)
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
    end

    it "can update an existing Archival Object" do
      aotitle = $driver.find_element(:css, "h2").text.sub(/ +Archival Object/, "")
      $driver.clear_and_send_keys([:id, "archival_object_title_"], "save this please")
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
      assert { $driver.find_element(:css, "h2").text.should eq("save this please Archival Object") }
      assert { $driver.find_element(:css => "div.alert.alert-success").text.should eq('Archival Object Saved') }
      $driver.clear_and_send_keys([:id, "archival_object_title_"], aotitle)
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
    end


    it "can add a child to an existing node and assign a Subject" do
      $driver.find_element(:link, "Add Child").click
      $driver.find_element(:link, "Archival Object").click
      $driver.clear_and_send_keys([:id, "archival_object_title_"], "Christmas cards")
      $driver.find_element(:id, "archival_object_level_").select_option("item")

      $driver.find_element(:css, ".linker-wrapper a.btn").click
      $driver.find_element(:css, "a.linker-create-btn").click
      $driver.clear_and_send_keys([:css, "form#new_subject .row-fluid:first-child input"], "#{$$}TestTerm123")
      $driver.find_element(:css, "form#new_subject .row-fluid:first-child .add-term-btn").click
      $driver.clear_and_send_keys([:css, "form#new_subject .row-fluid:last-child input"], "#{$$}FooTerm456")
      $driver.find_element(:id, "createAndLinkButton").click
    end


    it "can remove the linked Subject but find it using typeahead and re-add it" do
      # remove the subject
      $driver.find_element(:css, ".token-input-delete-token").click

      # search for the created subject
      assert {
        @indexer.run_index_round
        $driver.clear_and_send_keys([:id, "token-input-archival_object_subjects_"], "#{$$}TestTerm123")
        $driver.find_element(:css, "li.token-input-dropdown-item2").click
      }

      $driver.click_and_wait_until_gone(:css, "form#archival_object_form button[type='submit']")

      # so the subject is here now
      assert { $driver.find_element(:css, "ul.token-input-list").text.should match(/#{$$}FooTerm456/) }

      # refresh the page and verify that the change really stuck
      $driver.navigate.refresh

      assert { $driver.find_element(:css, "ul.token-input-list").text.should match(/#{$$}FooTerm456/) }
    end


    it "can view a read only Archival Object" do
      $driver.find_element(:link, 'Finish Editing').click

      assert { $driver.find_element(:css, ".record-pane h2").text.should eq("Christmas cards Archival Object") }

      $driver.find_element(:link => "Edit").click
    end


    it "can support dragging and dropping an archival object" do
      # first resize the tree pane (do it incrementally so it doesn't flip out...)
      pane_resize_handle = $driver.find_element(:css => ".ui-resizable-handle.ui-resizable-s")
      10.times {
        $driver.action.drag_and_drop_by(pane_resize_handle, 0, 10).perform
      }

      source = $driver.find_element_with_text("//div[@id='archives_tree']//a", /Christmas cards/)
      target = $driver.find_element_with_text("//div[@id='archives_tree']//a", /Pony Express/)
      $driver.action.drag_and_drop(source, target).perform
      $driver.wait_for_ajax

      target = $driver.find_element_with_text("//div[@id='archives_tree']//li", /Pony Express/)
      target.find_element_with_text("./ul/li/a", /Christmas cards/)

      # refresh the page and verify that the change really stuck
      $driver.navigate.refresh

      target = $driver.find_element_with_text("//div[@id='archives_tree']//li", /Pony Express/)
      target.find_element_with_text("./ul/li/a", /Christmas cards/)
    end


    it "shows our newly added Resource in the browse list" do
      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Resources").click
      $driver.find_element_with_text('//td', /#{resource_title}/)
    end


    it "can edit a Resource and add another Extent" do
      ## Check browse list for Resources
      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Resources").click

      $driver.click_and_wait_until_gone(:link, 'Edit')

      $driver.find_element(:css => '#resource_extents_ .subrecord-form-heading .btn').click

      $driver.clear_and_send_keys([:id, 'resource_extents__1__number_'], "5")
      event_type_select = $driver.find_element(:id => "resource_extents__1__extent_type_")
      event_type_select.find_elements( :tag_name => "option" ).each do |option|
        option.click if option.attribute("value") === "volumes"
      end

      $driver.find_element(:css => "form#resource_form button[type='submit']").click

      $driver.find_element_with_text('//div', /Resource Saved/).should_not be_nil

      $driver.find_element(:link, 'Finish Editing').click
    end


    it "can see two Extents on the saved Resource" do
      extent_headings = $driver.blocking_find_elements(:css => '#resource_extents_ .accordion-heading')

      extent_headings.length.should eq (2)
      assert { extent_headings[0].text.should eq ("10 Cassettes") }
      assert { extent_headings[1].text.should eq ("5 Volumes") }
    end


    it "can remove an Extent when editing a Resource" do
      $driver.find_element(:link, 'Edit').click

      $driver.blocking_find_elements(:css => '#resource_extents_ .subrecord-form-remove')[1].click
      $driver.find_element(:css => '#resource_extents_ .confirm-removal').click
      $driver.find_element(:css => "form#resource_form button[type='submit']").click

      $driver.find_element(:link, 'Finish Editing').click

      extent_headings = $driver.blocking_find_elements(:css => '#resource_extents_ .accordion-heading')

      extent_headings.length.should eq (1)
      assert { extent_headings[0].text.should eq ("10 Cassettes") }
    end
  end


  describe "Notes" do

    before(:all) do
      login_as_archivist
    end


    after(:all) do
      logout
    end

    it "can attach notes to resources" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Resource").click

      $driver.clear_and_send_keys([:id, "resource_title_"], "a resource with notes")
      $driver.complete_4part_id("resource_id_%d_")
      $driver.find_element(:id, "resource_language_").select_option("eng")
      $driver.find_element(:id, "resource_level_").select_option("collection")
      $driver.clear_and_send_keys([:id, "resource_extents__0__number_"], "10")

      add_note = proc do |type|
        $driver.find_element(:css => '#notes .subrecord-form-heading .btn').click
        $driver.blocking_find_elements(:css => '#notes .subrecord-selector select')[0].select_option(type)
        $driver.find_element(:css => '#notes .subrecord-selector .btn').click
      end

      3.times do
        add_note.call("note_multipart")
      end

      $driver.blocking_find_elements(:css => '#notes .subrecord-form-fields').length.should eq(3)
    end


    it "confirms before removing a note entry" do
      notes = $driver.blocking_find_elements(:css => '#notes .subrecord-form-list > li')

      notes[0].find_element(:css => '.subrecord-form-remove').click

      # Get a confirmation
      $driver.find_element(:css => '.subrecord-form-removal-confirmation')

      # Now remove the second note
      notes[1].find_element(:css => '.subrecord-form-remove').click

      # Verify that the first confirmation is now gone
      $driver.find_elements(:css => '.subrecord-form-removal-confirmation').length.should be < 2

      # Confirm
      $driver.find_element(:css => '.subrecord-form-removal-confirmation .btn-primary').click

      # Take out the first note too
      notes[0].find_element(:css => '.subrecord-form-remove').click
      $driver.find_element(:css => '.subrecord-form-removal-confirmation .btn-primary').click

      # One left!
      $driver.blocking_find_elements(:css => '#notes .subrecord-form-fields').length.should eq(1)

      # Fill it out
      $driver.clear_and_send_keys([:id, 'resource_notes__2__label_'],
                                  "A multipart note")

      $driver.execute_script("$('#resource_notes__2__content_').data('CodeMirror').setValue('Some note content')")
      $driver.execute_script("$('#resource_notes__2__content_').data('CodeMirror').save()")


      # Save the resource
      $driver.find_element(:css => "form#resource_form button[type='submit']").click
      $driver.find_element(:link, 'Finish Editing').click
    end


    it "can edit an existing resource note to add subparts after saving" do
      $driver.find_element(:link, 'Edit').click

      notes = $driver.blocking_find_elements(:css => '#notes .subrecord-form-fields')

      # Add a sub note
      notes[0].find_element(:css => '.subrecord-form-heading .btn').click
      notes[0].find_element(:css => '.subrecord-selector select').select_option('note_bibliography')
      notes[0].find_element(:css => '.add-sub-note-btn').click

      $driver.find_element(:id => 'resource_notes__0__subnotes__1__label_')
      $driver.clear_and_send_keys([:id, 'resource_notes__0__subnotes__1__label_'], "Bibliography label")
      $driver.execute_script("$('#resource_notes__0__subnotes__1__content_').data('CodeMirror').setValue('Bibliography content')")
      $driver.execute_script("$('#resource_notes__0__subnotes__1__content_').data('CodeMirror').save()")

      2.times do
        notes[0].find_element(:css => '.add-item-btn').click
      end

      $driver.clear_and_send_keys([:id, 'resource_notes__0__subnotes__1__items__2_'], "Bib item 1")
      $driver.clear_and_send_keys([:id, 'resource_notes__0__subnotes__1__items__3_'], "Bib item 2")


      notes[0].find_element(:css => '.subrecord-form-heading .btn').click
      notes[0].find_element(:css => '.subrecord-selector select').select_option('note_index')
      notes[0].find_element(:css => '.add-sub-note-btn').click

      $driver.clear_and_send_keys([:id, 'resource_notes__0__subnotes__4__label_'], "Index item")
      $driver.execute_script("$('#resource_notes__0__subnotes__4__content_').data('CodeMirror').setValue('Index content')")
      $driver.execute_script("$('#resource_notes__0__subnotes__4__content_').data('CodeMirror').save()")

      2.times do
        $driver.find_element(:id => 'resource_notes__0__subnotes__4__label_').
                containing_subform.
                find_element(:css => '.add-item-btn').
                click
      end

      [5, 6]. each do |i|
        ["value", "type", "reference", "reference_text"].each do |field|
          $driver.clear_and_send_keys([:id, "resource_notes__0__subnotes__4__items__#{i}__#{field}_"],
                                      "pogo")
        end
      end

      # Save the resource
      $driver.find_element(:css => "form#resource_form button[type='submit']").click
      $driver.find_element(:link, 'Finish Editing').click

      $driver.find_element_with_text("//div", /pogo/)
    end


    it "can add a top-level bibliography too" do
      bibliography_content = "Top-level bibliography content"

      $driver.find_element(:link, 'Edit').click

      add_note_button = $driver.find_element(:css => '#notes > .subrecord-form-heading .btn').click
      $driver.find_element(:css => '#notes > .subrecord-form-heading select').select_option("note_bibliography")
      $driver.find_element(:css => '#notes > .subrecord-form-heading .subrecord-selector .btn').click

      $driver.clear_and_send_keys([:id, 'resource_notes__5__label_'], "Top-level bibliography label")
      $driver.execute_script("$('#resource_notes__5__content_').data('CodeMirror').setValue('#{bibliography_content}')")
      $driver.execute_script("$('#resource_notes__5__content_').data('CodeMirror').save()")

      $driver.execute_script("$('#resource_notes__5__content_').data('CodeMirror').toTextArea()")
      $driver.find_element(:id => "resource_notes__5__content_").attribute("value").should eq(bibliography_content)

      form = $driver.find_element(:id => 'resource_notes__5__label_').nearest_ancestor('div[contains(@class, "subrecord-form-container")]')

      2.times do
        form.find_element(:css => '.add-item-btn').click
      end

      $driver.clear_and_send_keys([:id, 'resource_notes__5__items__6_'], "Top-level bib item 1")
      $driver.clear_and_send_keys([:id, 'resource_notes__5__items__7_'], "Top-level bib item 2")

    end


    it "can wrap note content text with EAD mark up" do
      # select some text
      $driver.execute_script("$('#resource_notes__0__content_').data('CodeMirror').setValue('ABC')")
      $driver.execute_script("$('#resource_notes__0__content_').data('CodeMirror').setSelection({line: 0, ch: 0}, {line: 0, ch: 3})")

      # select a tag to wrap the text
      $driver.find_element(:css => "select.mixed-content-wrap-action").select_option("ref")
      $driver.execute_script("$('#resource_notes__0__content_').data('CodeMirror').save()")
      $driver.execute_script("$('#resource_notes__0__content_').data('CodeMirror').toTextArea()")
      $driver.find_element(:id => "resource_notes__0__content_").attribute("value").should eq("<ref>ABC</ref>")

      # Save the resource
      $driver.find_element(:css => "form#resource_form button[type='submit']").click
      $driver.find_element(:link, 'Finish Editing').click
    end


    it "can add a deaccession record" do
      $driver.find_element(:link, 'Edit').click

      $driver.find_element(:css => '#resource_deaccessions_ .subrecord-form-heading .btn').click

      $driver.find_element(:id => 'resource_deaccessions__0__date__label_').get_select_value.should eq("deaccession")

      $driver.clear_and_send_keys([:id, 'resource_deaccessions__0__description_'], "Lalala describing the deaccession")
      $driver.find_element(:css => "#resource_deaccessions__0__date__date_type_").select_option("single")
      $driver.clear_and_send_keys([:id, 'resource_deaccessions__0__date__begin_'], "2012-05-14")


      # Save the resource
      $driver.find_element(:css => "form#resource_form button[type='submit']").click
      $driver.find_element(:link, 'Finish Editing').click

      $driver.blocking_find_elements(:css => '#resource_deaccessions_').length.should eq(1)
    end


    it "can attach notes to archival objects" do
      # Create a resource
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Resource").click

      $driver.clear_and_send_keys([:id, "resource_title_"], "a resource")
      $driver.complete_4part_id("resource_id_%d_")
      $driver.find_element(:id, "resource_language_").select_option("eng")
      $driver.find_element(:id, "resource_level_").select_option("collection")
      $driver.clear_and_send_keys([:id, "resource_extents__0__number_"], "10")

      $driver.find_element(:css => "form#resource_form button[type='submit']").click

      # Give it a child AO
      $driver.find_element(:link, "Add Child").click
      $driver.find_element(:link, "Archival Object").click
      $driver.clear_and_send_keys([:id, "archival_object_title_"], "An Archival Object with notes")
      $driver.find_element(:id, "archival_object_level_").select_option("item")


      # Add some notes to it
      add_note = proc do |type|
        $driver.find_element(:css => '#notes .subrecord-form-heading .btn').click
        $driver.blocking_find_elements(:css => '#notes .subrecord-selector select')[0].select_option(type)
        $driver.find_element(:css => '#notes .subrecord-selector .btn').click
      end

      3.times do
        add_note.call("note_multipart")
      end

      $driver.blocking_find_elements(:css => '#notes .subrecord-form-fields').length.should eq(3)

      $driver.find_element(:link, "Revert Changes").click

      # Skip over Firefox's "you're navigating away" warning.
      $driver.switch_to.alert.accept
    end


    it "can attach special notes to digital objects" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Digital Object").click

      $driver.clear_and_send_keys([:id, "digital_object_title_"], "A digital object with notes")
      $driver.clear_and_send_keys([:id, "digital_object_digital_object_id_"],(Digest::MD5.hexdigest("#{Time.now}")))

      # Add a Summary note
      $driver.find_element(:css => '#notes .subrecord-form-heading .btn').click
      select = $driver.blocking_find_elements(:css => '#notes .subrecord-selector select')[0]
      select.find_elements(:tag_name => "option").each do |option|
        if option.text == "Summary"
          option.click
          break
        end
      end
      $driver.find_element(:css => '#notes .subrecord-selector .btn').click

      $driver.clear_and_send_keys([:id, 'digital_object_notes__0__label_'], "Summary label")
      $driver.execute_script("$('#digital_object_notes__0__content_').data('CodeMirror').setValue('Summary content')")
      $driver.execute_script("$('#digital_object_notes__0__content_').data('CodeMirror').save()")

      $driver.execute_script("$('#digital_object_notes__0__content_').data('CodeMirror').toTextArea()")
      $driver.find_element(:id => "digital_object_notes__0__content_").attribute("value").should eq("Summary content")

      $driver.find_element(:css => "form#new_digital_object button[type='submit']").click
    end

  end


  describe "Digital Objects" do

    before(:all) do
      login_as_archivist
    end


    after(:all) do
      logout
    end


    it "reports errors and warnings when creating an invalid Digital Object" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Digital Object").click
      $driver.find_element(:id, "digital_object_title_").clear
      $driver.find_element(:css => "form#new_digital_object button[type='submit']").click

      $driver.find_element_with_text('//div[contains(@class, "error")]', /Identifier - Property is required but was missing/)

      $driver.find_element(:css, "a.btn.btn-cancel").click
    end


    digital_object_title = "Pony Express Digital Image"

    it "can create a digital_object" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Digital Object").click

      $driver.clear_and_send_keys([:id, "digital_object_title_"],(digital_object_title))
      $driver.clear_and_send_keys([:id, "digital_object_digital_object_id_"],(Digest::MD5.hexdigest("#{Time.now}")))

      $driver.find_element(:css => "form#new_digital_object button[type='submit']").click

      # The new Digital Object shows up on the tree
      assert { $driver.find_element(:css => "a.jstree-clicked").text.strip.should eq(digital_object_title) }
    end


    it "reports errors if adding an empty child to a Digital Object" do
      $driver.find_element(:link, "Add Child").click
      $driver.find_element(:link, "Digital Object Component").click

      # False start: create an object without filling it out
      $driver.click_and_wait_until_gone(:id => "createPlusOne")

      $driver.find_element_with_text('//div[contains(@class, "error")]', /Identifier - Property is required but was missing/)
    end


    # Digital Object Component Nodes in Tree

    it "can populate the archival object tree" do
      $driver.clear_and_send_keys([:id, "digital_object_component_title_"], "JPEG 2000 Verson of Image")
      $driver.clear_and_send_keys([:id, "digital_object_component_component_id_"],(Digest::MD5.hexdigest("#{Time.now}")))

      $driver.click_and_wait_until_gone(:id => "createPlusOne")

      ["PNG format", "GIF format", "BMP format"].each_with_index do |thing, idx|

        # Wait for the new empty form to be populated.  There's a tricky race
        # condition here that I can't quite track down, so here's my blunt
        # instrument fix.
        $driver.find_element(:xpath, "//input[@value='New Digital Object Component']")

        $driver.clear_and_send_keys([:id, "digital_object_component_title_"],(thing))
        $driver.clear_and_send_keys([:id, "digital_object_component_label_"],(thing))
        $driver.clear_and_send_keys([:id, "digital_object_component_component_id_"],(Digest::MD5.hexdigest("#{thing}#{Time.now}")))

        if idx < 2
          $driver.click_and_wait_until_gone(:id => "createPlusOne")
        else
          $driver.find_element(:css => "form#new_digital_object_component button[type='submit']").click
        end
      end


      elements = $driver.blocking_find_elements(:css => "li.jstree-leaf").map{|li| li.text.strip}

      ["PNG format", "GIF format", "BMP format"].each do |thing|
        elements.any? {|elt| elt =~ /#{thing}/}.should be_true
      end

    end

    it "can drag and drop reorder a Digital Object" do
      # create grand child
      $driver.find_element(:link, "Add Child").click
      $driver.find_element(:link, "Digital Object Component").click

      $driver.clear_and_send_keys([:id, "digital_object_component_title_"], "ICO")
      $driver.clear_and_send_keys([:id, "digital_object_component_component_id_"],(Digest::MD5.hexdigest("#{Time.now}")))
      $driver.click_and_wait_until_gone(:css => "form#new_digital_object_component button[type='submit']")

      # first resize the tree pane (do it incrementally so it doesn't flip out...)
      pane_resize_handle = $driver.find_element(:css => ".ui-resizable-handle.ui-resizable-s")
      10.times {
        $driver.action.drag_and_drop_by(pane_resize_handle, 0, 10).perform
      }

      #drag to become sibling of parent
      source = $driver.find_element_with_text("//div[@id='archives_tree']//a", /ICO/)
      target = $driver.find_element_with_text("//div[@id='archives_tree']//a", /Pony Express Digital Image/)
      $driver.action.drag_and_drop(source, target).perform
      $driver.wait_for_ajax

      target = $driver.find_element_with_text("//div[@id='archives_tree']//li", /Pony Express Digital Image/)
      target.find_element_with_text("./ul/li/a", /ICO/)

      # refresh the page and verify that the change really stuck
      $driver.navigate.refresh

      target = $driver.find_element_with_text("//div[@id='archives_tree']//li", /Pony Express Digital Image/)
      target.find_element_with_text("./ul/li/a", /ICO/)
    end
  end

  # Chopped out for now because I got another failure when the session expired halfway through.

  # I think we can work around this by creating a non-expiring session for
  # Selenium to run its regular tests, followed by a very short expiry for
  # running this specific test.

  # it "expires a session after a nap" do
  #   sleep $expire + 1
  #   $driver.find_element(:link => 'Browse').click
  #   $driver.find_element(:link => 'Subjects').click

  #   $driver.find_element(:css => "div.alert.alert-error").text.should eq('Your session expired due to inactivity. Please sign in again.')

  #   $driver.find_element(:link, "Sign In").click
  #   $driver.clear_and_send_keys([:id, 'user_username'], @user)
  #   $driver.clear_and_send_keys([:id, 'user_password'], "testuser")
  #   $driver.find_element(:id, 'login').click
  # end

  describe "User management" do

    before(:all) do
      login("admin", "admin")
      
      (@user, @pass) = create_user
    end

    after(:all) do
      logout
    end

    it "can create a user account" do
      $driver.find_element(:css, '.repository-container .btn').click
      $driver.find_element(:link, "Manage Users").click
      
      $driver.find_element(:link, "Create User").click
      
      $driver.clear_and_send_keys([:id, "user_username_"], @user)
      $driver.clear_and_send_keys([:id, "user_name_"], @user)
      $driver.clear_and_send_keys([:id, "user_password_"], @pass)
      $driver.clear_and_send_keys([:id, "user_confirm_password_"], @pass)
      
      $driver.find_element(:id, 'create_account').click
    end
  end


  describe "Users and authentication" do

    after(:all) do
      logout
    end


    it "fails logins with invalid credentials" do
      login("oopsie", "daisies")

      assert { $driver.find_element(:css => "p.help-inline.login-message").text.should eq('Login attempt failed') }

      $driver.find_element(:link, "Sign In").click
    end


    it "can register a new user" do
      $driver.find_element(:link, "Sign In").click
      $driver.find_element(:link, "Register now").click

      $driver.clear_and_send_keys([:id, "user_username_"], @user)
      $driver.clear_and_send_keys([:id, "user_name_"], @user)
      $driver.clear_and_send_keys([:id, "user_password_"], "testuser")
      $driver.clear_and_send_keys([:id, "user_confirm_password_"], "testuser")

      $driver.find_element(:id, 'create_account').click

      assert { $driver.find_element(:css => "span.user-label").text.should match(/#{@user}/) }
    end


    it "but they have no repositories yet!" do
      $driver.find_element(:css, '.repository-container .btn').click
      assert { $driver.find_element(:css, '.repository-container .dropdown-menu').text.should match(/No repositories/) }
    end

  end

end
