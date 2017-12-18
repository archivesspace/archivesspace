require_relative 'spec_helper'

describe "Accessions" do

  before(:all) do

    @repo = create(:repo, :repo_code => "accession_test_#{Time.now.to_i}")
    set_repo @repo

    @coll_mgmt_accession = create(:accession)
    @other_accession = create(:accession, :title => "Link to me")
   
    @archivist_user = create_user(@repo => ['repository-archivists'])
    @manager_user = create_user(@repo => ['repository-managers'])


    @accession_title = "Exciting new stuff - \u2603 - #{Time.now.to_i}"
    @me = "#{$$}.#{Time.now.to_i}"

    @shared_4partid = generate(:four_part_id)

    @dates_accession_title = "Accession_#{Time.now.to_i}"
    @dates_4partid = generate(:four_part_id)

    @exdocs_accession_title = "Accession_#{Time.now.to_i}"
    @exdocs_4partid = generate(:four_part_id)

    run_all_indexers

    @driver = Driver.get.login_to_repo(@archivist_user, @repo)
  end


  after(:all) do
    @driver.quit
  end

  it "can spawn an accession from an existing accession" do
    @driver.find_element(:link, "Create").click
    @driver.click_and_wait_until_gone(:link, "Accession")

    @driver.clear_and_send_keys([:id, "accession_title_"], "Charles Darwin's paperclip collection")
    @driver.complete_4part_id("accession_id_%d_")
    @driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
    @driver.clear_and_send_keys([:id, "accession_content_description_"], "Lots of paperclips")
    @driver.clear_and_send_keys([:id, "accession_condition_description_"], "pristine")

    # add a date
    @driver.find_element(:css => '#accession_dates_ .subrecord-form-heading .btn:not(.show-all)').click
    @driver.find_element(:id => "accession_dates__0__label_").select_option("digitized")
    @driver.find_element(:id => "accession_dates__0__date_type_").select_option("single")
    @driver.clear_and_send_keys([:id, "accession_dates__0__expression_"], "The day before yesterday.")

    # add a rights subrecord
    @driver.find_element(:css => '#accession_rights_statements_ .subrecord-form-heading .btn:not(.show-all)').click
    @driver.find_element(:id => "accession_rights_statements__0__rights_type_").select_option("copyright")
    @driver.find_element(:id => "accession_rights_statements__0__status_").select_option("copyrighted")
    @driver.clear_and_send_keys([:id, "accession_rights_statements__0__start_date_"], "2012-01-01")
    combo = @driver.find_element(:xpath => '//div[@class="combobox-container"][following-sibling::select/@id="accession_rights_statements__0__jurisdiction_"]//input[@type="text"]');
    combo.clear
    combo.click
    combo.send_keys("AU")
    combo.send_keys(:tab)

    # add an external document
    @driver.find_element(:css => "#accession_rights_statements__0__external_documents_ .subrecord-form-heading .btn:not(.show-all)").click
    @driver.clear_and_send_keys([:id, "accession_rights_statements__0__external_documents__0__title_"], "Agreement")
    @driver.clear_and_send_keys([:id, "accession_rights_statements__0__external_documents__0__location_"], "http://locationof.agreement.com")
    combo = @driver.find_element(:xpath => '//div[@class="combobox-container"][following-sibling::select/@id="accession_rights_statements__0__external_documents__0__identifier_type_"]//input[@type="text"]');
    combo.clear
    combo.click
    combo.send_keys("Trove")
    combo.send_keys(:tab)

    # save
    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    @driver.wait_for_ajax

    # Spawn an accession from the accession we just created
    @driver.find_element(:link, "Spawn").click

    @driver.click_and_wait_until_gone(:link, "Accession")

    @driver.find_element_with_text('//div', /This Accession has been spawned from/)

    @driver.clear_and_send_keys([:id, "accession_title_"], "Charles Darwin's second paperclip collection")
    @driver.complete_4part_id("accession_id_%d_")

    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    # Success!
    assert(5) {
      @driver.find_element_with_text('//div', /Accession Charles Darwin's second paperclip collection created/).should_not be_nil
    }

    @driver.click_and_wait_until_gone(:link => "Charles Darwin's second paperclip collection")

    # date should have come across
    date_headings = @driver.blocking_find_elements(:css => '#accession_dates_ .panel-heading')
    date_headings.length.should eq (1)

    # rights and external doc shouldn't
    @driver.ensure_no_such_element(:id, "accession_rights_statements_")
    @driver.ensure_no_such_element(:id, "accession_external_documents_")
  end


  it "can create an Accession" do
    @driver.find_element(:link, "Create").click
    @driver.click_and_wait_until_gone(:link, "Accession")
    @driver.clear_and_send_keys([:id, "accession_title_"], @accession_title)
    @driver.complete_4part_id("accession_id_%d_", @shared_4partid)
    @driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
    @driver.clear_and_send_keys([:id, "accession_content_description_"], "A box containing our own universe")
    @driver.clear_and_send_keys([:id, "accession_condition_description_"], "Slightly squashed")
    @driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

    @driver.click_and_wait_until_gone(:link => @accession_title)

    assert(5) { @driver.find_element(:css => '.record-pane h2').text.should eq("#{@accession_title} Accession") }
  end


  it "is presented an Accession edit form" do
    @driver.click_and_wait_until_gone(:link, 'Edit')
    @driver.clear_and_send_keys([:id, 'accession_content_description_'], "Here is a description of this accession.")
    @driver.clear_and_send_keys([:id, 'accession_condition_description_'], "Here we note the condition of this accession.")
    @driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

    @driver.click_and_wait_until_gone(:link => @accession_title)

    assert(5) { @driver.find_element(:css => 'body').text.should match(/Here is a description of this accession/) }
  end


  it "reports errors when updating an Accession with invalid data" do
    @driver.click_and_wait_until_gone(:link, 'Edit')
    @driver.clear_and_send_keys([:id, "accession_id_0_"], "")
    @driver.find_element(:css => "form#accession_form button[type='submit']").click
    expect {
      @driver.find_element_with_text('//div[contains(@class, "error")]', /Identifier - Property is required but was missing/)
    }.to_not raise_error

    # cancel first to back out bad change
    @driver.click_and_wait_until_gone(:link => "Cancel")
  end


  it "can edit an Accession and two Extents" do
    # add the first extent
    @driver.find_element(:css => '#accession_extents_ .subrecord-form-heading .btn:not(.show-all)').click
    @driver.find_element(:id => "accession_extents__0__extent_type_").select_option("volumes")
    @driver.clear_and_send_keys([:id, 'accession_extents__0__number_'], "5")

    # add the second extent
    @driver.find_element(:css => '#accession_extents_ .subrecord-form-heading .btn:not(.show-all)').click
    @driver.find_element(:id => "accession_extents__1__extent_type_").select_option("cassettes")
    @driver.clear_and_send_keys([:id, 'accession_extents__1__number_'], "10")

    @driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

    @driver.click_and_wait_until_gone(:link => @accession_title)

    assert(5) { @driver.find_element(:css => '.record-pane h2').text.should eq("#{@accession_title} Accession") }
  end


  it "can see two extents on the saved Accession" do
    extent_headings = @driver.blocking_find_elements(:css => '#accession_extents_ .panel-heading')

    extent_headings.length.should eq (2)

    assert(5) { extent_headings[0].text.should eq ("5 Volumes") }
    assert(5) { extent_headings[1].text.should eq ("10 Cassettes") }
  end


  it "can remove an extent when editing an Accession" do
    @driver.click_and_wait_until_gone(:link, 'Edit')
    @driver.blocking_find_elements(:css => '#accession_extents_ .subrecord-form-remove')[0].click
    @driver.find_element(:css => '#accession_extents_ .confirm-removal').click

    @driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

    @driver.click_and_wait_until_gone(:link => @accession_title)

    extent_headings = @driver.blocking_find_elements(:css => '#accession_extents_ .panel-heading')
    extent_headings.length.should eq (1)
    assert(5) { extent_headings[0].text.should eq ("10 Cassettes") }
  end


  it "can link an accession to an agent as a subject" do
    create(:agent_person, 
           :names => [build(:name_person,
                            :name_order => "inverted",
                            :primary_name => "Subject Agent #{@me}",
                            :rest_of_name => "Subject Agent #{@me}",
                            :sort_name => "Subject Agent #{@me}")])
    run_index_round

    @driver.click_and_wait_until_gone(:link, 'Edit')

    @driver.find_element(:css => '#accession_linked_agents_ .subrecord-form-heading .btn:not(.show-all)').click

    @driver.find_element(:id => "accession_linked_agents__0__role_").select_option("subject")

    token_input = @driver.find_element(:id, "token-input-accession_linked_agents__0__ref_")
    @driver.typeahead_and_select( token_input, "Subject Agent" ) 

    @driver.find_element(:css, "#accession_linked_agents__0__terms_ .subrecord-form-heading .btn:not(.show-all)").click
    @driver.find_element(:css, "#accession_linked_agents__0__terms_ .subrecord-form-heading .btn:not(.show-all)").click

    @driver.clear_and_send_keys([:id => "accession_linked_agents__0__terms__0__term_"], "#{@me}LinkedAgentTerm1")
    @driver.clear_and_send_keys([:id => "accession_linked_agents__0__terms__1__term_"], "#{@me}LinkedAgentTerm2")

    @driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

    @driver.click_and_wait_until_gone(:link => @accession_title)

    @driver.find_element(:id => 'accession_linked_agents_').text.should match(/LinkedAgentTerm/)
  end


  it "shows an error if you try to reuse an identifier" do
    @driver.find_element(:link, "Create").click
    @driver.click_and_wait_until_gone(:link, "Accession")
    @driver.clear_and_send_keys([:id, "accession_title_"], @accession_title)
    @driver.complete_4part_id("accession_id_%d_", @shared_4partid)
    @driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

    expect {
      @driver.find_element_with_text('//div[contains(@class, "error")]', /Identifier - That ID is already in use/)
    }.to_not raise_error

    @driver.click_and_wait_until_gone(:link => "Cancel")
    @driver.click_and_wait_until_gone(:link => "Cancel")
  end


  it "can create an Accession with some dates" do
    @driver.find_element(:link, "Create").click
    @driver.click_and_wait_until_gone(:link, "Accession")

    # populate mandatory fields
    @driver.clear_and_send_keys([:id, "accession_title_"], @dates_accession_title)

    @driver.complete_4part_id("accession_id_%d_", @dates_4partid)

    @driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
    @driver.clear_and_send_keys([:id, "accession_content_description_"], "A box containing our own universe")
    @driver.clear_and_send_keys([:id, "accession_condition_description_"], "Slightly squashed")

    # add some dates!
    @driver.find_element(:css => '#accession_dates_ .subrecord-form-heading .btn:not(.show-all)').click
    @driver.find_element(:css => '#accession_dates_ .subrecord-form-heading .btn:not(.show-all)').click

    #populate the first date
    @driver.find_element(:id => "accession_dates__0__label_").select_option("digitized")
    @driver.find_element(:id => "accession_dates__0__date_type_").select_option("single")
    @driver.clear_and_send_keys([:id, "accession_dates__0__expression_"], "The day before yesterday.")

    #populate the second date
    @driver.find_element(:id => "accession_dates__1__label_").select_option("other")
    @driver.find_element(:id => "accession_dates__1__date_type_").select_option("inclusive")
    @driver.clear_and_send_keys([:id, "accession_dates__1__begin_"], "2012-05-14")
    @driver.clear_and_send_keys([:id, "accession_dates__1__end_"], "2011-05-14")

    # save!
    @driver.find_element(:css => "form#accession_form button[type='submit']").click

    # fail!
    expect {
      @driver.find_element_with_text('//div[contains(@class, "error")]', /must not be before begin/)
    }.to_not raise_error

    # fix!
    @driver.clear_and_send_keys([:id, "accession_dates__1__end_"], "2013-05-14")

    # save again!
    @driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

    @driver.click_and_wait_until_gone(:link => @dates_accession_title)

    # check dates
    date_headings = @driver.blocking_find_elements(:css => '#accession_dates_ .panel-heading')
    date_headings.length.should eq (2)
  end


  it "can delete an existing date when editing an Accession" do
    @driver.click_and_wait_until_gone(:link, 'Edit')

    # remove the first date
    @driver.find_element(:css => '#accession_dates_ .subrecord-form-remove').click
    @driver.find_element(:css => '#accession_dates_ .confirm-removal').click

    # save!
    @driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

    # check remaining date
    @driver.click_and_wait_until_gone(:link => @dates_accession_title)
    date_headings = @driver.blocking_find_elements(:css => '#accession_dates_ .panel-heading')
    date_headings.length.should eq (1)
  end


  it "can create an Accession with some external documents" do
    @driver.find_element(:link, "Create").click
    @driver.click_and_wait_until_gone(:link, "Accession")

    # populate mandatory fields
    @driver.clear_and_send_keys([:id, "accession_title_"], @exdocs_accession_title)

    @driver.complete_4part_id("accession_id_%d_", @exdocs_4partid)

    @driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
    @driver.clear_and_send_keys([:id, "accession_content_description_"], "A box containing our own universe")
    @driver.clear_and_send_keys([:id, "accession_condition_description_"], "Slightly squashed")

    # add some external documents
    @driver.find_element(:css => '#accession_external_documents_ .subrecord-form-heading .btn:not(.show-all)').click
    @driver.find_element(:css => '#accession_external_documents_ .subrecord-form-heading .btn:not(.show-all)').click

    #populate the first external documents
    @driver.clear_and_send_keys([:id, "accession_external_documents__0__title_"], "My URI document")
    @driver.clear_and_send_keys([:id, "accession_external_documents__0__location_"], "http://archivesspace.org")

    #populate the second external documents
    @driver.clear_and_send_keys([:id, "accession_external_documents__1__title_"], "My other document")
    @driver.clear_and_send_keys([:id, "accession_external_documents__1__location_"], "a/file/path/or/something/")

    # save!
    @driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

    @driver.click_and_wait_until_gone(:link => @exdocs_accession_title)

    # check external documents
    external_document_sections = @driver.blocking_find_elements(:css => '#accession_external_documents_ .external-document')
    external_document_sections.length.should eq (2)
    external_document_sections[0].find_element(:link => "http://archivesspace.org")
  end


  it "can delete an existing external documents when editing an Accession" do
    @driver.click_and_wait_until_gone(:link, 'Edit')

    # remove the first external documents
    @driver.find_element(:css => '#accession_external_documents_ .subrecord-form-remove').click
    @driver.find_element(:css => '#accession_external_documents_ .confirm-removal').click

    # save!
    @driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

    @driver.click_and_wait_until_gone(:link => @exdocs_accession_title)

    # check remaining external documents
    external_document_sections = @driver.blocking_find_elements(:css => '#accession_external_documents_ .external-document')
    external_document_sections.length.should eq (1)
  end


  it "can create a subject and link to an Accession" do

    @driver.click_and_wait_until_gone(:link, 'Edit')

    @driver.find_element(:css => '#accession_subjects_ .subrecord-form-heading .btn:not(.show-all)').click

    @driver.find_element(:css => '#accession_subjects_ .dropdown-toggle').click
    @driver.wait_for_dropdown
    @driver.find_element(:css, "a.linker-create-btn").click

    @driver.find_element(:css, ".modal #subject_terms_ .subrecord-form-heading .btn:not(.show-all)").click

    @driver.clear_and_send_keys([:id => "subject_terms__0__term_"], "#{@me}AccessionTermABC")
    @driver.clear_and_send_keys([:id => "subject_terms__1__term_"], "#{@me}AccessionTermDEF")
    @driver.find_element(:id => "subject_source_").select_option("local")

    @driver.find_element(:id, "createAndLinkButton").click

    # Browse works too
    @driver.find_element(:css => '#accession_subjects_ .dropdown-toggle').click
    @driver.wait_for_dropdown
    @driver.find_element(:css, "a.linker-browse-btn").click
    @driver.find_element_with_text('//div', /#{@me}AccessionTermABC/)
    @driver.find_element(:css, ".modal-footer > button.btn.btn-cancel").click

    @driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

    @driver.click_and_wait_until_gone(:link => @exdocs_accession_title)

    assert(5) { @driver.find_element(:css => "#accession_subjects_ .token").text.should eq("#{@me}AccessionTermABC -- #{@me}AccessionTermDEF") }
  end


  it "can add a rights statement to an Accession" do
    @driver.click_and_wait_until_gone(:link, 'Edit')

    # add a rights sub record
    @driver.find_element(:css => '#accession_rights_statements_ .subrecord-form-heading .btn:not(.show-all)').click

    @driver.find_element(:id => "accession_rights_statements__0__rights_type_").select_option("copyright")
    @driver.find_element(:id => "accession_rights_statements__0__status_").select_option("copyrighted")
    @driver.clear_and_send_keys([:id, "accession_rights_statements__0__start_date_"], "2012-01-01")
    combo = @driver.find_element(:xpath => '//div[@class="combobox-container"][following-sibling::select/@id="accession_rights_statements__0__jurisdiction_"]//input[@type="text"]');
    combo.clear
    combo.click
    combo.send_keys("AU")
    combo.send_keys(:tab)

    # add an external document
    @driver.find_element(:css => "#accession_rights_statements__0__external_documents_ .subrecord-form-heading .btn:not(.show-all)").click
    @driver.clear_and_send_keys([:id, "accession_rights_statements__0__external_documents__0__title_"], "Agreement")
    @driver.clear_and_send_keys([:id, "accession_rights_statements__0__external_documents__0__location_"], "http://locationof.agreement.com")
    combo = @driver.find_element(:xpath => '//div[@class="combobox-container"][following-sibling::select/@id="accession_rights_statements__0__external_documents__0__identifier_type_"]//input[@type="text"]');
    combo.clear
    combo.click
    combo.send_keys("Trove")
    combo.send_keys(:tab)


    # save changes
    @driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")
    run_index_round

    sleep(10)
    # check the show page
    @driver.click_and_wait_until_gone(:link => @exdocs_accession_title)
    expect {
      @driver.find_element(:id, "accession_rights_statements_")
      @driver.find_element(:css, "#accession_rights_statements_ .accordion-toggle").click
      @driver.find_element(:id, "rights_statement_0")
    }.not_to raise_error
  end

  it "can add collection management fields to an Accession" do
    @driver.navigate.to("#{$frontend}/accessions/#{@coll_mgmt_accession.id}/edit")
    # add a collection management sub record
    @driver.find_element(:css => '#accession_collection_management_ .subrecord-form-heading .btn:not(.show-all)').click

    # save changes
    @driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

    run_index_round
    # check the CM page
    @driver.find_element(:link, "Browse").click
    @driver.click_and_wait_until_gone(:link, "Collection Management")

    expect {
      @driver.find_element(:xpath => "//td[contains(text(), '#{@coll_mgmt_accession.title}')]")
    }.not_to raise_error

    @driver.click_and_wait_until_gone(:link, 'View')
    @driver.click_and_wait_until_gone(:link, 'Edit')

    # now delete it
    @driver.find_element(:css => '#accession_collection_management_ .subrecord-form-remove').click
    @driver.find_element(:css => '#accession_collection_management_ .confirm-removal').click
    @driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

    run_index_round

    expect {
      10.times {
        @driver.find_element(:link, "Browse").click
        @driver.click_and_wait_until_gone(:link, "Collection Management")
        @driver.find_element_orig(:xpath => "//td[contains(text(), '#{@coll_mgmt_accession.title}')]")

        run_index_round #keep indexing and refreshing till it disappears
        @driver.navigate.refresh
        sleep(1)
      }
    }.to raise_error Selenium::WebDriver::Error::NoSuchElementError
  end


  it "can create an accession which is linked to another accession" do   
    @driver.go_home
    @driver.find_element(:link, "Create").click
    @driver.click_and_wait_until_gone(:link, "Accession")

    # populate mandatory fields
    @driver.clear_and_send_keys([:id, "accession_title_"], "linked_accession_#{@me}")

    @driver.complete_4part_id("accession_id_%d_")

    #@driver.find_element(:css => '#accession_collection_management_ .subrecord-form-heading .btn:not(.show-all)').click
    @driver.find_element(:css => "#accession_related_accessions_ .subrecord-form-heading .btn:not(.show-all)").click

    @driver.find_element(:class, "related-accession-type").select_option('accession_parts_relationship')

    token_input = @driver.find_element(:id, "token-input-accession_related_accessions__0__ref_")
    @driver.typeahead_and_select( token_input, @other_accession.title )

    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

    @driver.find_element(:link, "linked_accession_#{@me}").click

    @driver.find_element_with_text('//td', /Forms Part of/)
    @driver.find_element_with_text('//td', /#{@other_accession.title}/)
  end


  it "can show a browse list of Accessions" do
    run_index_round

    @driver.find_element(:link, "Browse").click
    @driver.click_and_wait_until_gone(:link, "Accessions")
    expect {
      @driver.find_element_with_text('//td', /#{@accession_title}/)
      @driver.find_element_with_text('//td', /#{@dates_accession_title}/)
      @driver.find_element_with_text('//td', /#{@exdocs_accession_title}/)
    }.to_not raise_error
  end


  it "can delete multiple Accessions from the listing" do
    # first login as someone with access to delete
    @driver.login_to_repo(@manager_user, @repo)

    second_accession_title = "A new accession about to be deleted"
    create(:accession, :title => second_accession_title)
    run_index_round

    @driver.find_element(:link, "Browse").click
    @driver.click_and_wait_until_gone(:link, "Accessions")

    @driver.blocking_find_elements(:css, ".multiselect-column input").each do |checkbox|
      checkbox.click
    end

    @driver.find_element(:css, ".record-toolbar .btn.multiselect-enabled").click
    @driver.find_element(:css, "#confirmChangesModal #confirmButton").click

    assert(5) { @driver.find_element(:css => ".alert.alert-success").text.should eq("Records deleted") }

    # refresh the indexer and the page to make sure it stuck
    run_index_round
    @driver.navigate.refresh
    assert(5) { @driver.find_element(:css => ".alert.alert-info").text.should eq("No records found") }
  end

end
