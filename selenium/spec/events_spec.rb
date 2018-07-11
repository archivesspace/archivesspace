require_relative 'spec_helper'

describe "Events" do

  before(:all) do
    @repo = create(:repo, :repo_code => "events_test_#{Time.now.to_i}")
    set_repo(@repo)

    @accession = create(:accession, :title => "Events link to this accession")
    @archivist_user = create_user(@repo => ['repository-archivists'])

    name_string = "Geddy Lee #{Time.now.to_i}"

    name = build(:name_person,
                 :name_order => "inverted",
                 :primary_name => name_string,
                 :rest_of_name => name_string,
                 :sort_name => name_string)

    @agent = create(:agent_person, :names => [name])

    run_index_round

    @driver = Driver.get.login_to_repo(@archivist_user, @repo)
  end


  after(:all) do
    @driver.quit
  end


  it "creates an event and links it to an agent and an agent as a source" do
    @driver.find_element(:link, "Create").click
    @driver.click_and_wait_until_gone(:link, "Event")
    @driver.find_element(:id, "event_event_type_").select_option('accession')
    @driver.find_element(:id, "event_outcome_").select_option("pass")
    @driver.clear_and_send_keys([:id, "event_outcome_note_"], "OK, that's another lie: all test subjects perished.")

    @driver.find_element(:id, "event_date__date_type_").select_option("single")
    @driver.clear_and_send_keys([:id, "event_date__begin_"], ["1776", :tab])

    agent_subform = @driver.find_element(:id, "event_linked_agents__0__role_").
      nearest_ancestor('div[contains(@class, "subrecord-form-container")]')

    @driver.find_element(:id, "event_linked_agents__0__role_").select_option('recipient')

    token_input = agent_subform.find_element(:id, "token-input-event_linked_agents__0__ref_")
    @driver.typeahead_and_select( token_input, "Admin" )

    @driver.find_element(:id, "event_linked_records__0__role_").select_option('source')

    record_subform = @driver.find_element(:id, "event_linked_records__0__role_").
      nearest_ancestor('div[contains(@class, "subrecord-form-container")]')

    token_input = record_subform.find_element(:id, "token-input-event_linked_records__0__ref_")
    @driver.typeahead_and_select(token_input, "Geddy")

    @driver.find_element(:css => "form#new_event button[type='submit']").click

    # Success!
    assert(5) {
      @driver.find_element_with_text('//div', /Event Created/).should_not be_nil
    }
    run_all_indexers

    @driver.get($frontend)

    @driver.find_element(:link, "Browse").click
    @driver.wait_for_dropdown
    @driver.click_and_wait_until_gone(:link, "Agents")

    @driver.clear_and_send_keys([:css, ".sidebar input.text-filter-field"], "Geddy*" )
    @driver.click_and_wait_until_gone(:css, ".sidebar input.text-filter-field + div button")
    @driver.click_and_wait_until_element_gone(@driver.find_element_with_text('//tr', /Geddy/).find_element(:link, 'View'))

    @driver.find_element_with_text('//td', /accession/)
  end

  it "creates an event and links it to an agent and accession" do
    @driver.find_element(:link, "Create").click
    @driver.click_and_wait_until_gone(:link, "Event")
    @driver.find_element(:id, "event_event_type_").select_option('virus_check')
    @driver.find_element(:id, "event_outcome_").select_option("pass")
    @driver.clear_and_send_keys([:id, "event_outcome_note_"], "OK, that's a lie: all test subjects perished.")

    @driver.find_element(:id, "event_date__date_type_").select_option("single")
    @driver.clear_and_send_keys([:id, "event_date__begin_"], ["2000-01-01", :tab])
    

    agent_subform = @driver.find_element(:id, "event_linked_agents__0__role_").
      nearest_ancestor('div[contains(@class, "subrecord-form-container")]')
    
    @driver.find_element(:id, "event_linked_agents__0__role_").select_option('recipient')
    token_input = agent_subform.find_element(:id, "token-input-event_linked_agents__0__ref_")
    @driver.typeahead_and_select( token_input, "Geddy" )   

    @driver.find_element(:id, "event_linked_records__0__role_").select_option('source')

    record_subform = @driver.find_element(:id, "event_linked_records__0__role_").
        nearest_ancestor('div[contains(@class, "subrecord-form-container")]')
    token_input = record_subform.find_element(:id, "token-input-event_linked_records__0__ref_")
    @driver.typeahead_and_select( token_input, @accession.title )   

    @driver.find_element(:css => "form#new_event button[type='submit']").click

    # Success!
    assert(5) {
      @driver.find_element_with_text('//div', /Event Created/).should_not be_nil
    }
  end

  it "can add an external document to an Event" do
    @driver.find_element(:css => '#event_external_documents_ .subrecord-form-heading .btn:not(.show-all)').click
    @driver.clear_and_send_keys([:id, "event_external_documents__0__title_"], "My URI document")
    @driver.clear_and_send_keys([:id, "event_external_documents__0__location_"], "http://archivesspace.org")

    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

    # check external documents
    external_document_sections = @driver.blocking_find_elements(:css => '#event_external_documents_ .subrecord-form-wrapper')
    external_document_sections.length.should eq (1)
    external_document_sections[0].find_element(:link => "http://archivesspace.org")
  end


  it "should be searchable" do
    run_index_round
    @driver.find_element(:id, 'global-search-button').click
    @driver.find_element(:link, "Event").click
    assert(5) { @driver.find_element_with_text("//h2", /Search Results/) }
  end

end
