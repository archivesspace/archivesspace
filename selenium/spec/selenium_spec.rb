require_relative 'spec_helper'
require_relative '../../indexer/app/lib/realtime_indexer'
require_relative '../../indexer/app/lib/periodic_indexer'



describe "ArchivesSpace user interface" do

  # Start the dev servers and Selenium
  before(:all) do
    selenium_init($backend_start_fn, $frontend_start_fn)
    @indexer = RealtimeIndexer.new($backend, nil)
    @period = PeriodicIndexer.new
  end


  def run_index_round
    @last_sequence ||= 0
    @last_sequence = @indexer.run_index_round(@last_sequence)
  end

  def run_periodic_index
    @period.run_index_round
  end

  def run_all_indexers
    run_index_round
    run_periodic_index
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
      SeleniumTest.save_screenshot
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
      $driver.find_element(:link, 'System').click
      $driver.find_element(:link, "Manage Repositories").click
      $driver.find_element(:link, "Create Repository").click
      $driver.clear_and_send_keys([:id, "repository_repository__name_"], "missing repo code")
      $driver.find_element(:css => "form#new_repository button[type='submit']").click

      assert(5) { $driver.find_element(:css => "div.alert.alert-danger").text.should eq('Repository Short Name - Property is required but was missing') }
    end


    it "can create a repository" do
      $driver.clear_and_send_keys([:id, "repository_repository__repo_code_"], @test_repo_code_1)
      $driver.clear_and_send_keys([:id, "repository_repository__name_"], @test_repo_name_1)
      $driver.find_element(:css => "form#new_repository button[type='submit']").click
    end


    it "can create a second repository" do
      $driver.find_element(:link, "Repositories").click
      $driver.find_element(:link, "Create Repository").click
      $driver.clear_and_send_keys([:id, "repository_repository__repo_code_"], @test_repo_code_2)
      $driver.clear_and_send_keys([:id, "repository_repository__name_"], @test_repo_name_2)
      $driver.find_element(:css => "form#new_repository button[type='submit']").click
    end


    it "can select either of the created repositories" do
      $driver.find_element(:link, 'Select Repository').click
      $driver.find_element(:css, '.select-a-repository').find_element(:id => "id").select_option_with_text(@test_repo_code_2)
      $driver.find_element(:css, '.select-a-repository .btn-primary').click
      assert(5) { $driver.find_element(:css, 'span.current-repository-id').text.should eq @test_repo_code_2 }

      $driver.find_element(:link, 'Select Repository').click
      $driver.find_element(:css, '.select-a-repository select').find_element(:id => "id").select_option_with_text(@test_repo_code_1)
      $driver.find_element(:css, '.select-a-repository .btn-primary').click
      assert(5) { $driver.find_element(:css, 'span.current-repository-id').text.should eq @test_repo_code_1 }

      $driver.find_element(:link, 'Select Repository').click
      $driver.find_element(:css, '.select-a-repository select').find_element(:id => "id").select_option_with_text(@test_repo_code_2)
      $driver.find_element(:css, '.select-a-repository .btn-primary').click
      assert(5) { $driver.find_element(:css, 'span.current-repository-id').text.should eq @test_repo_code_2 }
    end

    it "will persist repository selection" do
      assert(5) { $driver.find_element(:css, 'span.current-repository-id').text.should eq @test_repo_code_2 }
    end

    it "automatically refreshes the repository list when a new repo gets added" do
      new_repo_code = "notificationtest1#{Time.now.to_i}_#{$$}"
      new_repo_name = "notification test repository - #{Time.now}"

      create_test_repo(new_repo_code, new_repo_name)

      $driver.navigate.refresh

      $driver.find_element(:link, 'Select Repository').click
      assert(5) { $driver.find_element(:css, '.select-a-repository').select_option_with_text(new_repo_code) }
    end


    it "paginates the list when more than a page of repositories" do
      AppConfig[:default_page_size].to_i.times.each do |i|
        create_test_repo("quickrepofortesting#{i}_#{Time.now.to_i}_#{$$}",
                         "quickrepofortesting#{i}_#{Time.now.to_i}_#{$$}",
                         false)
      end

      run_index_round

      $driver.find_element(:link, 'System').click
      $driver.find_element(:link, "Manage Repositories").click

      $driver.find_element(:css, '.pagination .active a').text.should eq('1')

      $driver.find_element(:link, '2').click
      $driver.find_element(:css, '.pagination .active a').text.should eq('2')

      $driver.find_element(:link, '1').click
      $driver.find_element(:css, '.pagination .active a').text.should eq('1')
      $driver.find_element(:link, '2')
    end

  end


  describe "Groups" do

    before(:all) do
      @can_manage_repo = "group_manage#{Time.now.to_i}_#{$$}"
      @can_view_repo = "group_view#{Time.now.to_i}_#{$$}"

      (@user, @pass) = create_user

      create_test_repo(@can_manage_repo, "manage", false)
      create_test_repo(@can_view_repo, "view", false)
      # wait for notification to fire (which can take up to 5 seconds)
      sleep 5
      login("admin", "admin")
    end


    after(:all) do
      logout
    end


    it "can assign a user to the archivist group" do
      select_repo(@can_manage_repo)

      $driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
      $driver.find_element(:link, "Manage Groups").click

      row = $driver.find_element_with_text('//tr', /repository-archivists/)
      row.find_element(:link, 'Edit').click

      $driver.clear_and_send_keys([:id, 'new-member'],(@user))
      $driver.find_element(:id, 'add-new-member').click
      $driver.find_element(:css => 'button[type="submit"]').click
    end


    it "can assign the test user to the viewers group of the first repository" do
      select_repo(@can_view_repo)

      $driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
      $driver.find_element(:link, "Manage Groups").click

      row = $driver.find_element_with_text('//tr', /repository-viewers/)
      row.find_element(:css, '.btn').click

      $driver.clear_and_send_keys([:id, 'new-member'],(@user))
      $driver.find_element(:id, 'add-new-member').click
      $driver.find_element(:css => 'button[type="submit"]').click
    end


    it "reports errors when attempting to create a Group with missing data" do
      $driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
      $driver.find_element(:link, "Manage Groups").click
      $driver.find_element(:link, "Create Group").click
      $driver.find_element(:css => "form#new_group button[type='submit']").click
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
      $driver.find_element(:css => "form#new_group button[type='submit']").click


      expect {
        $driver.find_element_with_text('//tr', /goo/)
      }.to_not raise_error
    end


    it "reports errors when attempting to update a Group with missing data" do
      $driver.find_element_with_text('//tr', /goo/).find_element(:link, "Edit").click
      $driver.clear_and_send_keys([:id, 'group_description_'], "")
      $driver.find_element(:css => "form#new_group button[type='submit']").click
      expect {
        $driver.find_element_with_text('//div[contains(@class, "error")]', /Description - Property is required but was missing/)
      }.to_not raise_error
      $driver.find_element(:link, "Cancel").click
    end


    it "can edit a Group" do
      $driver.find_element_with_text('//tr', /goo/).find_element(:link, "Edit").click
      $driver.clear_and_send_keys([:id, 'group_description_'], "Group to gather goo")
      $driver.find_element(:css => "form#new_group button[type='submit']").click
      expect {
        $driver.find_element_with_text('//tr', /Group to gather goo/)
      }.to_not raise_error
    end


    it "can get a list of usernames matching a string" do
      $driver.get(URI.join($frontend, "/users/complete?query=#{URI.escape(@user)}"))
      $driver.page_source.should match(/#{@user}/)
      $driver.get(URI.join($frontend))
    end

    it "can log out of the admin account" do
      logout
    end


    it "can log in with the user just created" do
      $driver.find_element(:link, "Sign In").click
      $driver.clear_and_send_keys([:id, 'user_username'], @user)
      $driver.clear_and_send_keys([:id, 'user_password'], @pass)
      $driver.find_element(:id, 'login').click

      assert(5) { $driver.find_element(:css => "span.user-label").text.should match(/#{@user}/) }
    end


    it "can select the second repository and find the create link" do
      select_repo(@can_manage_repo)

      # Wait until it's selected
      $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /#{@can_manage_repo}/)
      $driver.find_element(:link, "Create")
    end


    it "can modify the user's groups for a repository via the Manage Access listing" do
      logout
      login("admin", "admin")

      # change @can_manage_repo to a view only
      select_repo(@can_manage_repo)

      $driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
      $driver.find_element(:link, "Manage User Access").click

      while true
        # Wait for the table to load
        $driver.find_element(:link, "Edit Groups")

        user_row = $driver.find_element_with_text('//tr', /#{@user}/, true, true)

        if user_row
          user_row.find_element(:link, "Edit Groups").click
          break
        end

        # Try the next page of users
        nextpage = $driver.find_elements(:xpath, '//a[@title="Next"]')
        if nextpage[0]
          nextpage[0].click
        else
          break
        end
      end

      # Wait for the form to load
      $driver.find_element(:id, "create_account")

      # uncheck all current groups
      $driver.find_elements(:xpath, '//input[@type="checkbox"][@checked]').each {|checkbox| checkbox.click}

      # check only the viewer group
      $driver.find_element_with_text('//tr', /repository-viewers/).find_element(:css, 'input').click

      $driver.find_element(:id, "create_account").click

      logout
    end

    it "can be modified via the Manage Access listing and then stick" do
      $driver.find_element(:link, "Sign In").click
      $driver.clear_and_send_keys([:id, 'user_username'], @user)
      $driver.clear_and_send_keys([:id, 'user_password'], @pass)
      $driver.find_element(:id, 'login').click

      select_repo(@can_manage_repo)

      assert(100) {
        $driver.ensure_no_such_element(:link, "Create")
      }
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

      $driver.find_element(:css => '#subject_external_documents_ .subrecord-form-heading .btn:not(.show-all)').click

      $driver.find_element(:css => '#subject_terms_ .subrecord-form-remove').click
      $driver.find_element(:css => '#subject_terms_ .confirm-removal').click

      $driver.find_element(:css => "form .record-pane button[type='submit']").click

      # check messages
      expect {
        $driver.find_element_with_text('//div[contains(@class, "error")]', /Terms - At least 1 item\(s\) is required/)
      }.to_not raise_error
    end


    it "can create a new Subject" do
      now = "#{$$}.#{Time.now.to_i}"

      $driver.find_element(:link => 'Create').click
      $driver.find_element(:link => 'Subject').click
      $driver.find_element(:css => "form #subject_terms_ button:not(.show-all)").click 
      
      $driver.find_element(:id => "subject_source_").select_option("local")
      
      
      $driver.clear_and_send_keys([:id, "subject_terms__0__term_"], "just a term really #{now}")
      $driver.clear_and_send_keys([:id, "subject_terms__1__term_"], "really")
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
      assert(5) { $driver.find_element(:css => '.record-pane h2').text.should eq("just a term really #{now} -- really Subject") }
    end

    it "can reorder the terms and have them maintain order" do

      first = SecureRandom.hex
      second = SecureRandom.hex

      $driver.find_element(:link => 'Create').click
      $driver.find_element(:link => 'Subject').click
      $driver.find_element(:css => "form #subject_terms_ button:not(.show-all)").click 
      $driver.find_element(:id => "subject_source_").select_option("local")
      $driver.clear_and_send_keys([:id, "subject_terms__0__term_"], first)
      $driver.clear_and_send_keys([:id, "subject_terms__1__term_"], second)
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
      assert(5) { $driver.find_element(:css => '.record-pane h2').text.should eq("#{first} -- #{second} Subject") }
      
      #drag to become sibling of parent
      source = $driver.find_element( :css => "#subject_terms__1_ .drag-handle" )
      
      $driver.action.drag_and_drop_by(source, 0, -100).perform
      $driver.wait_for_ajax
      $driver.find_element(:css => "form .record-pane button[type='submit']").click

      assert(5) { $driver.find_element(:css => '.record-pane h2').text.should eq("#{second} -- #{first} Subject") }

      # refresh the page and verify that the change really stuck
      $driver.navigate.refresh
      target = $driver.find_element( :css => "#subject_terms__0__term_" ).attribute('value').should eq(second)
      target = $driver.find_element( :css => "#subject_terms__1__term_" ).attribute('value').should eq(first)

    end

    it "can present a browse list of Subjects" do
      run_index_round

      $driver.find_element(:link => 'Browse').click
      $driver.find_element(:link => 'Subjects').click

      expect {
        $driver.find_element_with_text('//tr', /just a term really/)
      }.to_not raise_error
    end

    it "can use plus+1 submit to quickly add another" do
      now = "#{$$}.#{Time.now.to_i}"

      $driver.find_element(:link => 'Create').click
      $driver.find_element(:link => 'Subject').click

      $driver.clear_and_send_keys([:id, "subject_terms__0__term_"], "My First New Term #{now}")
      $driver.find_element(:id => "subject_source_").select_option("local")
      $driver.find_element(:css => "form #createPlusOne").click

      $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Subject Created/)
      $driver.find_element(:id, "subject_terms__0__term_").attribute("value").should eq("")
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
      $driver.find_element(:link, 'Agent').click
      $driver.find_element(:link, 'Person').click
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Primary Part of Name - Property is required but was missing/)
    end


    it "reports an error when neither Source nor Rules is provided" do
      $driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], "Hendrix")

      $driver.find_element(:css => "form .record-pane button[type='submit']").click

      $driver.find_element_with_text('//div[contains(@class, "error")]', /Source - is required/)
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Rules - is required/)
    end


    it "reports a warning when Authority ID is provided without a Source" do
      $driver.clear_and_send_keys([:id, "agent_names__0__authority_id_"], SecureRandom.hex )
      $driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], "Hendrix")

      rules_select = $driver.find_element(:id => "agent_names__0__rules_")
      rules_select.select_option("local")

      $driver.find_element(:css => "form .record-pane button[type='submit']").click
      $driver.find_element_with_text('//div[contains(@class, "warning")]', /^Source - is required if there is an 'authority id'$/i)
    end


    it "auto generates Sort Name when other name fields upon save" do
      $driver.find_element(:id => "agent_names__0__source_").select_option("local")

      $driver.clear_and_send_keys([:id, "agent_names__0__authority_id_"], SecureRandom.hex)
      $driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], "Hendrix")

      $driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

      $driver.find_element_with_text('//h2', /Hendrix/)

      $driver.clear_and_send_keys([:id, "agent_names__0__rest_of_name_"], "Johnny Allen")

      $driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

      $driver.find_element_with_text('//h2', /Hendrix, Johnny Allen/)
    end


    it "changing Direct Order updates Sort Name" do
      $driver.find_element(:id => "agent_names__0__name_order_").select_option("direct")

      $driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

      $driver.find_element_with_text('//h2', /Johnny Allen Hendrix/)
    end


    it "throws an error if no sort name is provided and auto gen is false" do
      $driver.find_element(:id, "agent_names__0__sort_name_auto_generate_").click
      $driver.clear_and_send_keys([:id, "agent_names__0__sort_name_"], "")
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Sort Name - Property is required but was missing/)
    end


    it "allows setting of a custom sort name" do
      $driver.clear_and_send_keys([:id, "agent_names__0__sort_name_"], "My Custom Sort Name")
      $driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

      $driver.find_element_with_text('//h2', /My Custom Sort Name/)
    end


    it "can add a secondary name and validations match index of name form" do
      $driver.find_element(:css => '#agent_person_names .subrecord-form-heading .btn:not(.show-all)').click
      $driver.find_element(:css => "form .record-pane button[type='submit']").click

      $driver.find_element_with_text('//div[contains(@class, "error")]', /Primary Part of Name - Property is required but was missing/)

      $driver.clear_and_send_keys([:id, "agent_names__1__primary_name_"], "Hendrix")
      $driver.clear_and_send_keys([:id, "agent_names__1__rest_of_name_"], "Jimi")

    end


    it "can save a person and view readonly view of person" do
      $driver.find_element(:css => '#agent_person_contact_details .subrecord-form-heading .btn:not(.show-all)').click

      $driver.clear_and_send_keys([:id, "agent_agent_contacts__0__name_"], "Email Address")
      $driver.clear_and_send_keys([:id, "agent_agent_contacts__0__email_"], "jimi@rocknrollheaven.com")

      $driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

      assert(5) { $driver.find_element(:css => '.record-pane h2').text.should eq("My Custom Sort Name Agent") }
    end


    it "reports errors when updating a Person Agent with invalid data" do
      $driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], "")
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Primary Part of Name - Property is required but was missing/)
      $driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], "Hendrix")
    end


    it "can add a related agent" do
      agent_uri, agent_name = create_agent("Linked Agent #{$$}.#{Time.now.to_i}")
      run_index_round

      $driver.find_element(:css => '#agent_person_related_agents .subrecord-form-heading .btn:not(.show-all)').click
      $driver.find_element(:css => "select.related-agent-type").select_option("agent_relationship_associative")

      token_input = $driver.find_element(:id, "token-input-agent_related_agents__1__ref_")
      token_input.clear
      token_input.click
      token_input.send_keys(agent_name)
      $driver.find_element(:css, "li.token-input-dropdown-item2").click

      $driver.find_element(:css => "form .record-pane button[type='submit']").click

      $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Agent Saved/)
      assert(5) { $driver.find_element(:css, "#agent_person_related_agents ul.token-input-list").text.should match(/#{agent_name}/) }
    end


    it "can remove contact details" do
      $driver.find_element(:css => '#agent_person_contact_details .subrecord-form-remove').click
      $driver.find_element(:css => '#agent_person_contact_details .confirm-removal').click

      assert(5) {
        $driver.ensure_no_such_element(:id => "agent_agent_contacts__0__name_")
      }

      $driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

      $driver.ensure_no_such_element(:id => "#agent_agent_contacts__0__name_")
    end


    it "can add an external document to an Agent" do
      $driver.find_element(:css => '#agent_person_external_documents .subrecord-form-heading .btn:not(.show-all)').click

      $driver.clear_and_send_keys([:id, "agent_external_documents__0__title_"], "My URI document")
      $driver.clear_and_send_keys([:id, "agent_external_documents__0__location_"], "http://archivesspace.org")

      $driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

      $driver.click_and_wait_until_gone(:link => "My Custom Sort Name")

      # check external documents
      external_document_sections = $driver.blocking_find_elements(:css => '#agent_person_external_documents .external-document')
      external_document_sections.length.should eq (1)
      external_document_sections[0].find_element(:link => "http://archivesspace.org")
    end


    it "can add a date of existence to an Agent" do
      $driver.click_and_wait_until_gone(:link, 'Edit')
      $driver.find_element(:css => '#agent_person_dates_of_existence .subrecord-form-heading .btn:not(.show-all)').click

      $driver.find_element(:id => "agent_dates_of_existence__0__date_type_").select_option("single")
      $driver.clear_and_send_keys([:id, "agent_dates_of_existence__0__expression_"], "1973")

      $driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

      $driver.click_and_wait_until_gone(:link => "My Custom Sort Name")

      # check for date expression
      $driver.find_element_with_text('//div', /1973/)
      end


    it "can add a Biog/Hist note to an Agent" do
      $driver.click_and_wait_until_gone(:link, 'Edit')
      $driver.find_element(:css => '#agent_person_notes .subrecord-form-heading .btn:not(.show-all)').click
      $driver.blocking_find_elements(:css => '#agent_person_notes .top-level-note-type')[0].select_option("note_bioghist")

      # ensure note form displayed
      $driver.find_element(:id, "agent_notes__0__label_")

      biog = "Jimi was an American musician and songwriter; and one of the most influential electric guitarists in the history of popular music."
      $driver.execute_script("$('#agent_notes__0__subnotes__0__content_').data('CodeMirror').setValue('#{biog}')")
      $driver.execute_script("$('#agent_notes__0__subnotes__0__content_').data('CodeMirror').save()")

      $driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

      $driver.click_and_wait_until_gone(:link => "My Custom Sort Name")

      # check the readonly view
      $driver.find_element_with_text('//div[contains(@class, "subrecord-form-fields")]', /#{biog}/)
    end


    it "can add a sub note" do
      $driver.click_and_wait_until_gone(:link, 'Edit')

      notes = $driver.blocking_find_elements(:css => '#agent_person_notes .subrecord-form-fields')

      # Expand the collapsed note
      notes[0].find_element(:css => '.collapse-subrecord-toggle').click

      # Add a sub note
      assert(5) { notes[0].find_element(:css => '.subrecord-form-heading .btn:not(.show-all)').click }
      notes[0].find_element(:css => 'select.bioghist-note-type').select_option('note_outline')

      # ensure sub note form displayed
      $driver.find_element(:id, "agent_notes__0__subnotes__2__publish_")

      notes[0].find_element(:css => ".add-level-btn").click
      notes[0].find_element(:css => ".add-sub-item-btn").click
      notes[0].find_element(:css => ".add-sub-item-btn").click

      $driver.clear_and_send_keys([:id, "agent_notes__0__subnotes__2__levels__3__items__4_"], "Woodstock")
      $driver.clear_and_send_keys([:id, "agent_notes__0__subnotes__2__levels__3__items__5_"], "Discography")
      $driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

      # check the readonly view
      $driver.click_and_wait_until_gone(:link => "My Custom Sort Name")
      $driver.find_element_with_text('//div[contains(@class, "subrecord-form-inline")]', /Woodstock/)
      $driver.find_element_with_text('//div[contains(@class, "subrecord-form-inline")]', /Discography/)
    end


    it "displays the agent in the agent's index page" do
      run_index_round

      $driver.get(URI.join($frontend, "/agents?&sort=create_time+desc"))

      expect {
        $driver.find_element_with_text('//td', /My Custom Sort Name/)
      }.to_not raise_error
    end


    it "returns agents in search results and shows their types correctly" do
      run_index_round

      $driver.clear_and_send_keys([:id, "global-search-box"], "Hendrix")
      $driver.find_element(:id => 'global-search-button').click

      $driver.find_element_with_text('//td', /My Custom Sort Name/)
      $driver.find_element_with_text('//td', /Person/)
    end
  end


  describe "Accessions" do

    before(:all) do
      login_as_archivist
      @accession_title = "Exciting new stuff - \u2603"
      @me = "#{$$}.#{Time.now.to_i}"

      @shared_4partid = $driver.generate_4part_id

      @dates_accession_title = "Accession with dates"
      @dates_4partid = $driver.generate_4part_id

      @exdocs_accession_title = "Accession with external docs"
      @exdocs_4partid = $driver.generate_4part_id
    end


    after(:all) do
      logout
    end


    it "can spawn an accession from an existing accession" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Accession").click

      $driver.clear_and_send_keys([:id, "accession_title_"], "Charles Darwin's paperclip collection")
      $driver.complete_4part_id("accession_id_%d_")
      $driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
      $driver.clear_and_send_keys([:id, "accession_content_description_"], "Lots of paperclips")
      $driver.clear_and_send_keys([:id, "accession_condition_description_"], "pristine")

      # add a date
      $driver.find_element(:css => '#accession_dates_ .subrecord-form-heading .btn:not(.show-all)').click
      $driver.find_element(:id => "accession_dates__0__label_").select_option("digitized")
      $driver.find_element(:id => "accession_dates__0__date_type_").select_option("single")
      $driver.clear_and_send_keys([:id, "accession_dates__0__expression_"], "The day before yesterday.")

      # add a rights subrecord
      $driver.find_element(:css => '#accession_rights_statements_ .subrecord-form-heading .btn:not(.show-all)').click
      $driver.find_element(:id => "accession_rights_statements__0__rights_type_").select_option("intellectual_property")
      $driver.find_element(:id => "accession_rights_statements__0__ip_status_").select_option("copyrighted")
      combo = $driver.find_element(:xpath => '//div[@class="combobox-container"][following-sibling::select/@id="accession_rights_statements__0__jurisdiction_"]//input[@type="text"]');
      combo.clear
      combo.click
      combo.send_keys("AU")
      combo.send_keys(:tab)

      # $driver.clear_and_send_keys([:id => "accession_rights_statements__0__jurisdiction__combobox"], ["AU", :return])
      $driver.find_element(:id, "accession_rights_statements__0__active_").click

      # add an external document
      $driver.find_element(:css => "#accession_rights_statements__0__external_documents_ .subrecord-form-heading .btn:not(.show-all)").click
      $driver.clear_and_send_keys([:id, "accession_rights_statements__0__external_documents__0__title_"], "Agreement")
      $driver.clear_and_send_keys([:id, "accession_rights_statements__0__external_documents__0__location_"], "http://locationof.agreement.com")

      # save
      $driver.find_element(:css => "form#accession_form button[type='submit']").click

      # Spawn an accession from the accession we just created
      $driver.find_element(:link, "Spawn").click
      $driver.find_element(:link, "Accession").click

      $driver.clear_and_send_keys([:id, "accession_title_"], "Charles Darwin's second paperclip collection")
      $driver.complete_4part_id("accession_id_%d_")

      $driver.find_element(:css => "form#accession_form button[type='submit']").click

      # Success!
      assert(5) {
        $driver.find_element_with_text('//div', /Accession Charles Darwin's second paperclip collection created/).should_not be_nil
      }

      $driver.click_and_wait_until_gone(:link => "Charles Darwin's second paperclip collection")

      # date should have come across
      date_headings = $driver.blocking_find_elements(:css => '#accession_dates_ .panel-heading')
      date_headings.length.should eq (1)

      # rights and external doc shouldn't
      $driver.ensure_no_such_element(:id, "accession_rights_statements_")
      $driver.ensure_no_such_element(:id, "accession_external_documents_")
    end


    it "can create an Accession" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Accession").click
      $driver.clear_and_send_keys([:id, "accession_title_"], @accession_title)
      $driver.complete_4part_id("accession_id_%d_", @shared_4partid)
      $driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
      $driver.clear_and_send_keys([:id, "accession_content_description_"], "A box containing our own universe")
      $driver.clear_and_send_keys([:id, "accession_condition_description_"], "Slightly squashed")
      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      $driver.click_and_wait_until_gone(:link => @accession_title)

      assert(5) { $driver.find_element(:css => '.record-pane h2').text.should eq("#{@accession_title} Accession") }
    end


    it "is presented an Accession edit form" do
      $driver.click_and_wait_until_gone(:link, 'Edit')
      $driver.clear_and_send_keys([:id, 'accession_content_description_'], "Here is a description of this accession.")
      $driver.clear_and_send_keys([:id, 'accession_condition_description_'], "Here we note the condition of this accession.")
      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      $driver.click_and_wait_until_gone(:link => @accession_title)

      assert(5) { $driver.find_element(:css => 'body').text.should match(/Here is a description of this accession/) }
    end


    it "reports errors when updating an Accession with invalid data" do
      $driver.click_and_wait_until_gone(:link, 'Edit')
      $driver.clear_and_send_keys([:id, "accession_id_0_"], "")
      $driver.find_element(:css => "form#accession_form button[type='submit']").click
      expect {
        $driver.find_element_with_text('//div[contains(@class, "error")]', /Identifier - Property is required but was missing/)
      }.to_not raise_error
      # cancel first to back out bad change
      $driver.find_element(:link, "Cancel").click
    end


    it "can edit an Accession and two Extents" do
      # add the first extent
      $driver.find_element(:css => '#accession_extents_ .subrecord-form-heading .btn:not(.show-all)').click

      $driver.clear_and_send_keys([:id, 'accession_extents__0__number_'], "5")
      $driver.find_element(:id => "accession_extents__0__extent_type_").select_option("volumes")

      # add the second extent
      $driver.find_element(:css => '#accession_extents_ .subrecord-form-heading .btn:not(.show-all)').click
      $driver.clear_and_send_keys([:id, 'accession_extents__1__number_'], "10")
      $driver.find_element(:id => "accession_extents__1__extent_type_").select_option("files")


      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      $driver.click_and_wait_until_gone(:link => @accession_title)

      assert(5) { $driver.find_element(:css => '.record-pane h2').text.should eq("#{@accession_title} Accession") }
    end


    it "can see two extents on the saved Accession" do
      extent_headings = $driver.blocking_find_elements(:css => '#accession_extents_ .panel-heading')

      extent_headings.length.should eq (2)

      assert(5) { extent_headings[0].text.should eq ("5 Volumes") }
      assert(5) { extent_headings[1].text.should eq ("10 Files") }
    end


    it "can remove an extent when editing an Accession" do
      $driver.click_and_wait_until_gone(:link, 'Edit')
      $driver.blocking_find_elements(:css => '#accession_extents_ .subrecord-form-remove')[0].click
      $driver.find_element(:css => '#accession_extents_ .confirm-removal').click

      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      $driver.click_and_wait_until_gone(:link => @accession_title)

      extent_headings = $driver.blocking_find_elements(:css => '#accession_extents_ .panel-heading')
      extent_headings.length.should eq (1)
      assert(5) { extent_headings[0].text.should eq ("10 Files") }
    end


    it "can link an accession to an agent as a subject" do
      create_agent("Subject Agent #{@me}")
      run_index_round

      $driver.click_and_wait_until_gone(:link, 'Edit')

      $driver.find_element(:css => '#accession_linked_agents_ .subrecord-form-heading .btn:not(.show-all)').click

      $driver.find_element(:id => "accession_linked_agents__0__role_").select_option("subject")

      token_input = $driver.find_element(:id, "token-input-accession_linked_agents__0__ref_")
      token_input.clear
      token_input.click
      token_input.send_keys("Subject Agent")
      $driver.find_element(:css, "li.token-input-dropdown-item2").click

      $driver.find_element(:css, "#accession_linked_agents__0__terms_ .subrecord-form-heading .btn:not(.show-all)").click
      $driver.find_element(:css, "#accession_linked_agents__0__terms_ .subrecord-form-heading .btn:not(.show-all)").click

      $driver.clear_and_send_keys([:id => "accession_linked_agents__0__terms__0__term_"], "#{@me}LinkedAgentTerm1")
      $driver.clear_and_send_keys([:id => "accession_linked_agents__0__terms__1__term_"], "#{@me}LinkedAgentTerm2")

      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      $driver.click_and_wait_until_gone(:link => @accession_title)

      $driver.find_element(:id => 'accession_linked_agents_').text.should match(/LinkedAgentTerm/)
    end


    it "shows an error if you try to reuse an identifier" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Accession").click
      $driver.clear_and_send_keys([:id, "accession_title_"], @accession_title)
      $driver.complete_4part_id("accession_id_%d_", @shared_4partid)
      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      expect {
        $driver.find_element_with_text('//div[contains(@class, "error")]', /Identifier - That ID is already in use/)
      }.to_not raise_error

      $driver.click_and_wait_until_gone(:link => "Cancel")
      $driver.click_and_wait_until_gone(:link => "Cancel")
    end


    it "can create an Accession with some dates" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Accession").click

      # populate mandatory fields
      $driver.clear_and_send_keys([:id, "accession_title_"], @dates_accession_title)

      $driver.complete_4part_id("accession_id_%d_", @dates_4partid)

      $driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
      $driver.clear_and_send_keys([:id, "accession_content_description_"], "A box containing our own universe")
      $driver.clear_and_send_keys([:id, "accession_condition_description_"], "Slightly squashed")

      # add some dates!
      $driver.find_element(:css => '#accession_dates_ .subrecord-form-heading .btn:not(.show-all)').click
      $driver.find_element(:css => '#accession_dates_ .subrecord-form-heading .btn:not(.show-all)').click

      #populate the first date
      $driver.find_element(:id => "accession_dates__0__label_").select_option("digitized")
      $driver.find_element(:id => "accession_dates__0__date_type_").select_option("single")
      $driver.clear_and_send_keys([:id, "accession_dates__0__expression_"], "The day before yesterday.")

      #populate the second date
      $driver.find_element(:id => "accession_dates__1__label_").select_option("other")
      $driver.find_element(:id => "accession_dates__1__date_type_").select_option("inclusive")
      $driver.clear_and_send_keys([:id, "accession_dates__1__begin_"], "2012-05-14")
      $driver.clear_and_send_keys([:id, "accession_dates__1__end_"], "2011-05-14")

      # save!
      $driver.find_element(:css => "form#accession_form button[type='submit']").click

      # fail!
      expect {
        $driver.find_element_with_text('//div[contains(@class, "error")]', /must not be before begin/)
      }.to_not raise_error

      # fix!
      $driver.clear_and_send_keys([:id, "accession_dates__1__end_"], "2013-05-14")

      # save again!
      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      $driver.click_and_wait_until_gone(:link => @dates_accession_title)

      # check dates
      date_headings = $driver.blocking_find_elements(:css => '#accession_dates_ .panel-heading')
      date_headings.length.should eq (2)
    end


    it "can delete an existing date when editing an Accession" do
      $driver.click_and_wait_until_gone(:link, 'Edit')

      # remove the first date
      $driver.find_element(:css => '#accession_dates_ .subrecord-form-remove').click
      $driver.find_element(:css => '#accession_dates_ .confirm-removal').click

      # save!
      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      # check remaining date
      $driver.click_and_wait_until_gone(:link => @dates_accession_title)
      date_headings = $driver.blocking_find_elements(:css => '#accession_dates_ .panel-heading')
      date_headings.length.should eq (1)
    end


    it "can create an Accession with some external documents" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Accession").click

      # populate mandatory fields
      $driver.clear_and_send_keys([:id, "accession_title_"], @exdocs_accession_title)

      $driver.complete_4part_id("accession_id_%d_", @exdocs_4partid)

      $driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
      $driver.clear_and_send_keys([:id, "accession_content_description_"], "A box containing our own universe")
      $driver.clear_and_send_keys([:id, "accession_condition_description_"], "Slightly squashed")

      # add some external documents
      $driver.find_element(:css => '#accession_external_documents_ .subrecord-form-heading .btn:not(.show-all)').click
      $driver.find_element(:css => '#accession_external_documents_ .subrecord-form-heading .btn:not(.show-all)').click

      #populate the first external documents
      $driver.clear_and_send_keys([:id, "accession_external_documents__0__title_"], "My URI document")
      $driver.clear_and_send_keys([:id, "accession_external_documents__0__location_"], "http://archivesspace.org")

      #populate the second external documents
      $driver.clear_and_send_keys([:id, "accession_external_documents__1__title_"], "My other document")
      $driver.clear_and_send_keys([:id, "accession_external_documents__1__location_"], "a/file/path/or/something/")

      # save!
      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      $driver.click_and_wait_until_gone(:link => @exdocs_accession_title)

      # check external documents
      external_document_sections = $driver.blocking_find_elements(:css => '#accession_external_documents_ .external-document')
      external_document_sections.length.should eq (2)
      external_document_sections[0].find_element(:link => "http://archivesspace.org")
    end


    it "can delete an existing external documents when editing an Accession" do
      $driver.click_and_wait_until_gone(:link, 'Edit')

      # remove the first external documents
      $driver.find_element(:css => '#accession_external_documents_ .subrecord-form-remove').click
      $driver.find_element(:css => '#accession_external_documents_ .confirm-removal').click

      # save!
      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      $driver.click_and_wait_until_gone(:link => @exdocs_accession_title)

      # check remaining external documents
      external_document_sections = $driver.blocking_find_elements(:css => '#accession_external_documents_ .external-document')
      external_document_sections.length.should eq (1)
    end


    it "can create a subject and link to an Accession" do

      $driver.click_and_wait_until_gone(:link, 'Edit')

      $driver.find_element(:css => '#accession_subjects_ .subrecord-form-heading .btn:not(.show-all)').click

      $driver.find_element(:css => '#accession_subjects_ .dropdown-toggle').click

      $driver.find_element(:css, "a.linker-create-btn").click

      $driver.find_element(:css, ".modal #subject_terms_ .subrecord-form-heading .btn:not(.show-all)").click

      $driver.clear_and_send_keys([:id => "subject_terms__0__term_"], "#{@me}AccessionTermABC")
      $driver.clear_and_send_keys([:id => "subject_terms__1__term_"], "#{@me}AccessionTermDEF")
      $driver.find_element(:id => "subject_source_").select_option("local")

      $driver.find_element(:id, "createAndLinkButton").click

      # Browse works too
      $driver.find_element(:css => '#accession_subjects_ .dropdown-toggle').click
      $driver.find_element(:css, "a.linker-browse-btn").click
      $driver.find_element_with_text('//div', /#{@me}AccessionTermABC/)
      $driver.find_element(:css, ".modal-footer > button.btn.btn-cancel").click

      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      $driver.click_and_wait_until_gone(:link => @exdocs_accession_title)

      assert(5) { $driver.find_element(:css => "#accession_subjects_ .token").text.should eq("#{@me}AccessionTermABC -- #{@me}AccessionTermDEF") }
    end


    it "can add a rights statement to an Accession" do
      $driver.click_and_wait_until_gone(:link, 'Edit')

      # add a rights sub record
      $driver.find_element(:css => '#accession_rights_statements_ .subrecord-form-heading .btn:not(.show-all)').click

      $driver.find_element(:id => "accession_rights_statements__0__rights_type_").select_option("intellectual_property")
      $driver.find_element(:id => "accession_rights_statements__0__ip_status_").select_option("copyrighted")
      combo = $driver.find_element(:xpath => '//div[@class="combobox-container"][following-sibling::select/@id="accession_rights_statements__0__jurisdiction_"]//input[@type="text"]');
      combo.clear
      combo.click
      combo.send_keys("AU")
      combo.send_keys(:tab)
      $driver.find_element(:id, "accession_rights_statements__0__active_").click

      # add an external document
      $driver.find_element(:css => "#accession_rights_statements__0__external_documents_ .subrecord-form-heading .btn:not(.show-all)").click
      $driver.clear_and_send_keys([:id, "accession_rights_statements__0__external_documents__0__title_"], "Agreement")
      $driver.clear_and_send_keys([:id, "accession_rights_statements__0__external_documents__0__location_"], "http://locationof.agreement.com")

      # save changes
      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      sleep(10)
      # check the show page
      $driver.click_and_wait_until_gone(:link => @exdocs_accession_title)
      $driver.find_element(:id, "accession_rights_statements_")
      $driver.find_element(:css, "#accession_rights_statements_ .accordion-toggle").click
      $driver.find_element(:id, "rights_statement_0")
    end

    it "can add collection management fields to an Accession" do
      $driver.click_and_wait_until_gone(:link, 'Edit')
       $accession_url = $driver.current_url
      # add a collection management sub record
      $driver.find_element(:css => '#accession_collection_management_ .subrecord-form-heading .btn:not(.show-all)').click

      $driver.clear_and_send_keys([:id => "accession_collection_management__cataloged_note_"], ["DONE!", :return])
      $driver.find_element(:id => "accession_collection_management__processing_status_").select_option("completed")

      # save changes
      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")
     
      run_all_indexers
      # check the CM page
      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Collection Management").click
     
    
      expect {
        $driver.find_element_with_text('//td', /#{@exdocs_accession_title}/ )
      }.to_not raise_error     
      
      $driver.click_and_wait_until_gone(:link, 'View')
      $driver.click_and_wait_until_gone(:link, 'Edit')
     
      # now delete it
      $driver.find_element(:css => '#accession_collection_management_ .subrecord-form-remove').click
      $driver.find_element(:css => '#accession_collection_management_ .confirm-removal').click 
      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")
    
      run_all_indexers

      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Collection Management").click
      
      assert(5) { $driver.find_element(:css => ".alert.alert-info").text.should eq("No records found") }    

      $driver.get($accession_url) 
      $driver.click_and_wait_until_gone(:link => @exdocs_accession_title) 
    end

    it "supports adding an event and then returning to the accession" do
      if false
      agent_uri, @agent_name = create_agent("Geddy Lee")
      run_index_round
      $driver.find_element(:link, "Add Event").click
      $driver.find_element(:link, "Processed").click

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

      $driver.find_element(:css => "form#new_event button[type='submit']").click

      # Success!
      assert(5) {
        $driver.find_element_with_text('//div', /Event Created/).should_not be_nil
        $driver.find_element(:css => '.record-pane h2').text.should eq("#{@exdocs_accession_title} Accession")
      }
      end
    end


    it "can create an accession which is linked to another accession" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Accession").click

      # populate mandatory fields
      $driver.clear_and_send_keys([:id, "accession_title_"], "linked_accession_#{@me}")

      $driver.complete_4part_id("accession_id_%d_")
      
      #$driver.find_element(:css => '#accession_collection_management_ .subrecord-form-heading .btn:not(.show-all)').click
      $driver.find_element(:css => "#accession_related_accessions_ .subrecord-form-heading .btn:not(.show-all)").click

      $driver.find_element(:class, "related-accession-type").select_option('accession_parts_relationship')

      token_input = $driver.find_element(:id, "token-input-accession_related_accessions__0__ref_")
      token_input.clear
      token_input.click
      token_input.send_keys(@accession_title)
      $driver.find_element(:css =>  "li.token-input-dropdown-item2").click

      $driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

      $driver.find_element(:link, "linked_accession_#{@me}").click

      $driver.find_element_with_text('//td', /Forms Part of/)
      $driver.find_element_with_text('//td', /#{@accession_title}/)
    end


    it "can show a browse list of Accessions" do
      run_index_round

      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Accessions").click
      expect {
        $driver.find_element_with_text('//td', /#{@accession_title}/)
        $driver.find_element_with_text('//td', /#{@dates_accession_title}/)
        $driver.find_element_with_text('//td', /#{@exdocs_accession_title}/)
      }.to_not raise_error
    end


    it "can delete multiple Accessions from the listing" do
      # first login as someone with access to delete
      logout
      login_as_repo_manager

      second_accession_title = "A new accession about to be deleted"
      create_accession(:title => second_accession_title)
      run_index_round

      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Accessions").click

      $driver.blocking_find_elements(:css, ".multiselect-column input").each do |checkbox|
        checkbox.click
      end

      $driver.find_element(:css, ".record-toolbar .btn.multiselect-enabled").click
      $driver.find_element(:css, "#confirmChangesModal #confirmButton").click

      assert(5) { $driver.find_element(:css => ".alert.alert-success").text.should eq("Records deleted") }

      # refresh the indexer and the page to make sure it stuck
      run_index_round
      $driver.navigate.refresh
      assert(5) { $driver.find_element(:css => ".alert.alert-info").text.should eq("No records found") }
    end

  end


  describe "Pagination" do

    before(:all) do
      login_as_repo_manager
    end


    after(:all) do
      logout
      $accession_url = nil
    end


    it "can navigate through pages of accessions" do
      c = 0
      (AppConfig[:default_page_size].to_i * 2 + 1).times do
        create_accession(:title => "acc #{c += 1}")
      end
      run_index_round

      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Accessions").click
      expect {
        $driver.find_element_with_text('//div', /Showing 1 - #{AppConfig[:default_page_size]}/)
      }.to_not raise_error

      $driver.find_element(:xpath, '//a[@title="Next"]').click
      expect {
        $driver.find_element_with_text('//div', /Showing #{AppConfig[:default_page_size] + 1}/)
      }.to_not raise_error

    end

    it "can navigate through pages of digital objects " do
      c = 0
      (AppConfig[:default_page_size].to_i + 1).times do
        create_digital_object({ :title => "I can't believe this is DO number #{c += 1}"})
      end
      run_index_round

      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Digital Objects").click
      expect {
        $driver.find_element_with_text('//div', /Showing 1 - #{AppConfig[:default_page_size]}/)
      }.to_not raise_error

      $driver.find_element(:xpath, '//a[@title="Next"]').click
      expect {
        $driver.find_element_with_text('//div', /Showing #{AppConfig[:default_page_size] + 1}/)
      }.to_not raise_error

    end
  end


  describe "Record Lifecycle" do

    before(:all) do
      login_as_repo_manager

      do_uri, @digital_object_title = create_digital_object(:title => "My digital object to test the record lifecycle")
      resource_uri, resource_title = create_resource(:title => "My resource to test the record lifecycle", :instances => [{:instance_type => "digital_object", :digital_object => {:ref => do_uri}}])
      create_archival_object(:title => nil, :dates => [{:expression => "1981 - present", :date_type => "single", :label => "creation"}], :resource => {:ref => resource_uri}, :instances => [{:instance_type => "digital_object", :digital_object => {:ref => do_uri}}])

      @accession_title = create_accession(:title => "My accession to test the record lifecycle")
      run_index_round
      logout
    end

    after(:each) do
      logout 
    end

    after(:all) do
      $accession_url = nil
    end


    it "can suppress an Accession" do
      login_as_repo_manager
      # make sure we can see suppressed records
      $driver.find_element(:css, '.user-container .btn.dropdown-toggle.last').click
      $driver.find_element(:link, "My Repository Preferences").click

      elt = $driver.find_element(:xpath, '//input[@id="preference_defaults__show_suppressed_"]')
      unless elt[@checked]
        elt.click
        $driver.find_element(:css => 'button[type="submit"]').click
      end

      # Navigate to the Accession
      $driver.clear_and_send_keys([:id, "global-search-box"], @accession_title)
      $driver.find_element(:id, "global-search-button").click
      $driver.find_element(:link, "View").click
      $accession_url = $driver.current_url

      # Suppress the Accession
      $driver.find_element(:css, ".suppress-record.btn").click
      $driver.find_element(:css, "#confirmChangesModal #confirmButton").click

      assert(5) { $driver.find_element(:css => "div.alert.alert-success").text.should eq("Accession #{@accession_title} suppressed") }
      assert(5) { $driver.find_element(:css => "div.alert.alert-info").text.should eq('Accession is suppressed and cannot be edited') }

      run_index_round

      # Try to navigate to the edit form
      $driver.get("#{$accession_url}/edit")

      assert(5) { $driver.current_url.should eq($accession_url) }
      assert(5) { $driver.find_element(:css => "div.alert.alert-info").text.should eq('Accession is suppressed and cannot be edited') }

    end


    it "an archivist can't see a suppressed Accession" do
      login_as_archivist
      # check the listing
      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Accessions").click

      $driver.find_element_with_text('//h2', /Accessions/)

      # No element found
      $driver.find_element_with_text('//td', /#{@accession_title}/, true, true).should eq(nil)

      # check the accession url
      $driver.get($accession_url)
      $driver.find_element_with_text('//h2', /Record Not Found/)

    end


    it "can unsuppress an Accession" do
      login_as_repo_manager

      $driver.get($accession_url)

      # Unsuppress the Accession
      $driver.find_element(:css, ".unsuppress-record.btn").click
      $driver.find_element(:css, "#confirmChangesModal #confirmButton").click

      assert(5) { $driver.find_element(:css => "div.alert.alert-success").text.should eq("Accession #{@accession_title} unsuppressed") }
    end


    it "can delete an Accession" do
      login_as_repo_manager
      $driver.get($accession_url)
      # Delete the accession
      $driver.find_element(:css, ".delete-record.btn").click
      $driver.find_element(:css, "#confirmChangesModal #confirmButton").click

      #Ensure Accession no longer exists
      assert(5) { $driver.find_element(:css => "div.alert.alert-success").text.should eq("Accession #{@accession_title} deleted") }

      run_index_round

      # hmm boo.. refresh the page now that the indexer is refreshed
      $driver.navigate.refresh
      $driver.find_element_with_text('//h2', /Accessions/)

      # No element found
      $driver.find_element_with_text('//td', /#{@accession_title}/, true, true).should eq(nil)

      # Navigate back to the accession's page
      $driver.get($accession_url)
      assert(5) {
        $driver.find_element_with_text('//h2', /Record Not Found/)
      }
      $driver.navigate.to $frontend
    end


    it "can suppress a Digital Object" do
      login_as_repo_manager
      # Navigate to the Digital Object
      $driver.clear_and_send_keys([:id, "global-search-box"], @digital_object_title)
      $driver.find_element(:id, "global-search-button").click
      $driver.find_element(:link, "View").click
      digital_object_url = $driver.current_url
      $driver.find_element(:link, "Edit").click
      digital_object_edit_url = $driver.current_url

      # Suppress the Digital Object
      $driver.find_element(:css, ".suppress-record.btn").click
      $driver.find_element(:css, "#confirmChangesModal #confirmButton").click

      assert(5) { $driver.find_element(:css => "div.alert.alert-success").text.should eq("Digital Object #{@digital_object_title} suppressed") }
      assert(5) { $driver.find_element(:css => "div.alert.alert-info").text.should eq('Digital Object is suppressed and cannot be edited') }

      run_index_round

      # Try to navigate to the edit form
      $driver.get(digital_object_edit_url)
      # there seems to be some oddities with the JS and the URL...they don't
      # matter to the app
      url = digital_object_edit_url.split("#").first
      assert(5) { $driver.current_url.include?(url).should be_true }
      assert(5) { $driver.find_element(:css => "div.alert.alert-info").text.should eq('Digital Object is suppressed and cannot be edited') }
    end

  end


  describe "Events" do

    before(:all) do
      login_as_archivist
      @accession_title = create_accession(:title => "Events link to this accession")
      agent_uri, @agent_name = create_agent("Geddy Lee")
      run_index_round
    end


    after(:all) do
      logout
    end


    it "creates an event and links it to an agent and accession" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Event").click
      $driver.find_element(:id, "event_event_type_").select_option('virus_check')
      $driver.find_element(:id, "event_outcome_").select_option("pass")
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

      $driver.find_element(:id, "event_linked_records__0__role_").select_option('source')

      record_subform = $driver.find_element(:id, "event_linked_records__0__role_").
                               nearest_ancestor('div[contains(@class, "subrecord-form-container")]')

      token_input = record_subform.find_element(:id, "token-input-event_linked_records__0__ref_")
      token_input.clear
      token_input.click
      token_input.send_keys(@accession_title)
      $driver.find_element(:css, "li.token-input-dropdown-item2").click

      $driver.find_element(:css => "form#new_event button[type='submit']").click

      # Success!
      assert(5) {
        $driver.find_element_with_text('//div', /Event Created/).should_not be_nil
      }
    end
  

    it "should be searchable" do
      run_index_round
      $driver.find_element(:id, 'global-search-button').click
      $driver.find_element(:link, "Event").click 
      assert(5) { $driver.find_element_with_text("//h2", /Search Results/) }
    end
  
  end


  describe "Resources and archival object trees" do

    before(:all) do
      login_as_archivist
    end


    after(:all) do
      logout
    end


    it "can spawn a resource from an existing accession" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Accession").click

      # populate mandatory fields
      $driver.clear_and_send_keys([:id, "accession_title_"], "A box of enraged guinea pigs")

      $driver.complete_4part_id("accession_id_%d_")

      $driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
      $driver.clear_and_send_keys([:id, "accession_content_description_"], "9 guinea pigs")
      $driver.clear_and_send_keys([:id, "accession_condition_description_"], "furious")
      
      # add a rights sub record
      $driver.find_element(:css => '#accession_collection_management_ .subrecord-form-heading .btn:not(.show-all)').click

      $driver.clear_and_send_keys([:id => "accession_collection_management__cataloged_note_"], ["HOBO CAMP!", :return])
      $driver.find_element(:id => "accession_collection_management__processing_status_").select_option("completed")
      

      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      # save
      $driver.find_element(:css => "form#accession_form button[type='submit']").click

      # Spawn a resource from the accession we just created
      $driver.find_element(:link, "Spawn").click
      $driver.find_element(:link, "Resource").click

      # The relationship back to the original accession is prepopulated
      $driver.find_element(:css => 'div.accession').text.should match(/enraged guinea pigs/)

      $driver.complete_4part_id("resource_id_%d_")
      combo = $driver.find_element(:xpath => '//div[@class="combobox-container"][following-sibling::select/@id="resource_language_"]//input[@type="text"]');
      combo.clear
      combo.click
      combo.send_keys("eng")
      combo.send_keys(:tab)

      $driver.find_element(:id, "resource_level_").select_option("collection")

      # no collection managment
      $driver.find_elements(:id, "resource_collection_management__cataloged_note_").length.should eq(0)
      
      # condition and content descriptions have come across as notes fields
      notes_toggle = $driver.blocking_find_elements(:css => "#notes .collapse-subrecord-toggle")
      notes_toggle[0].click
      $driver.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').toTextArea()")
      assert(5) { $driver.find_element(:id => "resource_notes__0__subnotes__0__content_").attribute("value").should eq("9 guinea pigs") }

      notes_toggle[1].click
      $driver.find_element(:id => "resource_notes__1__content__0_").text.should match(/furious/)


      $driver.clear_and_send_keys([:id, "resource_extents__0__number_"], "10")
      $driver.find_element(:id => "resource_extents__0__extent_type_").select_option("files")

      $driver.find_element(:id => "resource_dates__0__date_type_").select_option("single")
      $driver.clear_and_send_keys([:id, "resource_dates__0__begin_"], "1978")
      

      $driver.find_element(:css => "form#resource_form button[type='submit']").click

      # Success!
      assert(5) {
        $driver.find_element_with_text('//div', /Resource A box of enraged guinea pigs created/).should_not be_nil
      }
    end

    it "reports errors and warnings when creating an invalid Resource" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Resource").click
      $driver.find_element(:id, "resource_title_").clear
      $driver.find_element(:css => "form#resource_form button[type='submit']").click

      $driver.find_element_with_text('//div[contains(@class, "error")]', /Identifier - Property is required but was missing/)
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Title - Property is required but was missing/)
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Number - Property is required but was missing/)
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Type - Property is required but was missing/)
      $driver.find_element_with_text('//div[contains(@class, "warning")]', /Language - Property was missing/)

      $driver.find_element(:css, "a.btn.btn-cancel").click
    end


    resource_title = "Pony <emph render='italic'>Express</emph>"
    resource_stripped = "Pony Express"
    resource_regex = /^.*?\bPony\b.*?$/m 
    
    it "can create a resource" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Resource").click

      $driver.clear_and_send_keys([:id, "resource_title_"],(resource_title))
      @resource_id = $driver.complete_4part_id("resource_id_%d_")
      
      $driver.find_element(:id => "resource_dates__0__date_type_").select_option("single")
      $driver.clear_and_send_keys([:id, "resource_dates__0__begin_"], "1978")
      
      combo = $driver.find_element(:xpath => '//div[@class="combobox-container"][following-sibling::select/@id="resource_language_"]//input[@type="text"]');
      combo.clear
      combo.click
      combo.send_keys("eng")
      combo.send_keys(:tab)
      $driver.find_element(:id, "resource_level_").select_option("collection")
      $driver.clear_and_send_keys([:id, "resource_extents__0__number_"], "10")
      $driver.find_element(:id => "resource_extents__0__extent_type_").select_option("files")
      $driver.find_element(:css => "form#resource_form button[type='submit']").click

      # The new Resource shows up on the tree
      assert(5) { $driver.find_element(:css => "a.jstree-clicked").text.strip.should match(resource_regex) }
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

      $driver.clear_and_send_keys([:id, "archival_object_title_"], "")

      # False start: create an object without filling it out
      $driver.click_and_wait_until_gone(:id => "createPlusOne")

      $driver.find_element_with_text('//div[contains(@class, "error")]', /Level of Description - Property is required but was missing/)
    end


    it "reports error if title is empty and no date is provided" do
      $driver.find_element(:id, "archival_object_level_").select_option("item")
      $driver.clear_and_send_keys([:id, "archival_object_title_"], "")

      # False start: create an object without filling it out
      $driver.click_and_wait_until_gone(:id => "createPlusOne")

      $driver.find_element_with_text('//div[contains(@class, "error")]', /Dates - one or more required \(or enter a Title\)/i)
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Title - must not be an empty string \(or enter a Date\)/i)
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
        $driver.find_element(:xpath, "//textarea[@id='archival_object_title_' and not(text())]")

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

      # Last added node now selected (text will include the 'level' badge)
      assert(5) {
        $driver.find_element(:css => "a.jstree-clicked .title-column").text.strip.should eq('December')
        $driver.find_element(:css => "a.jstree-clicked .field-column-1").text.strip.should eq('Item')
      }
    end


    it "reports warnings when updating an Archival Object with invalid data" do
      aotitle = $driver.find_element(:css, "h2").text.sub(/ +Archival Object/, "")
      $driver.clear_and_send_keys([:id, "archival_object_title_"], "")
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
      expect {
        $driver.find_element_with_text('//div[contains(@class, "error")]', /Title - must not be an empty string/)
      }.to_not raise_error
      $driver.clear_and_send_keys([:id, "archival_object_title_"], aotitle)
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
    end

    it "can update an existing Archival Object" do
      aotitle = $driver.find_element(:css, "h2").text.sub(/ +Archival Object/, "")
      $driver.clear_and_send_keys([:id, "archival_object_title_"], "save this please")
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
      assert(5) { $driver.find_element(:css, "h2").text.should eq("save this please Archival Object") }
      assert(5) { $driver.find_element(:css => "div.alert.alert-success").text.should eq('Archival Object save this please updated') }
      $driver.clear_and_send_keys([:id, "archival_object_title_"], aotitle)
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
    end


    it "can add a child to an existing node and assign a Subject" do
      $driver.find_element(:link, "Add Child").click

      $driver.clear_and_send_keys([:id, "archival_object_title_"], "Christmas cards")
      $driver.find_element(:id, "archival_object_level_").select_option("item")

      $driver.find_element(:css => '#archival_object_subjects_ .subrecord-form-heading .btn:not(.show-all)').click

      $driver.find_element(:css, ".linker-wrapper a.btn").click
      $driver.find_element(:css, "a.linker-create-btn").click

      $driver.find_element(:css, ".modal #subject_terms_ .subrecord-form-heading .btn:not(.show-all)").click

      $driver.clear_and_send_keys([:id => "subject_terms__0__term_"], "#{$$}TestTerm123")
      $driver.clear_and_send_keys([:id => "subject_terms__1__term_"], "#{$$}FooTerm456")
      $driver.find_element(:id => "subject_source_").select_option("local")

      $driver.find_element(:id, "createAndLinkButton").click
    end


    it "can remove the linked Subject but find it using typeahead and re-add it" do
      # remove the subject
      $driver.find_element(:css, ".token-input-delete-token").click

      # search for the created subject
      assert(5) {
        run_index_round
        $driver.clear_and_send_keys([:id, "token-input-archival_object_subjects__0__ref_"], "#{$$}TestTerm123")
        $driver.find_element(:css, "li.token-input-dropdown-item2").click
      }

      $driver.click_and_wait_until_gone(:css, "form#archival_object_form button[type='submit']")

      # so the subject is here now
      assert(5) { $driver.find_element(:css, "#archival_object_subjects_ ul.token-input-list").text.should match(/#{$$}FooTerm456/) }
    end


    it "can view a read only Archival Object" do
      $driver.find_element(:link, 'Close Record').click

      assert(5) { $driver.find_element(:css, ".record-pane h2").text.should eq("Christmas cards Archival Object") }

      $driver.find_element(:link => "Edit").click
    end

    it "can add siblings" do
       
      [ "Christmas albums", "Tree decorations", "Nog"].each do |ao| 
        $driver.click_and_wait_until_gone(:link, "Add Sibling")
        $driver.clear_and_send_keys([:id, "archival_object_title_"], ao)
        $driver.find_element(:id, "archival_object_level_").select_option("item")
        $driver.click_and_wait_until_gone(:css, "form#archival_object_form button[type='submit']")
      end
    end

    it "can support dragging and dropping an archival object" do
      $driver.navigate.refresh
      # first resize the tree pane (do it incrementally so it doesn't flip out...)
      pane_resize_handle = $driver.find_element(:css => ".ui-resizable-handle.ui-resizable-s")
      10.times {
        $driver.action.drag_and_drop_by(pane_resize_handle, 0, 30).perform
      }
      $driver.find_element(:css, "a[title~='December']").click

      source = $driver.find_element_with_text("//div[@id='archives_tree']//a", /Christmas cards/)
      target = $driver.find_element_with_text("//div[@id='archives_tree']//a", /Pony Express/)
      $driver.action.drag_and_drop(source, target).perform
      $driver.wait_for_ajax
      target = $driver.find_element_with_text("//div[@id='archives_tree']//li", /Pony Express/)
      target.find_element_with_text(".//a", /Christmas cards/)

      # refresh the page and verify that the change really stuck
      $driver.navigate.refresh

      target = $driver.find_element_with_text("//div[@id='archives_tree']//li", /Pony Express/)
      target.find_element_with_text("//a", /Christmas cards/)
    
      target = $driver.find_element(:xpath, "//div[@id='archives_tree']//li[a/@title='December']")
      [ "Christmas albums", "Tree decorations", "Nog"].each do |ao| 
          target.find_element_with_text(".//a", /#{ao}/)
      end 
    
      
      pane_resize_handle = $driver.find_element(:css => ".ui-resizable-handle.ui-resizable-s")
      10.times {
        $driver.action.drag_and_drop_by(pane_resize_handle, 0, -20).perform
      }
    end
   
    it "can reorder while editing another item and not lose the order" do
      parent = $driver.find_element(:xpath, "//div[@id='archives_tree']//li[a/@title='December']")
      source = $driver.find_element_with_text("//div[@id='archives_tree']//a", /Nog/)
      
      parent.find_element_with_text(".//a", /Tree decorations/).click
      $driver.clear_and_send_keys([:id, "archival_object_title_"], "XMAS Tree decorations")
     
      # now do a drag and drop
      $driver.action.drag_and_drop(source, parent ).perform
      # save the item
      $driver.click_and_wait_until_gone(:css, "form#archival_object_form button[type='submit']")
      
      parent = $driver.find_element(:xpath, "//div[@id='archives_tree']//li[a/@title='December']")
      [ "Christmas albums", "Nog", "XMAS Tree decorations" ].each do |term|
        parent.find_element_with_text(".//a", /#{term}/)
      end
    end
      
      
    it "can not reorder if logged in as a read only user" do

      $driver.find_element(:link, 'Close Record').click
      url = $driver.current_url
      
      logout
      login_as_viewer
      
      $driver.get(url)
    
      parent = $driver.find_element(:xpath, "//div[@id='archives_tree']//li[a/@title='December']")
      source = $driver.find_element_with_text("//div[@id='archives_tree']//a", /XMAS Tree decorations/)
      
      children = $driver.blocking_find_elements(:css => "span.tree-node-text").map{|span| span.text.strip}
      
      # now do a drag and drop
      $driver.action.drag_and_drop(source, parent ).perform

		# there should be no change...      
      rechildren = $driver.blocking_find_elements(:css => "span.tree-node-text").map{|span| span.text.strip}
		
	  children.should eq(rechildren)

	   logout
	   login_as_archivist
	   
	
	   
    end


    it "exports and downloads the resource to xml" do
      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Resources").click
      $driver.find_element_with_text('//tr', resource_regex).find_element(:link, 'Edit').click
    
      system("rm #{File.join(Dir.tmpdir, '*_ead.xml')}")

      $driver.find_element(:link, "Export").click
      response = $driver.find_element(:link, "Download EAD").click
      $driver.wait_for_ajax
      assert(5) { Dir.glob(File.join( Dir.tmpdir,"*_ead.xml" )).length.should eq(1) } 
      system("rm #{File.join(Dir.tmpdir, '*_ead.xml')}")
    end
    
    it "exports and downloads the resource to pdf" do
      system("rm #{File.join(Dir.tmpdir, '*_ead.pdf')}")
      $driver.find_element_with_text("//div[@id='archives_tree']//a", /Pony Express/).click
      $driver.find_element(:link, "Export").click
       
      el = $driver.find_element(:link, "Download EAD")
      $driver.mouse.move_to(el) 
      
      $driver.find_element(:css, "input#print-pdf").click
      $driver.find_element(:link, "Download EAD").click
      
      $driver.wait_for_ajax
      assert(5) { Dir.glob(File.join( Dir.tmpdir,"*_ead.pdf" )).length.should eq(1) } 
      system("rm #{File.join(Dir.tmpdir, '*_ead.pdf')}")
    end


    it "shows our newly added Resource in the browse list" do
      run_index_round
      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Resources").click

      $driver.find_element_with_text('//td', /#{resource_stripped}/)
    end
    


    it "can edit a Resource and add another Extent" do
      ## Check browse list for Resources
      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Resources").click

      $driver.find_element_with_text('//tr', resource_regex).find_element(:link, 'Edit').click

      $driver.find_element(:css => '#resource_extents_ .subrecord-form-heading .btn:not(.show-all)').click

      $driver.clear_and_send_keys([:id, 'resource_extents__1__number_'], "5")
      $driver.find_element(:id => "resource_extents__1__extent_type_").select_option("volumes")

      $driver.find_element(:css => "form#resource_form button[type='submit']").click

      $driver.find_element_with_text('//div', /\bResource\b.*\bupdated\b/).should_not be_nil

      $driver.find_element(:link, 'Close Record').click
    end


    it "can see two Extents on the saved Resource" do
      extent_headings = $driver.blocking_find_elements(:css => '#resource_extents_ .panel-heading')

      extent_headings.length.should eq (2)
      assert(5) { extent_headings[0].text.should eq ("10 Files") }
      assert(5) { extent_headings[1].text.should eq ("5 Volumes") }
    end


    it "can remove an Extent when editing a Resource" do
      $driver.click_and_wait_until_gone(:link, 'Edit')

      $driver.blocking_find_elements(:css => '#resource_extents_ .subrecord-form-remove')[1].click
      $driver.find_element(:css => '#resource_extents_ .confirm-removal').click
      $driver.find_element(:css => "form#resource_form button[type='submit']").click

      $driver.find_element(:link, 'Close Record').click

      extent_headings = $driver.blocking_find_elements(:css => '#resource_extents_ .panel-heading')

      extent_headings.length.should eq (1)
      assert(5) { extent_headings[0].text.should eq ("10 Files") }
    end
 
    it "can transfer a resource to another repository" do
      
      
      logout
      login("admin", "admin")
      @target_repo_name = "target_#{Time.now.to_i}"      
      @target_repo_code, @target_repo_uri = create_test_repo(@target_repo_name, @target_repo_name, true)
      
      select_repo($test_repo) 
      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Resources").click
      $driver.find_element_with_text('//tr', resource_regex).find_element(:link, 'Edit').click
      
      $driver.find_element(:link, "Transfer").click
      $driver.find_element(:id, "transfer_ref_").select_option_with_text(@target_repo_name)
      $driver.find_element(:css => ".transfer-button").click
      $driver.find_element(:css, "#confirmButton").click
      $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Transfer Successful/)
      
      run_all_indexers

      select_repo(@target_repo_code) 
      
      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Resources").click
      
      $driver.find_element_with_text('//td', /#{resource_stripped}/)

    end
    
    it "can edit and reorder aftert the transfer" do
      $driver.find_element_with_text('//tr', resource_regex).find_element(:link, 'Edit').click
      
      # first resize the tree pane (do it incrementally so it doesn't flip out...)
      pane_resize_handle = $driver.find_element(:css => ".ui-resizable-handle.ui-resizable-s")
      10.times {
        $driver.action.drag_and_drop_by(pane_resize_handle, 0, 10).perform
      }

      source = $driver.find_element_with_text("//div[@id='archives_tree']//a", /December/)
      target = $driver.find_element_with_text("//div[@id='archives_tree']//a", /Pony Express/)
      $driver.action.drag_and_drop(source, target).perform
      $driver.wait_for_ajax
    
      target = $driver.find_element_with_text("//div[@id='archives_tree']//li", /Pony Express/)
      target.find_element_with_text(".//a", /December/)

      # refresh the page and verify that the change really stuck
      $driver.navigate.refresh

      target = $driver.find_element_with_text("//div[@id='archives_tree']//li", /Pony Express/)
      target.find_element_with_text(".//a", /December/).click
      
      $driver.clear_and_send_keys([:id, "archival_object_title_"], "save this please")
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
      assert(5) { $driver.find_element(:css, "h2").text.should eq("save this please Archival Object") }
      assert(5) { $driver.find_element(:css => "div.alert.alert-success").text.should eq('Archival Object save this please updated') }
      
      target = $driver.find_element_with_text("//div[@id='archives_tree']//li", /Pony Express/)
      target.find_element_with_text(".//a", /save this please/).click
      
      $driver.find_element(:link, "Add Child").click

      $driver.clear_and_send_keys([:id, "archival_object_title_"], "Baby AO")
      $driver.find_element(:id, "archival_object_level_").select_option("item")
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
        
      assert(5){
       $driver.find_element_with_text("//div[@id='archives_tree']//li//span", /Baby AO/)
      } 
    end
 
    it "can merge a resource into a resource" do
      logout
      login("admin", "admin")
      
      select_repo($test_repo) 
      
      [ "Thing1", "Thing2"].each do |title| 
        create_resource( :title => title  )
      end
      run_index_round

      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Resources").click
      $driver.find_element_with_text('//tr', /Thing1/).find_element(:link, 'Edit').click

      $driver.find_element(:link, "Merge").click
      
      $driver.clear_and_send_keys([:id, "token-input-merge_ref_"], "Thing2" )
      $driver.find_element(:css, "li.token-input-dropdown-item2").click
      
      $driver.find_element(:css, "button.merge-button").click
      
      $driver.wait_for_ajax

      $driver.find_element_with_text("//h3", /Merge into this record\?/)
      $driver.find_element(:css, "button#confirmButton").click
      $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Resource\(s\) Merged/)


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
      combo = $driver.find_element(:xpath => '//div[@class="combobox-container"][following-sibling::select/@id="resource_language_"]//input[@type="text"]');
      combo.clear
      combo.click
      combo.send_keys("eng")
      combo.send_keys(:tab)
      $driver.find_element(:id, "resource_level_").select_option("collection")
      $driver.clear_and_send_keys([:id, "resource_extents__0__number_"], "10")
      $driver.find_element(:id => "resource_extents__0__extent_type_").select_option("files")
      
      $driver.find_element(:id => "resource_dates__0__date_type_").select_option("single")
      $driver.clear_and_send_keys([:id, "resource_dates__0__begin_"], "1978")

      add_note = proc do |type|
        $driver.find_element(:css => '#notes .subrecord-form-heading .btn:not(.show-all)').click
        $driver.find_last_element(:css => '#notes select.top-level-note-type:last-of-type').select_option(type)
      end

      3.times do
        add_note.call("note_multipart")
      end

      $driver.blocking_find_elements(:css => '#notes > .subrecord-form-container > .subrecord-form-list > li').length.should eq(3)
    end


    it "confirms before removing a note entry" do
      notes = $driver.blocking_find_elements(:css =>  '#notes > .subrecord-form-container > .subrecord-form-list > li')

      notes[0].find_element(:css => '.subrecord-form-remove').click

      # Get a confirmation
      $driver.find_element(:css => '.subrecord-form-removal-confirmation')

      # Now remove the second note
      notes[1].find_element(:css => '.subrecord-form-remove').click

      # Verify that the first confirmation is now gone
      $driver.find_elements(:css => '.subrecord-form-removal-confirmation').length.should be < 2

      # Confirm
      $driver.click_and_wait_until_gone(:css => '.subrecord-form-removal-confirmation .btn-primary')

      # Take out the first note too
      notes[0].find_element(:css => '.subrecord-form-remove').click
      $driver.click_and_wait_until_gone(:css => '.subrecord-form-removal-confirmation .btn-primary')

      # One left!
      $driver.blocking_find_elements(:css => '#notes > .subrecord-form-container > .subrecord-form-list > li').length.should eq(1)

      # Fill it out
      $driver.clear_and_send_keys([:id, 'resource_notes__2__label_'],
                                  "A multipart note")

      $driver.execute_script("$('#resource_notes__2__subnotes__0__content_').data('CodeMirror').setValue('Some note content')")
      $driver.execute_script("$('#resource_notes__2__subnotes__0__content_').data('CodeMirror').save()")


      # Save the resource
      $driver.click_and_wait_until_gone(:css => "form#resource_form button[type='submit']")

      $driver.find_element(:link, 'Close Record').click
    end


    it "can edit an existing resource note to add subparts after saving" do
      $driver.click_and_wait_until_gone(:link, 'Edit')

      notes = $driver.blocking_find_elements(:css => '#notes .subrecord-form-fields')

      # Add a sub note
      notes[0].find_element(:css => '.collapse-subrecord-toggle').click
      assert(5) { notes[0].find_element(:css => '.subrecord-form-heading .btn:not(.show-all)').click }
      notes[0].find_last_element(:css => 'select.multipart-note-type').select_option('note_chronology')

      $driver.find_element(:id => 'resource_notes__0__subnotes__2__title_')
      $driver.clear_and_send_keys([:id, 'resource_notes__0__subnotes__2__title_'], "Chronology title")


      notes[0].find_element(:css => '.subrecord-form-heading .btn:not(.show-all)').click
      notes[0].find_last_element(:css => 'select.multipart-note-type').select_option('note_definedlist')

      $driver.clear_and_send_keys([:id, 'resource_notes__0__subnotes__3__title_'], "Defined list")

      2.times do
        $driver.find_element(:id => 'resource_notes__0__subnotes__3__title_').
                containing_subform.
                find_element(:css => '.add-item-btn').
                click
      end

      [4, 5]. each do |i|
        ["label", "value"].each do |field|
          $driver.clear_and_send_keys([:id, "resource_notes__0__subnotes__3__items__#{i}__#{field}_"],
                                      "pogo")
        end
      end

      # Save the resource
      $driver.find_element(:css => "form#resource_form button[type='submit']").click
      $driver.find_element(:link, 'Close Record').click

      $driver.find_element_with_text("//div", /pogo/)
    end


    it "can add a top-level bibliography too" do
      bibliography_content = "Top-level bibliography content"

      $driver.click_and_wait_until_gone(:link, 'Edit')

      $driver.find_element(:css => '#notes > .subrecord-form-heading .btn:not(.show-all)').click
      $driver.find_last_element(:css => 'select.top-level-note-type').select_option("note_bibliography")

      $driver.clear_and_send_keys([:id, 'resource_notes__6__label_'], "Top-level bibliography label")
      $driver.execute_script("$('#resource_notes__6__content__0_').data('CodeMirror').setValue('#{bibliography_content}')")
      $driver.execute_script("$('#resource_notes__6__content__0_').data('CodeMirror').save()")

      $driver.execute_script("$('#resource_notes__6__content__0_').data('CodeMirror').toTextArea()")
      $driver.find_element(:id => "resource_notes__6__content__0_").attribute("value").should eq(bibliography_content)

      form = $driver.find_element(:id => 'resource_notes__6__label_').nearest_ancestor('div[contains(@class, "subrecord-form-container")]')

      2.times do
        form.find_element(:css => '.add-item-btn').click
      end

      $driver.clear_and_send_keys([:id, 'resource_notes__6__items__7_'], "Top-level bib item 1")
      $driver.clear_and_send_keys([:id, 'resource_notes__6__items__8_'], "Top-level bib item 2")

    end


    it "can wrap note content text with EAD mark up" do
      # expand the first note
      $driver.find_element(:css => '#notes .collapse-subrecord-toggle').click

      # select some text
      $driver.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').setValue('ABC')")
      $driver.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').setSelection({line: 0, ch: 0}, {line: 0, ch: 3})")

      # select a tag to wrap the text
      assert(5) { $driver.find_element(:css => "select.mixed-content-wrap-action").select_option("blockquote") }
      $driver.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').save()")
      $driver.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').toTextArea()")
      $driver.find_element(:id => "resource_notes__0__subnotes__0__content_").attribute("value").should eq("<blockquote>ABC</blockquote>")

      # Save the resource
      $driver.find_element(:css => "form#resource_form button[type='submit']").click
      $driver.find_element(:link, 'Close Record').click
    end


    it "can add a deaccession record" do
      $driver.click_and_wait_until_gone(:link, 'Edit')

      $driver.find_element(:css => '#resource_deaccessions_ .subrecord-form-heading .btn:not(.show-all)').click

      $driver.find_element(:id => 'resource_deaccessions__0__date__label_').get_select_value.should eq("deaccession")

      $driver.clear_and_send_keys([:id, 'resource_deaccessions__0__description_'], "Lalala describing the deaccession")
      $driver.find_element(:css => "#resource_deaccessions__0__date__date_type_").select_option("single")
      $driver.clear_and_send_keys([:id, 'resource_deaccessions__0__date__begin_'], "2012-05-14")


      # Save the resource
      $driver.find_element(:css => "form#resource_form button[type='submit']").click
      $driver.find_element(:link, 'Close Record').click

      $driver.blocking_find_elements(:css => '#resource_deaccessions_').length.should eq(1)
    end


    it "can attach notes to archival objects" do
      # Create a resource
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Resource").click

      $driver.clear_and_send_keys([:id, "resource_title_"], "a resource")
      $driver.complete_4part_id("resource_id_%d_")
      combo = $driver.find_element(:xpath => '//div[@class="combobox-container"][following-sibling::select/@id="resource_language_"]//input[@type="text"]');
      combo.clear
      combo.click
      combo.send_keys("eng")
      combo.send_keys(:tab)
      $driver.find_element(:id, "resource_level_").select_option("collection")
      $driver.clear_and_send_keys([:id, "resource_extents__0__number_"], "10")
      $driver.find_element(:id => "resource_extents__0__extent_type_").select_option("files")
      
      $driver.find_element(:id => "resource_dates__0__date_type_").select_option("single")
      $driver.clear_and_send_keys([:id, "resource_dates__0__begin_"], "1978")

      $driver.find_element(:css => "form#resource_form button[type='submit']").click

      # Give it a child AO
      $driver.find_element(:link, "Add Child").click

      $driver.clear_and_send_keys([:id, "archival_object_title_"], "An Archival Object with notes")
      $driver.find_element(:id, "archival_object_level_").select_option("item")


      # Add some notes to it
      add_note = proc do |type|
        $driver.find_element(:css => '#notes .subrecord-form-heading .btn:not(.show-all)').click
        $driver.find_last_element(:css => '#notes select.top-level-note-type').select_option(type)
      end

      3.times do
        add_note.call("note_multipart")
      end

      $driver.blocking_find_elements(:css => '#notes > .subrecord-form-container > .subrecord-form-list > li').length.should eq(3)

      $driver.find_element(:link, "Revert Changes").click

      # Skip over "Save Your Changes" dialog i.e. don't save AO.
      $driver.find_element(:id, "dismissChangesButton").click
    end


    it "can attach special notes to digital objects" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Digital Object").click

      $driver.clear_and_send_keys([:id, "digital_object_title_"], "A digital object with notes")
      $driver.clear_and_send_keys([:id, "digital_object_digital_object_id_"],(Digest::MD5.hexdigest("#{Time.now}")))

      # Add a Summary note
      $driver.find_element(:css => '#notes .subrecord-form-heading .btn:not(.show-all)').click
      $driver.find_last_element(:css => '#notes select.top-level-note-type').select_option_with_text("Summary")

      $driver.clear_and_send_keys([:id, 'digital_object_notes__0__label_'], "Summary label")
      $driver.execute_script("$('#digital_object_notes__0__content__0_').data('CodeMirror').setValue('Summary content')")
      $driver.execute_script("$('#digital_object_notes__0__content__0_').data('CodeMirror').save()")

      $driver.execute_script("$('#digital_object_notes__0__content__0_').data('CodeMirror').toTextArea()")
      $driver.find_element(:id => "digital_object_notes__0__content__0_").attribute("value").should eq("Summary content")

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

    it "can create a digital_object with one file version" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Digital Object").click

      $driver.clear_and_send_keys([:id, "digital_object_title_"],(digital_object_title))
      $driver.clear_and_send_keys([:id, "digital_object_digital_object_id_"],(Digest::MD5.hexdigest("#{Time.now}")))

      $driver.find_element(:id => 'digital_object_digital_object_type_').select_option_with_text("Mixed Materials")

      $driver.find_element(:css => "section#digital_object_file_versions_ > h3 > .btn:not(.show-all)").click

      $driver.clear_and_send_keys([:id, "digital_object_file_versions__0__file_uri_"], "/uri/for/this/file/version")
      $driver.clear_and_send_keys([:id , "digital_object_file_versions__0__file_size_bytes_"], '100')

      $driver.find_element(:css => "form#new_digital_object button[type='submit']").click

      # The new Digital Object shows up on the tree
      assert(5) { $driver.find_element(:css => "a.jstree-clicked").text.strip.should match(/#{digital_object_title}/) }
    end

    it "can handle multiple file versions and file system and network path types" do
      [
        '/root/top_secret.txt',
        'C:\Program Files\windows.exe',
        '\\\\SomeAwesome\Network\location.bat',
      ].each_with_index do |uri, idx|
        i = idx + 1
        $driver.find_element(:css => "section#digital_object_file_versions_ > h3 > .btn:not(.show-all)").click
        $driver.clear_and_send_keys([:id, "digital_object_file_versions__#{i}__file_uri_"], uri)
        $driver.find_element(:css => ".form-actions button[type='submit']").click
      end
      $driver.find_element(:link, "Close Record").click
      $driver.find_element_with_text('//h3', /File Versions/)
      $driver.find_element(:link, "Edit").click
    end

    it "reports errors if adding an empty child to a Digital Object" do
      $driver.find_element(:link, "Add Child").click

      # False start: create an object without filling it out
      $driver.click_and_wait_until_gone(:id => "createPlusOne")

      $driver.find_element_with_text('//div[contains(@class, "error")]', /you must provide/)
    end


    # Digital Object Component Nodes in Tree

    it "can populate the digital object component tree" do
      $driver.clear_and_send_keys([:id, "digital_object_component_title_"], "JPEG 2000 Verson of Image")
      $driver.clear_and_send_keys([:id, "digital_object_component_component_id_"],(Digest::MD5.hexdigest("#{Time.now}")))

      $driver.click_and_wait_until_gone(:id => "createPlusOne")

      ["PNG format", "GIF format", "BMP format"].each_with_index do |thing, idx|

        # Wait for the new empty form to be populated.  There's a tricky race
        # condition here that I can't quite track down, so here's my blunt
        # instrument fix.
        $driver.find_element(:xpath, "//textarea[@id='digital_object_component_title_' and not(text())]")

        $driver.clear_and_send_keys([:id, "digital_object_component_title_"],(thing))
        $driver.clear_and_send_keys([:id, "digital_object_component_label_"],(thing))
        $driver.clear_and_send_keys([:id, "digital_object_component_component_id_"],(Digest::MD5.hexdigest("#{thing}#{Time.now}")))

        $driver.find_element(:css => "section#digital_object_component_file_versions_ > h3 > .btn:not(.show-all)").click
        $driver.clear_and_send_keys([:id, "digital_object_component_file_versions__0__file_uri_"], "/uri/for/this/file/version")

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
      target.find_element_with_text(".//a", /ICO/)

      # refresh the page and verify that the change really stuck
      $driver.navigate.refresh

      target = $driver.find_element_with_text("//div[@id='archives_tree']//li", /Pony Express Digital Image/)
      target.find_element_with_text(".//a", /ICO/)

      $driver.click_and_wait_until_gone(:link, "Close Record")
      $driver.find_element(:xpath, "//a[@title='#{digital_object_title}']").click

      $driver.find_element_with_text("//h2", /#{digital_object_title}/)
    end


    it "applies i18n to the show view" do
      $driver.find_element_with_text("//div", /Mixed Materials/) # not mixed_materials
    end
    
    it "can merge a DO into a DO" do
      logout
      login("admin", "admin")
      
      select_repo($test_repo) 
      
      [ "Thing1", "Thing2"].each do |title| 
        create_digital_object( :title => title  )
      end
      run_index_round

      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Digital Objects").click
      
      $driver.clear_and_send_keys([:css, ".sidebar input.text-filter-field"], "Thing*" )
      $driver.find_element(:css, ".sidebar input.text-filter-field + div button").click
      # $driver.find_element(:css, ".span3 .icon-search").click 

      $driver.find_element_with_text('//tr', /Thing1/).find_element(:link, 'Edit').click

      $driver.find_element(:link, "Merge").click
      
      $driver.clear_and_send_keys([:id, "token-input-merge_ref_"], "Thing2" )
      $driver.find_element(:css, "li.token-input-dropdown-item2").click
      
      $driver.find_element(:css, "button.merge-button").click
      
      $driver.wait_for_ajax

      $driver.find_element_with_text("//h3", /Merge into this record\?/)
      $driver.find_element(:css, "button#confirmButton").click
      $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Digital object\(s\) Merged/)


    end

  end



  describe "User management" do

    before(:all) do
      @user = nil
    end
    
    before(:all) do
      @test_user = "test_user_#{Time.now.to_i}"
      @test_pass = "123456"
      @user_props = {   
                  :email => "#{@test_user}@aspace.org", :first_name => "first_#{@test_user}", 
                  :last_name => "last_#{@test_user}", :telephone => "555-555-5555", 
                  :title => "title_#{@test_user}", :department => "dept_#{@test_user}",
                  :additional_contact => "ac_#{@test_user}"}
    end

    after(:each) do
      logout
    end

    it "can create a user account" do
      login("admin", "admin")
      $driver.find_element(:link, 'System').click
      $driver.find_element(:link, "Manage Users").click

      $driver.find_element(:link, "Create User").click

      $driver.clear_and_send_keys([:id, "user_username_"], @test_user)
      $driver.clear_and_send_keys([:id, "user_name_"], @test_user)
      
      @user_props.each do |k,val|
        $driver.clear_and_send_keys([:id, "user_#{k.to_s}_"], val)
      end
      
      
      $driver.clear_and_send_keys([:id, "user_password_"], @test_pass)
      $driver.clear_and_send_keys([:id, "user_confirm_password_"], @test_pass)

      $driver.find_element(:id, 'create_account').click
      $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /User Created: /)
    end

   it "doesn't delete user information after the new user logins" do
      run_index_round
      $driver.navigate.refresh 
      sleep 5 
      $driver.find_element(:link, "Sign In").click
      $driver.clear_and_send_keys([:id, 'user_password'], @test_pass)
      $driver.clear_and_send_keys([:id, 'user_username'], @test_user)
       
      $driver.find_element(:id, 'login').click
      sleep 5 
      $driver.wait_for_ajax
      assert(5) { $driver.find_element(:css => "span.user-label").text.should match(/#{@test_user}/) }

      logout
     
      $driver.navigate.refresh 
      login("admin", "admin")
      $driver.find_element(:link, 'System').click
      $driver.find_element(:link, "Manage Users").click
      $driver.find_element( :xpath => "//td[contains(text(), '#{@test_user}')]/following-sibling::td/div/a").click
      @user_props.each do |k,val|
        assert(5) { $driver.find_element(:css=> "#user_#{k.to_s}_").attribute('value').should match(val) }
      end

   end

   it "doesn't allow you to edit the user short names" do
      login("admin", "admin")
      $driver.find_element(:link, 'System').click
      $driver.find_element(:link, "Manage Users").click
      $driver.find_element( :xpath => "//td[contains(text(), 'admin')]/following-sibling::td/div/a").click
      $driver.find_element(:id, "user_username_").attribute("readonly").should eq("true")
   end



  end


  describe "Context Sensitive Help" do

    before(:all) do
      login_as_repo_manager
    end


    after(:all) do
      logout
    end


    it "displays a clickable tooltip for a field label" do
      # navigate to the Accession form
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Accession").click

      # click on a field label

      # Use JQuery to trigger the handler to avoid hovering over the element too
      $driver.find_element(:css, "label[for='accession_title_']")
      $driver.execute_script("$('label[for=\"accession_title_\"]').triggerHandler(\"click\")")

      $driver.find_element(:css, ".tooltip.archivesspace-help")

      # can hide the tooltip
      $driver.find_element(:css, ".tooltip.archivesspace-help .tooltip-close").click

      assert(5) {
        $driver.ensure_no_such_element(:css, ".tooltip.archivesspace-help .tooltip-close")
      }
    end

  end


  describe "Users and authentication" do

    after(:all) do
      logout
    end


    it "fails logins with invalid credentials" do
      login("oopsie", "daisies")

      assert(5) { $driver.find_element(:css => "p.alert-danger").text.should eq('Login attempt failed') }

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

      assert(5) { $driver.find_element(:css => "span.user-label").text.should match(/#{@user}/) }
    end


    it "but they have no repositories yet!" do
      assert(5) {
        $driver.ensure_no_such_element(:link, "Select Repository")
      }
      logout
    end


    it "allows the admin user to become a different user" do
      login("admin", "admin")

      $driver.find_element(:css, '.user-container a.btn').click
      $driver.find_element(:link, "Become User").click
      $driver.clear_and_send_keys([:id, "select-user"], @user)
      $driver.find_element(:css, "#new_become_user .btn-primary").click
      $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Successfully switched users/)
    end

  end


  describe "Enumeration Management" do
    before(:all) do
      if !$test_repo
        ($test_repo, $test_repo_uri) = create_test_repo("repo_#{Time.now.to_i}_#{$$}", "description")
      end
      login("admin", "admin")
    end


    after(:all) do
      logout
    end


    it "lets you add a new value to an enumeration" do
      $driver.find_element(:link, 'System').click
      $driver.find_element(:link, "Manage Controlled Value Lists").click

      enum_select = $driver.find_element(:id => "enum_selector")
      enum_select.select_option_with_text("Accession Acquisition Type (accession_acquisition_type)")

      # Wait for the table of enumerations to load
      $driver.find_element(:css, '.enumeration-list')

      $driver.find_element(:link, 'Create Value').click
      $driver.clear_and_send_keys([:id, "enumeration_value_"], "manna\n")

      $driver.find_element_with_text('//td', /^manna$/)
    end


    it "lets you delete a value from an enumeration" do
      manna = $driver.find_element_with_text('//tr', /manna/)
      manna.find_element(:link, 'Delete').click

      $driver.find_element(:css => "form#delete_enumeration button[type='submit']").click

      $driver.find_element_with_text('//div', /Value Deleted/)

      $driver.ensure_no_such_element(:xpath, '//td[contains(text(), "manna")]')
    end


    it "lets you merge one value into another in an enumeration" do
      enum_a = "EnumA_#{Time.now.to_i}_#{$$}"
      enum_b = "EnumB_#{Time.now.to_i}_#{$$}"

      # create enum A
      $driver.find_element(:link, 'Create Value').click
      $driver.clear_and_send_keys([:id, "enumeration_value_"], "#{enum_a}\n")

      # create enum B
      $driver.find_element(:link, 'Create Value').click
      $driver.clear_and_send_keys([:id, "enumeration_value_"], "#{enum_b}\n")

      # merge enum B into A
      $driver.find_element(:xpath, "//a[contains(@href, \"#{enum_b}\")][contains(text(), \"Merge\")]").click

      #merge form is eventually displayed
      merge_form = $driver.find_element(:id, 'merge_enumeration')
      merge_form.find_element(:id, 'merge_into').select_option_with_text(enum_a)

      $driver.click_and_wait_until_gone(:css => "form#merge_enumeration button[type='submit']")

      $driver.find_element_with_text('//div', /Value Merged/)

      $driver.ensure_no_such_element(:xpath, "//td[contains(text(), \"#{enum_b}\")]")
    end


    it "lets you set a default enumeration (date_type)" do
      $driver.find_element(:link, 'System').click
      $driver.find_element(:link, "Manage Controlled Value Lists").click

      enum_select = $driver.find_element(:id => "enum_selector")
      enum_select.select_option_with_text("Date Type (date_type)")

      # Wait for the table of enumerations to load
      $driver.find_element(:css, '.enumeration-list')

      while true
        inclusive_dates = $driver.find_element_with_text('//tr', /Inclusive Dates/) 
        default_btn = inclusive_dates.find_elements(:link, 'Set as Default')

        if default_btn[0]
          default_btn[0].click
          # Keep looping until the 'Set as Default' button is gone
          $driver.wait_for_ajax 
          sleep 3 
        else
          break
        end
      end

      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Accession").click

      $driver.find_element(:css => '#accession_dates_ .subrecord-form-heading .btn:not(.show-all)').click

      date_type_select = $driver.find_element(:id => "accession_dates__0__date_type_")
      selected_type = date_type_select.get_select_value
      selected_type.should eq 'inclusive'

      # ensure that the correct subform is loading:
      subform = $driver.find_element(:css => '.date-type-subform')
      subform.find_element_with_text('//label', /Begin/)
      subform.find_element_with_text('//label', /End/)

      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")
    end

    it "lets you add a new value to an enumeration and then you can use it" do
      $driver.find_element(:link, 'System').click
      $driver.find_element(:link, "Manage Controlled Value Lists").click

      enum_select = $driver.find_element(:id => "enum_selector")
      enum_select.select_option_with_text("Collection Management Processing Priority (collection_management_processing_priority)")

      # Wait for the table of enumerations to load
      $driver.find_element(:css, '.enumeration-list')

      $driver.find_element(:link, 'Create Value').click
      $driver.clear_and_send_keys([:id, "enumeration_value_"], "IMPORTANT.\n")

      $driver.find_element_with_text('//td', /^IMPORTANT\.$/)
   
      # now lets make sure it's there
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Accession").click
     
      cm_accession_title = "CM Punk TEST"
      $driver.clear_and_send_keys([:id, "accession_title_"], cm_accession_title)
      $driver.complete_4part_id("accession_id_%d_", $driver.generate_4part_id)
      $driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
      $driver.clear_and_send_keys([:id, "accession_content_description_"], "STUFFZ")
      $driver.clear_and_send_keys([:id, "accession_condition_description_"], "stuffy")
     
      #now add collection management
      $driver.find_element(:css => '#accession_collection_management_ .subrecord-form-heading .btn:not(.show-all)').click

      $driver.clear_and_send_keys([:id => "accession_collection_management__cataloged_note_"], ["DONE!", :return])
      $driver.find_element(:id => "accession_collection_management__processing_priority_").select_option("IMPORTANT.")
      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      $driver.click_and_wait_until_gone(:link => cm_accession_title)

      assert(5) { $driver.find_element(:css => '#accession_collection_management__accordian div:last-child').text.include?("IMPORTANT.") }
    end
  end


  describe "Search" do

    before(:all) do
      login_as_repo_manager
    end


    after(:all) do
      logout
    end


    it "supports global searches" do
      $driver.find_element(:id, 'global-search-button').click
      assert(5) { $driver.find_element_with_text("//h2", /Search Results/) }
    end


    it "supports filtering global searches by type" do
      create_accession(:title => "A test accession #{Time.now.to_i}_#{$$}")
      run_index_round

      $driver.find_element(:id, 'global-search-button').click
      $driver.find_element(:link, "Accession").click
      assert(5) { $driver.find_element_with_text("//h5", /Filtered By/) }
      assert(5) { $driver.find_element_with_text("//a", /Record Type: Accession/) }
      assert(5) { $driver.find_element_with_text('//div', /Showing 1.* of.*Results/) }
    end

  end


  describe  "RDE" do

    before(:all) do
      login_as_archivist
      @resource_uri, @resource_title = create_resource
      run_index_round
    end


    after(:all) do
      logout
    end

    it "can view the RDE form when editing a resource" do
      # navigate to the edit resource page
      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Resources").click
      while true
        resource_row = $driver.find_element_with_text('//tr', /#{@resource_title}/, true, true)

        if resource_row
          resource_row.find_element(:link, "Edit").click
          break
        end

        # Try the next page of resources
        nextpage = $driver.find_elements(:xpath, '//a[@title="Next"]')
        if nextpage[0]
          nextpage[0].click
        else
          break
        end
      end


      $driver.find_element(:link, "Rapid Data Entry").click
      $driver.wait_for_ajax

      @modal = $driver.find_element(:id => "rapidDataEntryModal")
      @modal.find_element(:id, "archival_record_children_children__0__level_")
    end

    it "can review error messages on an invalid entry" do
      @modal = $driver.find_element(:id => "rapidDataEntryModal")

      @modal.find_element(:css, ".modal-footer .btn-primary").click

      # general message at the top
      @modal.find_element_with_text('//div[contains(@class, "alert-danger")]', /1 row\(s\) with an error \- click a row field to view the errors for that row/)

      # simulate focusing the row (normally done when the user focuses on an :input within the row)
      $driver.execute_script("$('#archival_record_children_children__0__title_').closest('tr').addClass('last-focused')")
      $driver.find_element(:css, ".error-summary")
      @modal.find_element_with_text('//div[contains(@class, "error")]', /Level of Description - Property is required but was missing/)

      @modal.find_element(:id, "archival_record_children_children__0__dates__0__date_type_").select_option("single")
      @modal.find_element(:css, ".modal-footer .btn-primary").click

      # make sure this form post is done.. then continue..
      $driver.wait_for_ajax

      # general message at the top
      @modal.find_element_with_text('//div[contains(@class, "alert-danger")]', /1 row\(s\) with an error \- click a row field to view the errors for that row/)

      # simulate focusing the row (normally done when the user focuses on an :input within the row)
      $driver.execute_script("$('#archival_record_children_children__0__title_').closest('tr').addClass('last-focused')")
      $driver.find_element(:css, ".error-summary")
      @modal.find_element_with_text('//div[contains(@class, "error")]', /Level of Description \- Property is required but was missing/)
      @modal.find_element_with_text('//div[contains(@class, "error")]', /Expression \- is required unless a begin or end date is given/)
      @modal.find_element_with_text('//div[contains(@class, "error")]', /Begin \- is required unless an expression or an end date is given/)
      @modal.find_element_with_text('//div[contains(@class, "error")]', /End \- is required unless an expression or a begin date is given/)
    end

    it "can add a child via the RDE form" do
      @modal = $driver.find_element(:id => "rapidDataEntryModal")

      @modal.find_element(:id, "archival_record_children_children__0__level_").select_option("item")
      $driver.clear_and_send_keys([:id, "archival_record_children_children__0__title_"], "My AO")
      $driver.clear_and_send_keys([:id, "archival_record_children_children__0__dates__0__begin_"], "2013")

      $driver.click_and_wait_until_gone(:css => ".modal-footer .btn-primary")

      $driver.wait_for_ajax

      assert(5) {
        $driver.find_element_with_text("//div[@id='archives_tree']//li//span", /My AO, 2013/)
        $driver.find_element_with_text("//div[@id='archives_tree']//li//span", /Item/)
      }
    end

    it "can access the RDE form when editing an archival object" do
      $driver.find_element(:css, "#archives_tree_toolbar .btn-next-tree-node").click
      $driver.wait_for_ajax

      $driver.find_element(:id, "archival_object_title_")

      $driver.find_element(:link, "Rapid Data Entry").click
      $driver.find_element(:id => "rapidDataEntryModal")
    end


    it "can add multiple children and sticky columns stick" do
      @modal = $driver.find_element(:id => "rapidDataEntryModal")

      @modal.find_element(:id, "archival_record_children_children__0__level_").select_option("fonds")
      @modal.find_element(:id, "archival_record_children_children__0__dates__0__date_type_").select_option("single")
      @modal.find_element(:id, "archival_record_children_children__0__publish_").click
      $driver.clear_and_send_keys([:id, "archival_record_children_children__0__dates__0__begin_"], "2013")
      $driver.clear_and_send_keys([:id, "archival_record_children_children__0__title_"], "Child 1")

      $driver.find_element_with_text("//div[@id='rapidDataEntryModal']//th", /Title/).click

      @modal.find_element(:css, ".btn.add-row").click
      @modal.find_element(:id, "archival_record_children_children__1__level_").get_select_value.should eq("fonds")
      @modal.find_element(:id, "archival_record_children_children__1__dates__0__date_type_").get_select_value.should eq("single")
      @modal.find_element(:id, "archival_record_children_children__1__publish_" ).attribute("checked").should be_true
      @modal.find_element(:id, "archival_record_children_children__1__dates__0__begin_").attribute("value").should eq("2013")
      @modal.find_element(:id, "archival_record_children_children__1__title_").attribute("value").should eq("Child 1")

      $driver.clear_and_send_keys([:id, "archival_record_children_children__1__title_"], "Child 2")

      $driver.click_and_wait_until_gone(:css => ".modal-footer .btn-primary")
      $driver.wait_for_ajax

      assert(5) {
        $driver.find_element_with_text("//div[@id='archives_tree']//li//span", /Child 1, 2013/)
        $driver.find_element_with_text("//div[@id='archives_tree']//li//span", /Child 2, 2013/)
      }
    end

    it "can add multiple rows in one action" do
      $driver.find_element(:link, "Rapid Data Entry").click
      @modal = $driver.find_element(:id => "rapidDataEntryModal")

      @modal.find_element(:id, "archival_record_children_children__0__level_").select_option("fonds")
      @modal.find_element(:id, "archival_record_children_children__0__publish_").click

      @modal.find_element(:css, ".btn.add-rows-dropdown").click
      #7.times { @modal.find_element(:css, ".add-rows-form input").send_keys(:arrow_up) } 
      $driver.wait_for_ajax
      $driver.clear_and_send_keys([:css, ".add-rows-form input"], "9") 
      
      # this is stupid, but seems to be a flakey issue with Selenium,
      # especailly when headless. The key is not being sent, so we'll try the 
      # up arror method to add the rows. 
      stupid = @modal.find_element(:css, ".add-rows-form input").attribute('value')
      unless stupid == '9'  
        9.times { @modal.find_element(:css, ".add-rows-form input").send_keys(:arrow_up) } 
      end 
      $driver.wait_for_ajax
      @modal.find_element(:css, ".add-rows-form .btn.btn-primary").click
      $driver.wait_for_ajax
      
      # there should be 10 rows now :)
      @modal.find_elements(:css, "table tbody tr").length.should eq(10)

      # all should have fonds as the level
      @modal.find_element(:id, "archival_record_children_children__1__level_").get_select_value.should eq("fonds")
      @modal.find_element(:id, "archival_record_children_children__2__level_").get_select_value.should eq("fonds")
      @modal.find_element(:id, "archival_record_children_children__3__level_").get_select_value.should eq("fonds")
      @modal.find_element(:id, "archival_record_children_children__4__level_").get_select_value.should eq("fonds")
      @modal.find_element(:id, "archival_record_children_children__5__level_").get_select_value.should eq("fonds")
      @modal.find_element(:id, "archival_record_children_children__6__level_").get_select_value.should eq("fonds")
      @modal.find_element(:id, "archival_record_children_children__7__level_").get_select_value.should eq("fonds")
      @modal.find_element(:id, "archival_record_children_children__8__level_").get_select_value.should eq("fonds")
      @modal.find_element(:id, "archival_record_children_children__9__level_").get_select_value.should eq("fonds")
      
      (1..9).each do |id|
        @modal.find_element(:id, "archival_record_children_children__#{id}__publish_" ).attribute("checked").should be_true
      end
    
    end

    it "can perform a basic fill" do
      @modal = $driver.find_element(:id => "rapidDataEntryModal")

      @modal.find_element(:css, ".btn.fill-column").click
      @modal.find_element(:id, "basicFillTargetColumn").select_option("colLevel")
      @modal.find_element(:id, "basicFillValue").select_option("item")
      $driver.click_and_wait_until_gone(:css, "#fill_basic .btn-primary")

      # all should have item as the level
      assert {
        @modal.find_element(:id, "archival_record_children_children__0__level_").get_select_value.should eq("item")
        @modal.find_element(:id, "archival_record_children_children__1__level_").get_select_value.should eq("item")
        @modal.find_element(:id, "archival_record_children_children__2__level_").get_select_value.should eq("item")
        @modal.find_element(:id, "archival_record_children_children__3__level_").get_select_value.should eq("item")
        @modal.find_element(:id, "archival_record_children_children__4__level_").get_select_value.should eq("item")
        @modal.find_element(:id, "archival_record_children_children__5__level_").get_select_value.should eq("item")
        @modal.find_element(:id, "archival_record_children_children__6__level_").get_select_value.should eq("item")
        @modal.find_element(:id, "archival_record_children_children__7__level_").get_select_value.should eq("item")
        @modal.find_element(:id, "archival_record_children_children__8__level_").get_select_value.should eq("item")
        @modal.find_element(:id, "archival_record_children_children__9__level_").get_select_value.should eq("item")
      }
    end

    it "can perform a sequence fill" do
      @modal = $driver.find_element(:id => "rapidDataEntryModal")

      @modal.find_element(:css, ".btn.fill-column").click
      @modal.find_element(:link, "Sequence").click

      @modal.find_element(:id, "sequenceFillTargetColumn").select_option("colCompId")
      $driver.clear_and_send_keys([:id, "sequenceFillPrefix"], "ABC")
      $driver.clear_and_send_keys([:id, "sequenceFillFrom"], "1")
      $driver.clear_and_send_keys([:id, "sequenceFillTo"], "5")
      $driver.click_and_wait_until_gone(:css, "#fill_sequence .btn-primary")

      # message should be displayed "not enough in the sequence" or thereabouts..
      @modal.find_element(:id, "sequenceTooSmallMsg")

      $driver.clear_and_send_keys([:id, "sequenceFillTo"], "10")
      $driver.click_and_wait_until_gone(:css, "#fill_sequence .btn-primary")

      # check the component id for each row matches the sequence
      assert {
        @modal.find_element(:id, "archival_record_children_children__0__component_id_").attribute("value").should eq("ABC1")
        @modal.find_element(:id, "archival_record_children_children__1__component_id_").attribute("value").should eq("ABC2")
        @modal.find_element(:id, "archival_record_children_children__2__component_id_").attribute("value").should eq("ABC3")
        @modal.find_element(:id, "archival_record_children_children__3__component_id_").attribute("value").should eq("ABC4")
        @modal.find_element(:id, "archival_record_children_children__4__component_id_").attribute("value").should eq("ABC5")
        @modal.find_element(:id, "archival_record_children_children__5__component_id_").attribute("value").should eq("ABC6")
        @modal.find_element(:id, "archival_record_children_children__6__component_id_").attribute("value").should eq("ABC7")
        @modal.find_element(:id, "archival_record_children_children__7__component_id_").attribute("value").should eq("ABC8")
        @modal.find_element(:id, "archival_record_children_children__8__component_id_").attribute("value").should eq("ABC9")
        @modal.find_element(:id, "archival_record_children_children__9__component_id_").attribute("value").should eq("ABC10")
      }
    end

    it "can perform a column reorder" do
      @modal = $driver.find_element(:id => "rapidDataEntryModal")

      @modal.find_element(:css, ".btn.reorder-columns").click

      # move Note Type 1 to the first position
      @modal.find_element(:id, "columnOrder").select_option("colNType1")
      17.times { @modal.find_element(:id, "columnOrderUp").click }

      # move Instance Type to the second position
      @modal.find_element(:id, "columnOrder").select_option("colNType1") # deselect Note Type 1
      @modal.find_element(:id, "columnOrder").select_option("colIType")
      9.times { @modal.find_element(:id, "columnOrderUp").click }

      # apply the new order
      $driver.click_and_wait_until_gone(:css, "#columnReorderForm .btn-primary")

      # check the first few headers now match the new order
      cells = @modal.find_elements(:css, "table .fieldset-labels th")
      cells[1].attribute("id").should eq("colNType1")
      cells[2].attribute("id").should eq("colIType")
      cells[3].attribute("id").should eq("colLevel")

      # check the section headers are correct
      cells = @modal.find_elements(:css, "table .sections th")
      cells[1].text.should eq("Notes")
      cells[1].attribute("colspan").should eq("1")
      cells[2].text.should eq("Instance")
      cells[2].attribute("colspan").should eq("1")
      cells[3].text.should eq("Basic Information")
      cells[3].attribute("colspan").should eq("5")

      # check the form fields match the headers
      cells = @modal.find_elements(:css, "table tbody tr:first-child td")
      cells[1].find_element(:id, "archival_record_children_children__0__notes__0__type_")
      cells[2].find_element(:id, "archival_record_children_children__0__instances__0__instance_type_")
      cells[3].find_element(:id, "archival_record_children_children__0__level_")
    end

  end


  describe  "Digital Object RDE" do

    before(:all) do
      login_as_archivist
      @digital_object_title = "Test Digital Object #{Time.now.to_i}#{$$}"
      create_digital_object({ :title => @digital_object_title})
      run_index_round
    end


    after(:all) do
      logout
    end

    it "can view the RDE form when editing a digital object" do
      # navigate to the edit resource page
      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Digital Objects").click

      while true
        row = $driver.find_element_with_text('//tr', /#{@digital_object_title}/, true, true)

        if row
          row.find_element(:link, "Edit").click
          break
        end

        # Try the next page of digital objects
        nextpage = $driver.find_elements(:xpath, '//a[@title="Next"]')
        if nextpage[0]
          nextpage[0].click
        else
          break
        end
      end


      $driver.find_element(:link, "Rapid Data Entry").click
      $driver.wait_for_ajax

      @modal = $driver.find_element(:id => "rapidDataEntryModal")
      @modal.find_element(:id, "digital_record_children_children__0__title_")
    end

    it "can review error messages on an invalid entry" do
      @modal = $driver.find_element(:id => "rapidDataEntryModal")

      @modal.find_element(:css, ".modal-footer .btn-primary").click

      # general message at the top
      @modal.find_element_with_text('//div[contains(@class, "alert-danger")]', /1 row\(s\) with an error \- click a row field to view the errors for that row/)

      # simulate focusing the row (normally done when the user focuses on an :input within the row)
      $driver.execute_script("$('#digital_record_children_children__0__title_').closest('tr').addClass('last-focused')")
      $driver.find_element(:css, ".error-summary")
      @modal.find_element_with_text('//div[contains(@class, "error")]', /Date - you must provide a Label, Title or Date/)
      @modal.find_element_with_text('//div[contains(@class, "error")]', /Title - you must provide a Label, Title or Date/)
      @modal.find_element_with_text('//div[contains(@class, "error")]', /Label - you must provide a Label, Title or Date/)

      @modal.find_element(:id, "digital_record_children_children__0__dates__0__date_type_").select_option("single")
      @modal.find_element(:css, ".modal-footer .btn-primary").click

      # make sure this form post is done.. then continue..
      $driver.wait_for_ajax

      # general message at the top
      @modal.find_element_with_text('//div[contains(@class, "alert-danger")]', /1 row\(s\) with an error \- click a row field to view the errors for that row/)

      # simulate focusing the row (normally done when the user focuses on an :input within the row)
      $driver.execute_script("$('#digital_record_children_children__0__title_').closest('tr').addClass('last-focused')")
      $driver.find_element(:css, ".error-summary")
      @modal.find_element_with_text('//div[contains(@class, "error")]', /Expression \- is required unless a begin or end date is given/)
      @modal.find_element_with_text('//div[contains(@class, "error")]', /Begin \- is required unless an expression or an end date is given/)
      @modal.find_element_with_text('//div[contains(@class, "error")]', /End \- is required unless an expression or a begin date is given/)
    end

    it "can add a child via the RDE form" do
      $driver.clear_and_send_keys([:id, "digital_record_children_children__0__title_"], "My DO")
      $driver.execute_script("$('#digital_record_children_children__0__dates__0__label_').val('')")
      $driver.execute_script("$('#digital_record_children_children__0__dates__0__date_type_').val('')")

      $driver.click_and_wait_until_gone(:css => ".modal-footer .btn-primary")

      $driver.wait_for_ajax

      assert(5) {
        $driver.find_element_with_text("//div[@id='archives_tree']//li//span", /My DO/)
      }
    end

    it "can access the RDE form when editing an digital object" do
      $driver.find_element(:css, "#archives_tree_toolbar .btn-next-tree-node").click
      $driver.wait_for_ajax

      $driver.find_element(:id, "digital_object_component_title_")

      $driver.find_element(:link, "Rapid Data Entry").click
      $driver.find_element(:id => "rapidDataEntryModal")
    end


    it "can add multiple children and sticky columns stick" do
      @modal = $driver.find_element(:id => "rapidDataEntryModal")

      $driver.clear_and_send_keys([:id, "digital_record_children_children__0__title_"], "Child 1")
      @modal.find_element(:css, ".btn.add-row").click

      @modal.find_element(:id, "digital_record_children_children__1__title_").attribute("value").should eq("Child 1")

      $driver.clear_and_send_keys([:id, "digital_record_children_children__1__title_"], "Child 2")

      $driver.click_and_wait_until_gone(:css => ".modal-footer .btn-primary")
      $driver.wait_for_ajax

      assert(5) {
        $driver.find_element_with_text("//div[@id='archives_tree']//li//span", /Child 1/)
        $driver.find_element_with_text("//div[@id='archives_tree']//li//span", /Child 2/)
      }
    end

    it "can add multiple rows in one action" do
      $driver.find_element(:link, "Rapid Data Entry").click
      @modal = $driver.find_element(:id => "rapidDataEntryModal")

      $driver.clear_and_send_keys([:id, "digital_record_children_children__0__label_"], "DO_LABEL")

      @modal.find_element(:css, ".btn.add-rows-dropdown").click
      
      # 8.times { @modal.find_element(:css, ".add-rows-form input").send_keys(:arrow_up) } 
      $driver.clear_and_send_keys([:css, ".add-rows-form input"], "9") 
      
      # this is stupid, but seems to be a flakey issue with Selenium,
      # especailly when headless. The key is not being sent, so we'll try the 
      # up arror method to add the rows. 
      stupid = @modal.find_element(:css, ".add-rows-form input").attribute('value')
      unless stupid == '9'  
        9.times { @modal.find_element(:css, ".add-rows-form input").send_keys(:arrow_up) } 
      end 
      
      @modal.find_element(:css, ".add-rows-form .btn.btn-primary").click

      # there should be 10 rows now :)
      @modal.find_elements(:css, "table tbody tr").length.should eq(10)

      # all should have level "DO_LABEL"
      @modal.find_element(:id, "digital_record_children_children__1__label_").attribute("value").should eq("DO_LABEL")
      @modal.find_element(:id, "digital_record_children_children__2__label_").attribute("value").should eq("DO_LABEL")
      @modal.find_element(:id, "digital_record_children_children__3__label_").attribute("value").should eq("DO_LABEL")
      @modal.find_element(:id, "digital_record_children_children__4__label_").attribute("value").should eq("DO_LABEL")
      @modal.find_element(:id, "digital_record_children_children__5__label_").attribute("value").should eq("DO_LABEL")
      @modal.find_element(:id, "digital_record_children_children__6__label_").attribute("value").should eq("DO_LABEL")
      @modal.find_element(:id, "digital_record_children_children__7__label_").attribute("value").should eq("DO_LABEL")
      @modal.find_element(:id, "digital_record_children_children__8__label_").attribute("value").should eq("DO_LABEL")
      @modal.find_element(:id, "digital_record_children_children__9__label_").attribute("value").should eq("DO_LABEL")
    end

    it "can perform a basic fill" do
      @modal = $driver.find_element(:id => "rapidDataEntryModal")

      @modal.find_element(:css, ".btn.fill-column").click
      @modal.find_element(:id, "basicFillTargetColumn").select_option("colLabel")
      $driver.clear_and_send_keys([:id, "basicFillValue"], "NEW_LABEL")
      $driver.click_and_wait_until_gone(:css, "#fill_basic .btn-primary")

      # all should have item as the level
      assert {
        @modal.find_element(:id, "digital_record_children_children__0__label_").attribute("value").should eq("NEW_LABEL")
        @modal.find_element(:id, "digital_record_children_children__1__label_").attribute("value").should eq("NEW_LABEL")
        @modal.find_element(:id, "digital_record_children_children__2__label_").attribute("value").should eq("NEW_LABEL")
        @modal.find_element(:id, "digital_record_children_children__3__label_").attribute("value").should eq("NEW_LABEL")
        @modal.find_element(:id, "digital_record_children_children__4__label_").attribute("value").should eq("NEW_LABEL")
        @modal.find_element(:id, "digital_record_children_children__5__label_").attribute("value").should eq("NEW_LABEL")
        @modal.find_element(:id, "digital_record_children_children__6__label_").attribute("value").should eq("NEW_LABEL")
        @modal.find_element(:id, "digital_record_children_children__7__label_").attribute("value").should eq("NEW_LABEL")
        @modal.find_element(:id, "digital_record_children_children__8__label_").attribute("value").should eq("NEW_LABEL")
        @modal.find_element(:id, "digital_record_children_children__9__label_").attribute("value").should eq("NEW_LABEL")
      }
    end

    it "can perform a sequence fill" do
      @modal = $driver.find_element(:id => "rapidDataEntryModal")

      @modal.find_element(:css, ".btn.fill-column").click
      @modal.find_element(:link, "Sequence").click

      @modal.find_element(:id, "sequenceFillTargetColumn").select_option("colTitle")
      $driver.clear_and_send_keys([:id, "sequenceFillPrefix"], "ABC")
      $driver.clear_and_send_keys([:id, "sequenceFillFrom"], "1")
      $driver.clear_and_send_keys([:id, "sequenceFillTo"], "5")
      $driver.click_and_wait_until_gone(:css, "#fill_sequence .btn-primary")

      # message should be displayed "not enough in the sequence" or thereabouts..
      @modal.find_element(:id, "sequenceTooSmallMsg")

      $driver.clear_and_send_keys([:id, "sequenceFillTo"], "10")
      $driver.click_and_wait_until_gone(:css, "#fill_sequence .btn-primary")

      # check the component id for each row matches the sequence
      assert {
        @modal.find_element(:id, "digital_record_children_children__0__title_").attribute("value").should eq("ABC1")
        @modal.find_element(:id, "digital_record_children_children__1__title_").attribute("value").should eq("ABC2")
        @modal.find_element(:id, "digital_record_children_children__2__title_").attribute("value").should eq("ABC3")
        @modal.find_element(:id, "digital_record_children_children__3__title_").attribute("value").should eq("ABC4")
        @modal.find_element(:id, "digital_record_children_children__4__title_").attribute("value").should eq("ABC5")
        @modal.find_element(:id, "digital_record_children_children__5__title_").attribute("value").should eq("ABC6")
        @modal.find_element(:id, "digital_record_children_children__6__title_").attribute("value").should eq("ABC7")
        @modal.find_element(:id, "digital_record_children_children__7__title_").attribute("value").should eq("ABC8")
        @modal.find_element(:id, "digital_record_children_children__8__title_").attribute("value").should eq("ABC9")
        @modal.find_element(:id, "digital_record_children_children__9__title_").attribute("value").should eq("ABC10")
      }
    end

    it "can perform a column reorder" do
      @modal = $driver.find_element(:id => "rapidDataEntryModal")

      @modal.find_element(:css, ".btn.reorder-columns").click

      # move Note Type 1 to the first position
      @modal.find_element(:id, "columnOrder").select_option("colNType1")
      20.times { @modal.find_element(:id, "columnOrderUp").click }

      # move Instance Type to the second position
      @modal.find_element(:id, "columnOrder").select_option("colNType1") # deselect Note Type 1
      @modal.find_element(:id, "columnOrder").select_option("colFUri")
      10.times { @modal.find_element(:id, "columnOrderUp").click }

      # apply the new order
      $driver.click_and_wait_until_gone(:css, "#columnReorderForm .btn-primary")

      # check the first few headers now match the new order
      cells = @modal.find_elements(:css, "table .fieldset-labels th")
      cells[1].attribute("id").should eq("colNType1")
      cells[2].attribute("id").should eq("colFUri")
      cells[3].attribute("id").should eq("colLabel")

      # check the section headers are correct
      cells = @modal.find_elements(:css, "table .sections th")
      cells[1].text.should eq("Notes")
      cells[1].attribute("colspan").should eq("1")
      cells[2].text.should eq("File Version")
      cells[2].attribute("colspan").should eq("1")
      cells[3].text.should eq("Basic Information")
      cells[3].attribute("colspan").should eq("5")

      # check the form fields match the headers
      cells = @modal.find_elements(:css, "table tbody tr:first-child td")
      cells[1].find_element(:id, "digital_record_children_children__0__notes__0__type_")
      cells[2].find_element(:id, "digital_record_children_children__0__file_versions__0__file_uri_")
      cells[3].find_element(:id, "digital_record_children_children__0__label_")
    end

  end



  describe "Locations" do

    before(:all) do
      login_as_repo_manager
    end


    after(:all) do
      logout
    end

    it "allows access to the single location form" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Location").click
      $driver.find_element(:link, "Single Location").click
    end

    it "displays error messages upon invalid location" do
      $driver.click_and_wait_until_gone(:css => "form#new_location .btn-primary")

      $driver.find_element_with_text('//div[contains(@class, "error")]', /Building - Property is required but was missing/)

      $driver.clear_and_send_keys([:id, "location_building_"], "129 W. 81st St")
      $driver.click_and_wait_until_gone(:css => "form#new_location .btn-primary")

      $driver.find_element_with_text('//div[contains(@class, "error")]', /You must either specify a barcode, a classification, or both a coordinate 1 label and coordinate 1 indicator/)
    end

    it "saves a valid location" do
      $driver.clear_and_send_keys([:id, "location_floor_"], "5")
      $driver.clear_and_send_keys([:id, "location_room_"], "5 MOO")

      $driver.clear_and_send_keys([:id, "location_coordinate_1_label_"], "Box XYZ")
      $driver.clear_and_send_keys([:id, "location_coordinate_1_indicator_"], "XYZ0001")

      $driver.click_and_wait_until_gone(:css => "form#new_location .btn-primary")

      $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Location Created/)
    end

    it "allows locations to be edited" do
      $driver.clear_and_send_keys([:id, "location_room_"], "5A")
      $driver.click_and_wait_until_gone(:css => "form#new_location .btn-primary")

      $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Location Saved/)
    end

    it "lists the new location in the browse list" do
      run_index_round

      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Locations").click

      $driver.find_element_with_text('//td', /129 W\. 81st St\, 5\, 5A \[Box XYZ\: XYZ0001\]/)
    end

    it "lists the new location for an archivist" do
      logout
      login_as_archivist

      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Locations").click

      $driver.find_element_with_text('//td', /129 W\. 81st St\, 5\, 5A \[Box XYZ\: XYZ0001\]/)
    end

    it "doesn't offer location edit actions to an archivist" do
      assert(100) {
        $driver.ensure_no_such_element(:link, "Create Location")
        $driver.ensure_no_such_element(:link, "Batch Locations")
        $driver.ensure_no_such_element(:link, "Edit")
      }

      $driver.find_element(:link, "View").click

      assert(100) {
        $driver.ensure_no_such_element(:link, "Edit")
      }
    end

    it "lists the location in different repositories" do
      logout
      login_as_admin

      new_repo_code = "locationtest#{Time.now.to_i}_#{$$}"
      new_repo_name = "locationtest repository - #{Time.now}"

      create_test_repo(new_repo_code, new_repo_name)

      $driver.navigate.refresh

      select_repo(new_repo_code)

      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Locations").click

      $driver.find_element_with_text('//td', /129 W\. 81st St\, 5\, 5A \[Box XYZ\: XYZ0001\]/)
    end

  end


  describe "Location batch" do

    before(:all) do
      login_as_repo_manager
    end


    after(:all) do
      logout
    end

    it "displays error messages upon invalid batch" do
      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Locations").click
      $driver.find_element(:link, "Batch Locations").click

      $driver.click_and_wait_until_gone(:css => "form#new_location_batch .btn-primary")

      $driver.find_element_with_text('//div[contains(@class, "error")]', /Building - Property is required but was missing/)
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Coordinate Range 1 - Property is required but was missing/)
    end

    it "can preview the titles of locations that will be created" do
      $driver.clear_and_send_keys([:id, "location_batch_building_"], "123 Awesome Street")
      $driver.clear_and_send_keys([:id, "location_batch_coordinate_1_range__label_"], "Room")
      $driver.clear_and_send_keys([:id, "location_batch_coordinate_1_range__start_"], "1A")
      $driver.clear_and_send_keys([:id, "location_batch_coordinate_1_range__end_"], "1B")
      $driver.clear_and_send_keys([:id, "location_batch_coordinate_2_range__label_"], "Shelf")
      $driver.clear_and_send_keys([:id, "location_batch_coordinate_2_range__start_"], "1")
      $driver.clear_and_send_keys([:id, "location_batch_coordinate_2_range__end_"], "4")

      $driver.click_and_wait_until_gone(:css => "form#new_location_batch .btn.preview-locations")

      modal = $driver.find_element(:id, "batchPreviewModal")
      $driver.wait_for_ajax

      $driver.find_element_with_text('//div[@id="batchPreviewModal"]//li', /123 Awesome Street \[Room: 1A, Shelf: 1\]/)
      $driver.find_element_with_text('//div[@id="batchPreviewModal"]//li', /123 Awesome Street \[Room: 1A, Shelf: 2\]/)
      $driver.find_element_with_text('//div[@id="batchPreviewModal"]//li', /123 Awesome Street \[Room: 1A, Shelf: 3\]/)
      $driver.find_element_with_text('//div[@id="batchPreviewModal"]//li', /123 Awesome Street \[Room: 1A, Shelf: 4\]/)
      $driver.find_element_with_text('//div[@id="batchPreviewModal"]//li', /123 Awesome Street \[Room: 1B, Shelf: 1\]/)
      $driver.find_element_with_text('//div[@id="batchPreviewModal"]//li', /123 Awesome Street \[Room: 1B, Shelf: 2\]/)
      $driver.find_element_with_text('//div[@id="batchPreviewModal"]//li', /123 Awesome Street \[Room: 1B, Shelf: 3\]/)
      $driver.find_element_with_text('//div[@id="batchPreviewModal"]//li', /123 Awesome Street \[Room: 1B, Shelf: 4\]/)

      $driver.click_and_wait_until_gone(:css, ".modal-footer button")
    end

    it "creates all the locations for the range" do
      $driver.click_and_wait_until_gone(:css => "form#new_location_batch .btn-primary")

      $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /8 Locations Created/)

      run_index_round
      $driver.navigate.refresh

      $driver.find_element_with_text('//td', /123 Awesome Street \[Room: 1A, Shelf: 1\]/)
      $driver.find_element_with_text('//td', /123 Awesome Street \[Room: 1A, Shelf: 2\]/)
      $driver.find_element_with_text('//td', /123 Awesome Street \[Room: 1A, Shelf: 3\]/)
      $driver.find_element_with_text('//td', /123 Awesome Street \[Room: 1A, Shelf: 4\]/)
      $driver.find_element_with_text('//td', /123 Awesome Street \[Room: 1B, Shelf: 1\]/)
      $driver.find_element_with_text('//td', /123 Awesome Street \[Room: 1B, Shelf: 2\]/)
      $driver.find_element_with_text('//td', /123 Awesome Street \[Room: 1B, Shelf: 3\]/)
      $driver.find_element_with_text('//td', /123 Awesome Street \[Room: 1B, Shelf: 4\]/)
    end

  end


  describe "Classifications" do

    before(:all) do
      login_as_admin

      @classification_agent_uri, @classification_agent_name = create_agent("Classification Agent #{Time.now.to_i}_#{$$}")
      run_index_round
    end


    after(:all) do
      logout
    end


    test_classification = "Classification #{Time.now.to_i}_#{$$}"
    test_classification_term = "Classification Term #{Time.now.to_i}_#{$$}"

    it "allows you to create a classification tree" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Classification").click

      $driver.clear_and_send_keys([:id, 'classification_identifier_'], "10")
      $driver.clear_and_send_keys([:id, 'classification_title_'], test_classification)

      token_input = $driver.find_element(:id, "token-input-classification_creator__ref_")
      token_input.clear
      token_input.click
      token_input.send_keys(@classification_agent_name)
      $driver.find_element(:css, "li.token-input-dropdown-item2").click

      $driver.click_and_wait_until_gone(:css => "form#classification_form button[type='submit']")

      $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Classification.*created/i)

      $driver.find_element_with_text('//div[contains(@class, "agent_person")]', /#{@classification_agent_name}/i)
    end


    it "allows you to create a classification term" do
      $driver.find_element(:link, "Add Child").click

      $driver.clear_and_send_keys([:id, 'classification_term_identifier_'], "11")
      $driver.clear_and_send_keys([:id, 'classification_term_title_'], test_classification_term)

      token_input = $driver.find_element(:id, "token-input-classification_term_creator__ref_")
      token_input.clear
      token_input.click
      token_input.send_keys(@classification_agent_name)
      $driver.find_element(:css, "li.token-input-dropdown-item2").click

      $driver.click_and_wait_until_gone(:css => "form#classification_term_form button[type='submit']")

      $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Classification Term.*created/i)

      $driver.find_element_with_text('//div[contains(@class, "agent_person")]', /#{@classification_agent_name}/i)
    end


    it "allows you to link a resource to a classification" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Resource").click

      $driver.clear_and_send_keys([:id, "resource_title_"], "a resource")
      $driver.complete_4part_id("resource_id_%d_")
      combo = $driver.find_element(:xpath => '//div[@class="combobox-container"][following-sibling::select/@id="resource_language_"]//input[@type="text"]');
      combo.clear
      combo.click
      combo.send_keys("eng")
      combo.send_keys(:tab)
      $driver.find_element(:id, "resource_level_").select_option("collection")
      $driver.clear_and_send_keys([:id, "resource_extents__0__number_"], "10")
      $driver.find_element(:id => "resource_extents__0__extent_type_").select_option("files")
      
      $driver.find_element(:id => "resource_dates__0__date_type_").select_option("single")
      $driver.clear_and_send_keys([:id, "resource_dates__0__begin_"], "1978")

      # Now add a classification
      $driver.find_element(:css => '#resource_classification_ .subrecord-form-heading .btn:not(.show-all)').click

      assert(5) {
        run_index_round
        $driver.clear_and_send_keys([:id, "token-input-resource_classification__ref_"],
                                    test_classification)
        $driver.find_element(:css, "li.token-input-dropdown-item2").click
      }

      $driver.click_and_wait_until_gone(:css => "form#resource_form button[type='submit']")
      $driver.click_and_wait_until_gone(:link, "Close Record")

      $driver.find_element(:css => 'div.token.classification').text.should match(/#{test_classification}/)
    end


    it "allows you to link an accession to a classification" do
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Accession").click

      accession_title = "Tomorrow's Harvest"
      accession_4part_id = $driver.generate_4part_id

      $driver.clear_and_send_keys([:id, "accession_title_"], accession_title)
      $driver.complete_4part_id("accession_id_%d_", accession_4part_id)

      $driver.clear_and_send_keys([:id, "accession_accession_date_"], "2013-06-11")

      # Now add a classification
      $driver.find_element(:css => '#accession_classification_ .subrecord-form-heading .btn:not(.show-all)').click

      assert(5) {
        run_index_round
        $driver.clear_and_send_keys([:id, "token-input-accession_classification__ref_"],
                                    test_classification)
        $driver.find_element(:css, "li.token-input-dropdown-item2").click
      }

      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      $driver.click_and_wait_until_gone(:link => accession_title)

      $driver.find_element(:css => 'div.token.classification').text.should match(/#{test_classification}/)
    end


  end

  describe "User Preferences" do

    before(:all) do
      login_as_admin
    end


    after(:all) do
      logout
    end


    it "allows you to configure browse columns" do
      create_accession(:title => "a browseable accession")
      run_index_round

      $driver.find_element(:css, '.user-container .btn.dropdown-toggle.last').click
      $driver.find_element(:link, "My Repository Preferences").click

      $driver.find_element(:id => "preference_defaults__accession_browse_column_1_").select_option_with_text("Acquisition Type")
      $driver.find_element(:css => 'button[type="submit"]').click
      $wait.until { $driver.find_element(:css => ".alert-success") }

      $driver.find_element(:link => 'Browse').click
      $driver.find_element(:link => 'Accessions').click
      $wait.until { $driver.find_element(:link => "Create Accession") }

      cells = $driver.find_elements(:css, "table th")
      cells[1].text.should eq("Title")
      cells[2].text.should eq("Acquisition Type")
    end

  end

  describe "Advanced Search" do

    before(:all) do
      login_as_repo_manager

      @keywords = (0..9).to_a.map { SecureRandom.hex }

      @accession_1_title = create_accession(:title => "#{@keywords[0]} #{@keywords[4]}", :publish => true)
      @accession_2_title = create_accession(:title => "#{@keywords[1]} #{@keywords[5]}", :publish => false)
      @resource_1_title = create_resource(:title => "#{@keywords[0]} #{@keywords[6]}", :publish => false)[1]
      @resource_2_title = create_resource(:title => "#{@keywords[2]} #{@keywords[7]}", :publish => true)[1]
      @digital_object_1_title = create_digital_object(:title => "#{@keywords[0]} #{@keywords[8]}")[1]
      @digital_object_2_title = create_digital_object(:title => "#{@keywords[3]} #{@keywords[9]}")[1]

      run_index_round
    end


    after(:all) do
      logout
    end


    it "is available via the navbar and renders when toggled" do
      $driver.find_element(:css => ".navbar .search-switcher").click

      assert(10) {
        advanced_search_form = $driver.find_element(:css => "form.advanced-search")
        advanced_search_form.find_element(:id => "v0")
        advanced_search_form.find_element(:css => ".btn-primary")
      }
    end


    it "finds matches with one keyword field query" do
      $driver.clear_and_send_keys([:id => "v0"], @keywords[0])

      $driver.click_and_wait_until_gone(:css => ".advanced-search .btn-primary")

      # result list should contain those items with the @keywords[0] in the title
      $driver.find_element_with_text("//td", /#{@accession_1_title}/)
      $driver.find_element_with_text("//td", /#{@resource_1_title}/)
      $driver.find_element_with_text("//td", /#{@digital_object_1_title}/)

      # these records should not appear in the results
      $driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@accession_2_title}')]")
      $driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@resource_2_title}')]")
      $driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@digital_object_2_title}')]")
    end


    it "finds single match with two keyword ANDed field queries" do
      # add a 2nd query row
      $driver.find_element(:css => ".advanced-search-add-row-dropdown").click
      $driver.find_element(:css => ".advanced-search-add-text-row").click

      $driver.clear_and_send_keys([:id => "v0"], @keywords[0])
      $driver.clear_and_send_keys([:id => "v1"], @keywords[4])
      $driver.find_element(:id => "f1").select_option("title")

      $driver.click_and_wait_until_gone(:css => ".advanced-search .btn-primary")

      # result list should contain those items with a keyword @keywords[0]
      # and with the title containing @keywords[4]
      $driver.find_element_with_text("//td", /#{@accession_1_title}/)

      # and these results should no longer be there
      $driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@resource_1_title}')]")
      $driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@digital_object_1_title}')]")

      # these records should not appear in the results
      $driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@accession_2_title}')]")
      $driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@resource_2_title}')]")
      $driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@digital_object_2_title}')]")
    end

    it "finds matches with two keyword ORed field queries" do
      $driver.find_element(:id => "op1").select_option("OR")

      $driver.click_and_wait_until_gone(:css => ".advanced-search .btn-primary")

      # result list should contain those items with both @keywords[0] and @keywords[4]
      $driver.find_element_with_text("//td", /#{@accession_1_title}/)
      $driver.find_element_with_text("//td", /#{@resource_1_title}/)
      $driver.find_element_with_text("//td", /#{@digital_object_1_title}/)

      # these records should not appear in the results
      $driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@accession_2_title}')]")
      $driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@resource_2_title}')]")
      $driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@digital_object_2_title}')]")
    end


    it "finds matches with two keyword joined AND NOTed field queries" do
      $driver.find_element(:id => "op1").select_option("NOT")

      $driver.click_and_wait_until_gone(:css => ".advanced-search .btn-primary")

      # result list should contain those items with both @keywords[0] and NOT @keywords[4]
      $driver.find_element_with_text("//td", /#{@resource_1_title}/)
      $driver.find_element_with_text("//td", /#{@digital_object_1_title}/)
      $driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@accession_1_title}')]")

      # these records should not appear in the results
      $driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@accession_2_title}')]")
      $driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@resource_2_title}')]")
      $driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@digital_object_2_title}')]")
    end


    it "clear resets the fields" do
      $driver.click_and_wait_until_gone(:css => ".advanced-search .reset-advanced-search")

      $driver.find_element(:id => "v0").attribute("value").should eq("")
    end

    it "allow adding of mulitple rows of the same type" do
      # in response to a bug
      $driver.find_element(:css => ".advanced-search-add-row-dropdown").click
      $driver.find_element(:css => ".advanced-search-add-bool-row").click
      $driver.find_element(:css => ".advanced-search-add-row-dropdown").click
      $driver.find_element(:css => ".advanced-search-add-bool-row").click

      $driver.find_element(:id => "v1")
      $driver.find_element(:id => "v2")

      $driver.click_and_wait_until_gone(:css => ".advanced-search .reset-advanced-search")
    end

    it "filters records based on a boolean search" do
      # Let's find all records with keyword 1
      $driver.clear_and_send_keys([:id => "v0"], @keywords[0])
      $driver.find_element(:id => "f0").select_option("title")

      $driver.click_and_wait_until_gone(:css => ".advanced-search .btn-primary")

      $driver.find_element_with_text("//td", /#{@accession_1_title}/)
      $driver.find_element_with_text("//td", /#{@resource_1_title}/)

      # add a boolean field row
      $driver.find_element(:css => ".advanced-search-add-row-dropdown").click
      $driver.find_element(:css => ".advanced-search-add-bool-row").click

      # let's only find those that are unpublished
      $driver.find_element(:id => "f1").select_option("published")
      $driver.find_element(:id => "v1").select_option("false")

      $driver.click_and_wait_until_gone(:css => ".advanced-search .btn-primary")

      $driver.find_element_with_text("//td", /#{@resource_1_title}/)
      $driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@accession_1_title}')]")

      # now let's flip it to find those that are published
      $driver.find_element(:id => "v1").select_option("true")

      $driver.click_and_wait_until_gone(:css => ".advanced-search .btn-primary")

      $driver.find_element_with_text("//td", /#{@accession_1_title}/)
      $driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@resource_1_title}')]")

    end


    it "filters records based on a date field search" do
      $driver.find_element(:css => ".advanced-search-add-row-dropdown").click
      $driver.find_element(:css => ".advanced-search-add-date-row").click

      # let's find all records created after 2014
      $driver.clear_and_send_keys([:id => "v2"], "2012-01-01")
      $driver.find_element(:id => "op2").select_option("AND")
      $driver.find_element(:id => "f2").select_option("create_time")
      $driver.find_element(:id => "dop2").select_option("greater_than")

      $driver.click_and_wait_until_gone(:css => ".advanced-search .btn-primary")

      $driver.find_element_with_text("//td", /#{@accession_1_title}/)

      # change to lesser than.. there should be no results!
      $driver.find_element(:id => "dop2").select_option("lesser_than")

      $driver.click_and_wait_until_gone(:css => ".advanced-search .btn-primary")

      $driver.find_element_with_text('//p[contains(@class, "alert-info")]', /No records found/)
    end


    it "hides when toggled" do
      advanced_search_form = $driver.find_element(:css => "form.advanced-search")

      $driver.find_element(:link => "Hide Advanced Search").click

      assert(10) {
        advanced_search_form.displayed?.should be_false
      }
    end


    it "doesn't display when a normal search is performed" do
      $driver.clear_and_send_keys([:id => "global-search-box"], @keywords[0])
      $driver.find_element(:id => "global-search-button").click

      $driver.ensure_no_such_element(:css => "form.advanced-search")
    end
  end


  describe "Permissions" do

    before(:all) do
      @perm_test_repo = "perm_test#{Time.now.to_i}_#{$$}"
      (moo, @repo_uri) = create_test_repo(@perm_test_repo, "The name of the #{@perm_test_repo}")
      (@archivist, @pass) = create_user
      add_user_to_archivists(@archivist, @repo_uri)
    end


    it "allows archivists to edit major record types by default" do
      login(@archivist, @pass)
      select_repo(@perm_test_repo)
      $driver.find_element(:link => 'Create').click
      $driver.find_element(:link => 'Accession').click
      $driver.find_element(:link => 'Create').click
      $driver.find_element(:link => 'Resource').click
      $driver.find_element(:link => 'Create').click
      $driver.find_element(:link => 'Digital Object').click
      logout
    end


    it "supports denying permission to edit Resources" do
      login_as_admin
      select_repo(@perm_test_repo)
      $driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
      $driver.find_element(:link, "Manage Groups").click

      row = $driver.find_element_with_text('//tr', /repository-archivists/)
      row.find_element(:link, 'Edit').click
      $driver.find_element(:xpath, '//input[@id="update_resource_record"]').click
      $driver.find_element(:css => 'button[type="submit"]').click
      logout
      login(@archivist, @pass)
      select_repo(@perm_test_repo)
      $driver.find_element(:link => 'Create').click
      $driver.ensure_no_such_element(:link, "Resource")
      logout
    end

  end


  describe "Collection Management" do

    before(:all) do
      new_repo_code = "collection_management_test_#{Time.now.to_i}_#{$$}"
      new_repo_name = "collection_managment test repository - #{Time.now}"
      (moo, repo_uri) = create_test_repo(new_repo_code, new_repo_name)
      (archivist, pass) = create_user
      add_user_to_archivists(archivist, repo_uri)


      login(archivist, pass)
      select_repo(new_repo_code)
    end

    after(:all) do
      logout
    end

    it "should be fine with no records" do
      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Collection Management").click
      assert(5) { $driver.find_element(:css => ".alert.alert-info").text.should eq("No records found") }  
    end
    
    
    it "is browseable even when its linked accession has no title" do
      # first create the title-less accession
      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Accession").click
      fourid = $driver.generate_4part_id
      $stderr.puts(fourid)
      $driver.complete_4part_id("accession_id_%d_", fourid)
#      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      # add a collection management sub record
      $driver.find_element(:css => '#accession_collection_management_ .subrecord-form-heading .btn:not(.show-all)').click

      $driver.clear_and_send_keys([:id => "accession_collection_management__cataloged_note_"], ["yikes, my accession has no title", :return])
      $driver.find_element(:id => "accession_collection_management__processing_status_").select_option("completed")

      # save changes
      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")
     
      run_all_indexers
      # check the CM page
      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Collection Management").click
     
    
      expect {
        $driver.find_element_with_text('//td', /#{fourid}/ )
      }.to_not raise_error     
      
      $driver.click_and_wait_until_gone(:link, 'View')
      $driver.click_and_wait_until_gone(:link, 'Edit')
     
      # now delete it
      $driver.find_element(:css => '#accession_collection_management_ .subrecord-form-remove').click
      $driver.find_element(:css => '#accession_collection_management_ .confirm-removal').click 
      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")
    
      run_all_indexers

      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Collection Management").click
      
      $driver.find_element_with_text('//td', /#{fourid}/, true, true).should eq(nil)
      

    end

  end

  describe "System Information" do


    
    after(:each) do
      logout
    end

    it "should not let any old fool see this" do
      @perm_test_repo = "perm_test#{Time.now.to_i}_#{$$}"
      (moo, @repo_uri) = create_test_repo(@perm_test_repo, "The name of the #{@perm_test_repo}")
      (@archivist, @pass) = create_user
      add_user_to_archivists(@archivist, @repo_uri)
      
      login(@archivist, @pass)
      
      $driver.find_element(:link, "System").click
      $driver.find_elements(:link, "System Information").length.should eq(0)
      $driver.get(URI.join($frontend, "/system_info"))
      assert(5) { 
        $driver.find_element(:css => ".alert.alert-danger h2").text.should eq("Unable to Access Page")
      } 
   
    end
    
    it "should let the admin see this" do
      login_as_admin
      
      $driver.find_element(:link, "System").click
      $driver.find_element(:link, "System Information").click
      assert(5) { 
        $driver.find_element(:css => "h3.subrecord-form-heading").text.should eq("Frontend System Information")
      } 
    
    end
  end
end
