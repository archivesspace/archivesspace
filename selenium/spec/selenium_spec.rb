require_relative 'spec_helper'
require_relative '../../indexer/app/lib/realtime_indexer'



describe "ArchivesSpace user interface" do

  # Start the dev servers and Selenium
  before(:all) do
    selenium_init($backend_start_fn, $frontend_start_fn)
    @indexer = RealtimeIndexer.new($backend, nil)
  end


  def run_index_round
    @last_sequence ||= 0
    @last_sequence = @indexer.run_index_round(@last_sequence)
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

      assert(5) { $driver.find_element(:css => "div.alert.alert-error").text.should eq('Repository Short Name - Property is required but was missing') }
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
      row.find_element(:css, '.btn').click

      $driver.clear_and_send_keys([:id, 'new-member'],(@user))
      $driver.find_element(:id, 'add-new-member').click
      $driver.find_element(:css => 'input[type="submit"]').click
    end


    it "can assign the test user to the viewers group of the first repository" do
      select_repo(@can_view_repo)

      $driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
      $driver.find_element(:link, "Manage Groups").click

      row = $driver.find_element_with_text('//tr', /repository-viewers/)
      row.find_element(:css, '.btn').click

      $driver.clear_and_send_keys([:id, 'new-member'],(@user))
      $driver.find_element(:id, 'add-new-member').click
      $driver.find_element(:css => 'input[type="submit"]').click
    end


    it "reports errors when attempting to create a Group with missing data" do
      $driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
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

      $driver.find_element(:css => '#subject_external_documents_ .subrecord-form-heading .btn').click

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
      $driver.find_element(:css => '#subject_terms_ .subrecord-form-heading .btn').click
      $driver.clear_and_send_keys([:id, "subject_terms__0__term_"], "just a term really #{now}")
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
      assert(5) { $driver.find_element(:css => '.record-pane h2').text.should eq("just a term really #{now} Subject") }
    end


    it "can present a browse list of Subjects" do
      run_index_round

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
      $driver.execute_script("$('.nav .dropdown-submenu a:contains(Agent)').focus()")
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


    it "reports an error when Authority ID is provided without a Source" do
      $driver.clear_and_send_keys([:id, "agent_names__0__authority_id_"], "authid123")
      $driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], "Hendrix")
      
      rules_select = $driver.find_element(:id => "agent_names__0__rules_")
      rules_select.select_option("local")

      $driver.find_element(:css => "form .record-pane button[type='submit']").click
      $driver.find_element_with_text('//div[contains(@class, "error")]', /^Source - is required .*?authority id$/)
    end


    it "auto generates Sort Name when other name fields upon save" do
      $driver.find_element(:id => "agent_names__0__source_").select_option("local")

      $driver.clear_and_send_keys([:id, "agent_names__0__authority_id_"], "authid123")
      $driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], "Hendrix")

      $driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

      $driver.find_element_with_text('//h2', /Hendrix/)

      $driver.find_element(:link => "Edit").click

      $driver.clear_and_send_keys([:id, "agent_names__0__rest_of_name_"], "Johnny Allen")

      $driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

      $driver.find_element_with_text('//h2', /Hendrix, Johnny Allen/)
    end


    it "changing Direct Order updates Sort Name" do
      $driver.find_element(:link => "Edit").click

      $driver.find_element(:id => "agent_names__0__name_order_").select_option("direct")

      $driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

      $driver.find_element_with_text('//h2', /Johnny Allen Hendrix/)
    end


    it "throws an error if no sort name is provided and auto gen is false" do
      $driver.find_element(:link => "Edit").click
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
      $driver.find_element(:link => "Edit").click
      $driver.find_element(:css => '#names .subrecord-form-heading .btn').click
      $driver.find_element(:css => "form .record-pane button[type='submit']").click

      $driver.find_element_with_text('//div[contains(@class, "error")]', /Primary Part of Name - Property is required but was missing/)

      $driver.clear_and_send_keys([:id, "agent_names__1__primary_name_"], "Hendrix")
      $driver.clear_and_send_keys([:id, "agent_names__1__rest_of_name_"], "Jimi")

    end


    it "can save a person and view readonly view of person" do
      $driver.find_element(:css => '#contacts .subrecord-form-heading .btn').click

      $driver.clear_and_send_keys([:id, "agent_agent_contacts__0__name_"], "Email Address")
      $driver.clear_and_send_keys([:id, "agent_agent_contacts__0__email_"], "jimi@rocknrollheaven.com")

      $driver.find_element(:id => "agent_names__1__source_").select_option("local")
      $driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

      assert(5) { $driver.find_element(:css => '.record-pane h2').text.should eq("My Custom Sort Name Agent") }
    end


    it "reports errors when updating a Person Agent with invalid data" do
      $driver.click_and_wait_until_gone(:link, 'Edit')

      $driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], "")
      $driver.find_element(:css => "form .record-pane button[type='submit']").click
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Primary Part of Name - Property is required but was missing/)
      $driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], "Hendrix")
    end


    it "can remove contact details" do
      $driver.find_element(:css => '#contacts .subrecord-form-remove').click
      $driver.find_element(:css => '#contacts .confirm-removal').click

      assert(5) {
        $driver.ensure_no_such_element(:id => "agent_agent_contacts__0__name_")
      }

      $driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

      $driver.ensure_no_such_element(:css => "#contacts h3")
    end


    it "can add an external document to an Agent" do
      $driver.click_and_wait_until_gone(:link, 'Edit')
      $driver.find_element(:css => '#agent_external_documents_ .subrecord-form-heading .btn').click

      $driver.clear_and_send_keys([:id, "agent_external_documents__0__title_"], "My URI document")
      $driver.clear_and_send_keys([:id, "agent_external_documents__0__location_"], "http://archivesspace.org")

      $driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

      # check external documents
      external_document_sections = $driver.blocking_find_elements(:css => '#agent_external_documents_ .external-document')
      external_document_sections.length.should eq (1)
      external_document_sections[0].find_element(:link => "http://archivesspace.org")
    end


    it "can add a Biog/Hist note to an Agent" do
      $driver.click_and_wait_until_gone(:link, 'Edit')
      $driver.find_element(:css => '#notes .subrecord-form-heading .btn').click
      $driver.blocking_find_elements(:css => '#notes .top-level-note-type')[0].select_option("note_bioghist")

      # ensure note form displayed
      $driver.find_element(:id, "agent_notes__0__label_")

      biog = "Jimi was an American musician and songwriter; and one of the most influential electric guitarists in the history of popular music."
      $driver.execute_script("$('#agent_notes__0__content__0_').data('CodeMirror').setValue('#{biog}')")
      $driver.execute_script("$('#agent_notes__0__content__0_').data('CodeMirror').save()")

      $driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

      # check the readonly view
      $driver.find_element_with_text('//div[contains(@class, "subrecord-form-fields")]', /#{biog}/)
    end


    it "can add a sub note" do
      $driver.click_and_wait_until_gone(:link, 'Edit')

      notes = $driver.blocking_find_elements(:css => '#notes .subrecord-form-fields')

      # Add a sub note
      notes[0].find_element(:css => '.subrecord-form-heading .btn').click
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
    end


    after(:all) do
      logout
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

      assert(5) { $driver.find_element(:css => '.record-pane h2').text.should eq("#{@accession_title} Accession") }
    end


    it "is presented an Accession edit form" do
      $driver.click_and_wait_until_gone(:link, 'Edit')

      $driver.clear_and_send_keys([:id, 'accession_content_description_'], "Here is a description of this accession.")
      $driver.clear_and_send_keys([:id, 'accession_condition_description_'], "Here we note the condition of this accession.")
      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      assert(5) { $driver.find_element(:css => 'body').text.should match(/Here is a description of this accession/) }
    end


    it "reports errors when updating an Accession with invalid data" do
      $driver.click_and_wait_until_gone(:link, 'Edit')
      $driver.clear_and_send_keys([:id, "accession_title_"], "")
      $driver.find_element(:css => "form#accession_form button[type='submit']").click
      expect {
        $driver.find_element_with_text('//div[contains(@class, "error")]', /Title - Property is required but was missing/)
      }.to_not raise_error
      # cancel first to back out bad change
      $driver.find_element(:link, "Cancel").click
    end


    it "can edit an Accession and two Extents" do
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

      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      assert(5) { $driver.find_element(:css => '.record-pane h2').text.should eq("#{@accession_title} Accession") }
    end


    it "can see two extents on the saved Accession" do
      extent_headings = $driver.blocking_find_elements(:css => '#accession_extents_ .accordion-heading')

      extent_headings.length.should eq (2)

      assert(5) { extent_headings[0].text.should eq ("5 Volumes") }
      assert(5) { extent_headings[1].text.should eq ("10 Cassettes") }
    end


    it "can remove an extent when editing an Accession" do
      $driver.click_and_wait_until_gone(:link, 'Edit')
      $driver.blocking_find_elements(:css => '#accession_extents_ .subrecord-form-remove')[0].click
      $driver.find_element(:css => '#accession_extents_ .confirm-removal').click

      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      extent_headings = $driver.blocking_find_elements(:css => '#accession_extents_ .accordion-heading')
      extent_headings.length.should eq (1)
      assert(5) { extent_headings[0].text.should eq ("10 Cassettes") }
    end


    it "can link an accession to an agent as a subject" do
      create_agent("Subject Agent #{@me}")
      run_index_round

      $driver.click_and_wait_until_gone(:link, 'Edit')

      $driver.find_element(:css => '#accession_linked_agents_ .subrecord-form-heading .btn').click

      $driver.find_element(:id => "accession_linked_agents__0__role_").select_option("subject")

      token_input = $driver.find_element(:id, "token-input-accession_linked_agents__0__ref_")
      token_input.clear
      token_input.click
      token_input.send_keys("Subject Agent")
      $driver.find_element(:css, "li.token-input-dropdown-item2").click

      $driver.find_element(:css, "#accession_linked_agents__0__terms_ .subrecord-form-heading .btn").click
      $driver.find_element(:css, "#accession_linked_agents__0__terms_ .subrecord-form-heading .btn").click

      $driver.clear_and_send_keys([:id => "accession_linked_agents__0__terms__0__term_"], "#{@me}LinkedAgentTerm1")
      $driver.clear_and_send_keys([:id => "accession_linked_agents__0__terms__1__term_"], "#{@me}LinkedAgentTerm2")

      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

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

      # check dates
      date_headings = $driver.blocking_find_elements(:css => '#accession_dates_ .accordion-heading')
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
      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

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

      # check remaining external documents
      external_document_sections = $driver.blocking_find_elements(:css => '#accession_external_documents_ .external-document')
      external_document_sections.length.should eq (1)
    end


    it "can create a subject and link to an Accession" do

      $driver.click_and_wait_until_gone(:link, 'Edit')

      $driver.find_element(:css => '#accession_subjects_ .subrecord-form-heading .btn').click

      $driver.find_element(:css => '#accession_subjects_ .dropdown-toggle').click

      $driver.find_element(:css, "a.linker-create-btn").click

      $driver.find_element(:css, ".modal #subject_terms_ .subrecord-form-heading .btn").click
      $driver.find_element(:css, ".modal #subject_terms_ .subrecord-form-heading .btn").click

      $driver.clear_and_send_keys([:id => "subject_terms__0__term_"], "#{@me}AccessionTermABC")
      $driver.clear_and_send_keys([:id => "subject_terms__1__term_"], "#{@me}AccessionTermDEF")

      $driver.find_element(:id, "createAndLinkButton").click

      # Browse works too
      $driver.find_element(:css => '#accession_subjects_ .dropdown-toggle').click
      $driver.find_element(:css, "a.linker-browse-btn").click
      $driver.find_element_with_text('//div', /#{@me}AccessionTermABC/)
      $driver.find_element(:css, ".modal-footer > button.btn.btn-cancel").click

      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      assert(5) { $driver.find_element(:css => "#accession_subjects_ .token").text.should eq("#{@me}AccessionTermABC -- #{@me}AccessionTermDEF") }
    end


    it "can add a rights statement to an Accession" do
      $driver.click_and_wait_until_gone(:link, 'Edit')

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
      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

      # check the show page
      $driver.find_element(:id, "accession_rights_statements_")
      $driver.find_element(:id, "rights_statement_0")
    end


    it "can show a browse list of Accessions" do
      run_index_round
      
      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Accessions").click
      expect {
        $driver.find_element_with_text('//td', /#{@accession_title}/)
      }.to_not raise_error
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
        create_accession("acc #{c += 1}")
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
        $driver.find_element(:link, "Create").click
        $driver.find_element(:link, "Digital Object").click

        $driver.clear_and_send_keys([:id, "digital_object_title_"],("I can't believe this is DO number #{c += 1}"))
        $driver.clear_and_send_keys([:id, "digital_object_digital_object_id_"],(Digest::MD5.hexdigest("#{Time.now}")))
        
        $driver.find_element(:css => "form#new_digital_object button[type='submit']").click
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
      @accession_title = create_accession("My accession to test the record lifecycle")
      run_index_round
    end


    after(:all) do
      logout
      $accession_url = nil
    end


    it "can suppress an Accession" do
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

      logout
      login_as_archivist
    end


    it "an archivist can't see a suppressed Accession" do
      # check the listing
      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Accessions").click

      $driver.find_element_with_text('//h2', /Accessions/)

      # No element found
      $driver.find_element_with_text('//td', /#{@accession_title}/, true, true).should eq(nil)

      # check the accession url
      $driver.get($accession_url)
      $driver.find_element_with_text('//h2', /Record Not Found/)

      logout
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
    end

  end


  describe "Events" do

    before(:all) do
      login_as_archivist
      @accession_title = create_accession("Events link to this accession")
      @agent_name = create_agent("Geddy Lee")
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

      # save
      $driver.find_element(:css => "form#accession_form button[type='submit']").click

      # Spawn a resource from the accession we just created
      $driver.find_element(:link, "Spawn").click
      $driver.find_element(:link, "Resource").click

      # The relationship back to the original accession is prepopulated
      $driver.find_element(:css => 'div.accession').text.should match(/enraged guinea pigs/)

      $driver.complete_4part_id("resource_id_%d_")
      $driver.find_element(:id, "resource_language_").select_option("eng")
      $driver.find_element(:id, "resource_level_").select_option("collection")

      # condition and content descriptions have come across as notes fields
      $driver.execute_script("$('#resource_notes__0__content__0_').data('CodeMirror').toTextArea()")
      $driver.find_element(:id => "resource_notes__0__content__0_").attribute("value").should eq("9 guinea pigs")

      $driver.execute_script("$('#resource_notes__1__content__0_').data('CodeMirror').toTextArea()")
      $driver.find_element(:id => "resource_notes__1__content__0_").attribute("value").should eq("furious")

      $driver.clear_and_send_keys([:id, "resource_extents__0__number_"], "10")

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
      assert(5) { $driver.find_element(:css => "a.jstree-clicked").text.strip.should match(/#{resource_title}/) }
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

      $driver.find_element_with_text('//div[contains(@class, "error")]', /Dates - one or more required \(or enter a Title\)/)
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Title - must not be an empty string \(or enter a Date\)/)
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
      assert(5) { $driver.find_element(:css => "a.jstree-clicked").text.strip.should eq('DecemberItem') }
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

      $driver.find_element(:css => '#archival_object_subjects_ .subrecord-form-heading .btn').click

      $driver.find_element(:css, ".linker-wrapper a.btn").click
      $driver.find_element(:css, "a.linker-create-btn").click

      $driver.find_element(:css, ".modal #subject_terms_ .subrecord-form-heading .btn").click
      $driver.find_element(:css, ".modal #subject_terms_ .subrecord-form-heading .btn").click

      $driver.clear_and_send_keys([:id => "subject_terms__0__term_"], "#{$$}TestTerm123")
      $driver.clear_and_send_keys([:id => "subject_terms__1__term_"], "#{$$}FooTerm456")

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

      $driver.find_element_with_text('//tr', /#{resource_title}/).find_element(:link, 'Edit').click

      $driver.find_element(:css => '#resource_extents_ .subrecord-form-heading .btn').click

      $driver.clear_and_send_keys([:id, 'resource_extents__1__number_'], "5")
      event_type_select = $driver.find_element(:id => "resource_extents__1__extent_type_")
      event_type_select.find_elements( :tag_name => "option" ).each do |option|
        option.click if option.attribute("value") === "volumes"
      end

      $driver.find_element(:css => "form#resource_form button[type='submit']").click

      $driver.find_element_with_text('//div', /Resource #{resource_title} updated/).should_not be_nil

      $driver.find_element(:link, 'Close Record').click
    end


    it "can see two Extents on the saved Resource" do
      extent_headings = $driver.blocking_find_elements(:css => '#resource_extents_ .accordion-heading')

      extent_headings.length.should eq (2)
      assert(5) { extent_headings[0].text.should eq ("10 Cassettes") }
      assert(5) { extent_headings[1].text.should eq ("5 Volumes") }
    end


    it "can remove an Extent when editing a Resource" do
      $driver.click_and_wait_until_gone(:link, 'Edit')

      $driver.blocking_find_elements(:css => '#resource_extents_ .subrecord-form-remove')[1].click
      $driver.find_element(:css => '#resource_extents_ .confirm-removal').click
      $driver.find_element(:css => "form#resource_form button[type='submit']").click

      $driver.find_element(:link, 'Close Record').click

      extent_headings = $driver.blocking_find_elements(:css => '#resource_extents_ .accordion-heading')

      extent_headings.length.should eq (1)
      assert(5) { extent_headings[0].text.should eq ("10 Cassettes") }
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
      $driver.find_element(:css => '.subrecord-form-removal-confirmation .btn-primary').click

      # Take out the first note too
      notes[0].find_element(:css => '.subrecord-form-remove').click
      $driver.find_element(:css => '.subrecord-form-removal-confirmation .btn-primary').click

      # One left!
      $driver.blocking_find_elements(:css => '#notes > .subrecord-form-container > .subrecord-form-list > li').length.should eq(1)

      # Fill it out
      $driver.clear_and_send_keys([:id, 'resource_notes__2__label_'],
                                  "A multipart note")

      $driver.execute_script("$('#resource_notes__2__content__0_').data('CodeMirror').setValue('Some note content')")
      $driver.execute_script("$('#resource_notes__2__content__0_').data('CodeMirror').save()")


      # Save the resource
      $driver.find_element(:css => "form#resource_form button[type='submit']").click
      $driver.find_element(:link, 'Close Record').click
    end


    it "can edit an existing resource note to add subparts after saving" do
      $driver.click_and_wait_until_gone(:link, 'Edit')

      notes = $driver.blocking_find_elements(:css => '#notes .subrecord-form-fields')

      # Add a sub note
      notes[0].find_element(:css => '.subrecord-form-heading .btn').click
      notes[0].find_last_element(:css => 'select.multipart-note-type').select_option('note_chronology')

      $driver.find_element(:id => 'resource_notes__0__subnotes__2__title_')
      $driver.clear_and_send_keys([:id, 'resource_notes__0__subnotes__2__title_'], "Chronology title")


      notes[0].find_element(:css => '.subrecord-form-heading .btn').click
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

      $driver.find_element(:css => '#notes > .subrecord-form-heading .btn').click
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
      # select some text
      $driver.execute_script("$('#resource_notes__0__content__0_').data('CodeMirror').setValue('ABC')")
      $driver.execute_script("$('#resource_notes__0__content__0_').data('CodeMirror').setSelection({line: 0, ch: 0}, {line: 0, ch: 3})")

      # select a tag to wrap the text
      $driver.find_element(:css => "select.mixed-content-wrap-action").select_option("ref")
      $driver.execute_script("$('#resource_notes__0__content__0_').data('CodeMirror').save()")
      $driver.execute_script("$('#resource_notes__0__content__0_').data('CodeMirror').toTextArea()")
      $driver.find_element(:id => "resource_notes__0__content__0_").attribute("value").should eq("<ref>ABC</ref>")

      # Save the resource
      $driver.find_element(:css => "form#resource_form button[type='submit']").click
      $driver.find_element(:link, 'Close Record').click
    end


    it "can add a deaccession record" do
      $driver.click_and_wait_until_gone(:link, 'Edit')

      $driver.find_element(:css => '#resource_deaccessions_ .subrecord-form-heading .btn').click

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
      $driver.find_element(:id, "resource_language_").select_option("eng")
      $driver.find_element(:id, "resource_level_").select_option("collection")
      $driver.clear_and_send_keys([:id, "resource_extents__0__number_"], "10")

      $driver.find_element(:css => "form#resource_form button[type='submit']").click

      # Give it a child AO
      $driver.find_element(:link, "Add Child").click

      $driver.clear_and_send_keys([:id, "archival_object_title_"], "An Archival Object with notes")
      $driver.find_element(:id, "archival_object_level_").select_option("item")


      # Add some notes to it
      add_note = proc do |type|
        $driver.find_element(:css => '#notes .subrecord-form-heading .btn').click
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
      $driver.find_element(:css => '#notes .subrecord-form-heading .btn').click
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

      $driver.find_element(:css => "section#digital_object_file_versions_ > h3 > .btn").click

      $driver.clear_and_send_keys([:id, "digital_object_file_versions__0__file_uri_"], "/uri/for/this/file/version")
      $driver.clear_and_send_keys([:id , "digital_object_file_versions__0__file_size_bytes_"], '100')
      
      $driver.find_element(:css => "form#new_digital_object button[type='submit']").click

      # The new Digital Object shows up on the tree
      assert(5) { $driver.find_element(:css => "a.jstree-clicked").text.strip.should match(/#{digital_object_title}/) }
    end


    it "reports errors if adding an empty child to a Digital Object" do
      $driver.find_element(:link, "Add Child").click

      # False start: create an object without filling it out
      $driver.click_and_wait_until_gone(:id => "createPlusOne")

      $driver.find_element_with_text('//div[contains(@class, "error")]', /Identifier - Property is required but was missing/)
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

        $driver.find_element(:css => "section#digital_object_component_file_versions_ > h3 > .btn").click
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
      target.find_element_with_text("./ul/li/a", /ICO/)

      # refresh the page and verify that the change really stuck
      $driver.navigate.refresh

      target = $driver.find_element_with_text("//div[@id='archives_tree']//li", /Pony Express Digital Image/)
      target.find_element_with_text("./ul/li/a", /ICO/)

      $driver.click_and_wait_until_gone(:link, "Close Record")
      $driver.find_element(:xpath, "//a[@title='#{digital_object_title}']").click

      $driver.find_element_with_text("//h2", /#{digital_object_title}/)
    end
  end



  describe "User management" do

    before(:all) do
      login("admin", "admin")
      
      (@user, @pass) = create_user
    end

    after(:all) do
      logout
    end

    it "can create a user account" do
      $driver.find_element(:link, 'System').click
      $driver.find_element(:link, "Manage Users").click
      
      $driver.find_element(:link, "Create User").click
      
      $driver.clear_and_send_keys([:id, "user_username_"], @user)
      $driver.clear_and_send_keys([:id, "user_name_"], @user)
      $driver.clear_and_send_keys([:id, "user_password_"], @pass)
      $driver.clear_and_send_keys([:id, "user_confirm_password_"], @pass)
      
      $driver.find_element(:id, 'create_account').click
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

      assert(5) { $driver.find_element(:css => "p.help-inline.login-message").text.should eq('Login attempt failed') }

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
      $driver.find_element(:link, "Manage Enumerations").click
      
      enum_select = $driver.find_element(:id => "enum_selector")
      enum_select.select_option_with_text("accession_acquisition_type")
      
      # Wait for the table of enumerations to load
      $driver.find_element(:css, '.enumeration-list')

      $driver.find_element(:link, 'Create Value').click
      $driver.clear_and_send_keys([:id, "enumeration_value_"], "manna\n")

      $driver.find_element_with_text('//td', /^manna$/)
    end


    it "lets you delete a value from an enumeration" do
      manna = $driver.find_element_with_text('//tr', /manna/)
      manna.find_element(:link, 'Delete').click

      $driver.find_element(:css => "form#delete_enumeration input[type='submit']").click

      $driver.find_element_with_text('//div', /Enumeration Value Deleted/)
    end


    it "lets you merge one value into another in an enumeration" do
      # write this test!
    end


    it "lets you set a default enumeration (date_type)" do
      $driver.find_element(:link, 'System').click
      $driver.find_element(:link, "Manage Enumerations").click
      
      enum_select = $driver.find_element(:id => "enum_selector")
      enum_select.select_option_with_text("date_type")
      
      # Wait for the table of enumerations to load
      $driver.find_element(:css, '.enumeration-list')

      while true
        inclusive_dates = $driver.find_element_with_text('//tr', /Inclusive Dates/)
        default_btn = inclusive_dates.find_elements(:link, 'Set as Default')

        if default_btn[0]
          default_btn[0].click
          # Keep looping until the 'Set as Default' button is gone
          sleep 0.1
        else
          break
        end
      end

      $driver.find_element(:link, "Create").click
      $driver.find_element(:link, "Accession").click

      $driver.find_element(:css => '#accession_dates_ .subrecord-form-heading .btn').click

      date_type_select = $driver.find_element(:id => "accession_dates__0__date_type_")
      selected_type = date_type_select.get_select_value
      selected_type.should eq 'inclusive'

      # ensure that the correct subform is loading:
      subform = $driver.find_element(:css => '.date-type-subform')
      subform.find_element_with_text('//label', /Begin/)
      subform.find_element_with_text('//label', /End/)

      $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")
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
      $driver.find_element(:id, 'global-search-button').click
      $driver.find_element(:link, "Repository").click
      assert(5) { $driver.find_element_with_text("//h5", /Filtered By/) }
      assert(5) { $driver.find_element_with_text("//a", /Record Type: Repository/) }
      assert(5) { $driver.find_element_with_text('//div', /Showing 1 - 1 of 1 Results/) }
    end

  end

end
