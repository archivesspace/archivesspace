require_relative 'spec_helper'

describe "Agents" do

  before(:all) do
    @repo = create(:repo, :repo_code => "agents_test_#{Time.now.to_i}")
    user = create_user(@repo => ['repository-archivists'])
    @driver = Driver.get.login_to_repo(user, @repo)

    @hendrix = "Hendrix von #{Time.now.to_i}"

    @other_agent = create(:agent_person)
    run_all_indexers
  end

  after(:all) do
    @driver.quit
  end


  it "reports errors and warnings when creating an invalid Person Agent" do
    @driver.find_element(:link, 'Create').click
    @driver.find_element(:link, 'Agent').click
    @driver.click_and_wait_until_gone(:link, 'Person')
    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Primary Part of Name - Property is required but was missing/)
  end


  it "reports an error when neither Source nor Rules is provided" do
    @driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], @hendrix)

    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

    @driver.find_element_with_text('//div[contains(@class, "error")]', /Source - is required/)
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Rules - is required/)
  end


  it "reports a warning when Authority ID is provided without a Source" do
    @driver.clear_and_send_keys([:id, "agent_names__0__authority_id_"], SecureRandom.hex )
    @driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], @hendrix)

    rules_select = @driver.find_element(:id => "agent_names__0__rules_")
    rules_select.select_option("local")

    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")
    @driver.find_element_with_text('//div[contains(@class, "warning")]', /^Source - is required if there is an 'authority id'$/i)
  end


  it "auto generates Sort Name when other name fields upon save" do
    @driver.find_element(:id => "agent_names__0__source_").select_option("local")

    @driver.clear_and_send_keys([:id, "agent_names__0__authority_id_"], SecureRandom.hex)
    @driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], @hendrix)

    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

    @driver.find_element_with_text('//h2', /#{@hendrix}/)

    @driver.clear_and_send_keys([:id, "agent_names__0__rest_of_name_"], "Johnny Allen")

    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

    @driver.find_element_with_text('//h2', /#{@hendrix}, Johnny Allen/)
  end


  it "changing Direct Order updates Sort Name" do
    @driver.find_element(:id => "agent_names__0__name_order_").select_option("direct")

    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

    @driver.find_element_with_text('//h2', /Johnny Allen #{@hendrix}/)
  end


  it "throws an error if no sort name is provided and auto gen is false" do
    @driver.find_element(:id, "agent_names__0__sort_name_auto_generate_").click
    @driver.clear_and_send_keys([:id, "agent_names__0__sort_name_"], "")
    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Sort Name - Property is required but was missing/)
  end


  it "allows setting of a custom sort name" do
    @driver.clear_and_send_keys([:id, "agent_names__0__sort_name_"], "My Custom Sort Name")
    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

    @driver.find_element_with_text('//h2', /My Custom Sort Name/)
  end


  it "can add a secondary name and validations match index of name form" do
    @driver.find_element(:css => '#agent_person_names .subrecord-form-heading .btn:not(.show-all)').click
    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

    @driver.find_element_with_text('//div[contains(@class, "error")]', /Primary Part of Name - Property is required but was missing/)

    @driver.clear_and_send_keys([:id, "agent_names__1__primary_name_"], @hendrix)
    @driver.clear_and_send_keys([:id, "agent_names__1__rest_of_name_"], "Jimi")
  end


  it "can save a person and view readonly view of person" do
    @driver.find_element(:css => '#agent_person_contact_details .subrecord-form-heading .btn:not(.show-all)').click

    @driver.clear_and_send_keys([:id, "agent_agent_contacts__0__name_"], "Email Address")
    @driver.clear_and_send_keys([:id, "agent_agent_contacts__0__email_"], "jimi@rocknrollheaven.com")

    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

    assert(5) { @driver.find_element(:css => '.record-pane h2').text.should eq("My Custom Sort Name Agent") }
  end


  it "can add multiple telephone numbers" do
    @driver.find_element(:css => '#agent_agent_contacts__0__telephones_ .subrecord-form-heading .btn:not(.show-all)').click

    @driver.clear_and_send_keys([:id, "agent_agent_contacts__0__telephones__0__number_"], "555-5555")
    @driver.clear_and_send_keys([:id, "agent_agent_contacts__0__telephones__0__ext_"], "66")

    @driver.find_element(:css => '#agent_agent_contacts__0__telephones_ .subrecord-form-heading .btn:not(.show-all)').click
    @driver.clear_and_send_keys([:id, "agent_agent_contacts__0__telephones__1__number_"], "999-9999")

    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")
    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Agent Saved/)
  end


  it "reports errors when updating a Person Agent with invalid data" do
    @driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], "")
    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Primary Part of Name - Property is required but was missing/)
    @driver.clear_and_send_keys([:id, "agent_names__0__primary_name_"], @hendrix)
  end


  it "can add a related agent" do
    @driver.find_element(:css => '#agent_person_related_agents .subrecord-form-heading .btn:not(.show-all)').click
    @driver.find_element(:css => "select.related-agent-type").select_option("agent_relationship_associative")

    token_input = @driver.find_element(:id, "token-input-agent_related_agents__1__ref_")
    @driver.typeahead_and_select( token_input, @other_agent.names.first['sort_name'] ) 

    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Agent Saved/)
    linked = @driver.find_element(:id, "_agents_people_#{@other_agent.id}").text.sub(/\n.*/, '')

    linked.should eq(@other_agent.names[0]['sort_name'])
  end


  it "can remove contact details" do
    @driver.find_element(:css => '#agent_person_contact_details .subrecord-form-remove').click
    @driver.find_element(:css => '#agent_person_contact_details .confirm-removal').click

    assert(5) {
      @driver.ensure_no_such_element(:id => "agent_agent_contacts__0__name_")
    }

    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

    @driver.ensure_no_such_element(:id => "#agent_agent_contacts__0__name_")
  end


  it "can add an external document to an Agent" do
    @driver.find_element(:css => '#agent_person_external_documents .subrecord-form-heading .btn:not(.show-all)').click

    @driver.clear_and_send_keys([:id, "agent_external_documents__0__title_"], "My URI document")
    @driver.clear_and_send_keys([:id, "agent_external_documents__0__location_"], "http://archivesspace.org")

    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

    @driver.click_and_wait_until_gone(:link => "My Custom Sort Name")

    # check external documents
    external_document_sections = @driver.blocking_find_elements(:css => '#agent_person_external_documents .external-document')
    external_document_sections.length.should eq (1)
    external_document_sections[0].find_element(:link => "http://archivesspace.org")
  end


  it "can add a date of existence to an Agent" do
    @driver.click_and_wait_until_gone(:link, 'Edit')
    @driver.find_element(:css => '#agent_person_dates_of_existence .subrecord-form-heading .btn:not(.show-all)').click

    @driver.find_element(:id => "agent_dates_of_existence__0__date_type_").select_option("single")
    @driver.clear_and_send_keys([:id, "agent_dates_of_existence__0__expression_"], "1973")

    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

    @driver.click_and_wait_until_gone(:link => "My Custom Sort Name")

    # check for date expression
    @driver.find_element_with_text('//div', /1973/)
  end


  it "can add a Biog/Hist note to an Agent" do
    @driver.click_and_wait_until_gone(:link, 'Edit')
    @driver.find_element(:css => '#agent_person_notes .subrecord-form-heading .btn.add-note').click
    @driver.blocking_find_elements(:css => '#agent_person_notes .top-level-note-type')[0].select_option("note_bioghist")

    # ensure note form displayed
    @driver.find_element(:id, "agent_notes__0__label_")

    biog = "Jimi was an American musician and songwriter; and one of the most influential electric guitarists in the history of popular music."
    @driver.execute_script("$('#agent_notes__0__subnotes__0__content_').data('CodeMirror').setValue('#{biog}')")
    @driver.execute_script("$('#agent_notes__0__subnotes__0__content_').data('CodeMirror').save()")

    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")


    @driver.click_and_wait_until_gone(:link => "My Custom Sort Name")

    # check the readonly view
    @driver.find_element_with_text('//div[contains(@class, "subrecord-form-fields")]', /#{biog}/)
  end


  it "can add a sub note" do
    @driver.click_and_wait_until_gone(:link, 'Edit')

    notes = @driver.blocking_find_elements(:css => '#agent_person_notes .subrecord-form-fields')

    # Expand the collapsed note
    notes[0].find_element(:css => '.collapse-subrecord-toggle').click

    # Add a sub note
    @driver.scroll_into_view(notes[0])  
    sleep 1 
    i = 0 
    begin 
      notes[0].find_element(:css => '.subrecord-form-heading .btn.add-sub-note-btn:not(.show-all)').click 
      el = notes[0].find_element_orig(:css => 'select.bioghist-note-type')
      el.select_option('note_outline')
    rescue Selenium::WebDriver::Error::NoSuchElementError => e
      if i < 5 
        i+= 1
        redo
      else
        raise e
      end
    end

    # Woah! Slow down, cowboy. Ensure the sub form is initialised.
    notes[0].find_element(:css => ".subrecord-form-fields.initialised")

    # ensure sub note form displayed
    @driver.find_element(:id, "agent_notes__0__subnotes__2__publish_")

    notes[0].find_element(:css => ".add-level-btn").click
    notes[0].find_element(:css => ".add-sub-item-btn").click
    notes[0].find_element(:css => ".add-sub-item-btn").click

    @driver.clear_and_send_keys([:id, "agent_notes__0__subnotes__2__levels__3__items__4_"], "Woodstock")
    @driver.clear_and_send_keys([:id, "agent_notes__0__subnotes__2__levels__3__items__5_"], "Discography")
    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

    # check the readonly view
    @driver.click_and_wait_until_gone(:link => "My Custom Sort Name")
    @driver.find_element_with_text('//div[contains(@class, "subrecord-form-inline")]', /Woodstock/)
    @driver.find_element_with_text('//div[contains(@class, "subrecord-form-inline")]', /Discography/)
  end


  it "displays the agent in the agent's index page" do
    run_index_round

    path = URI.encode('/agents?filter_term[]={"primary_type":"agent_person"}&sort=create_time+desc')
    @driver.get(URI.join($frontend, path))

    expect {
      @driver.find_paginated_element(:xpath => "//td[contains(text(), 'My Custom Sort Name')]")
    }.to_not raise_error
  end


  it "returns agents in search results and shows their types correctly" do

    @driver.clear_and_send_keys([:id, "global-search-box"], @hendrix)
    @driver.click_and_wait_until_gone(:id => 'global-search-button')

    @driver.find_element_with_text('//td', /My Custom Sort Name/)
    @driver.find_element_with_text('//td', /Person/)
  end
end
