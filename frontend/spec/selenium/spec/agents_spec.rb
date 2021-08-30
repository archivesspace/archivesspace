# frozen_string_literal: true

require_relative '../spec_helper'
require 'net/http'

describe "agents merge" do
  before(:all) do
    @repo = create(:repo, repo_code: "agents_test_#{Time.now.to_i}")

    @driver = Driver.get
    @driver.login_to_repo($admin, @repo)

    @first_agent = create(:json_agent_corporate_entity_full_subrec)
    @second_agent = create(:json_agent_corporate_entity_full_subrec)

    run_all_indexers
  end

  after(:all) do
    @driver ? @driver.quit : next
  end

  it 'displays the full merge page without any errors' do
    @driver.clear_and_send_keys([:id, 'global-search-box'], @first_agent['names'][0]['primary_name'])
    @driver.find_element(id: 'global-search-button').click
    @driver.click_and_wait_until_element_gone(
      @driver.
        find_paginated_element(xpath: "//tr[./td[contains(., '#{@first_agent['names'][0]['primary_name']}')]]").
        find_element(:link, 'Edit')
    )
    @driver.find_element(:link, 'Merge').click
    input = @driver.find_element(:id, 'token-input-merge_ref_')
    @driver.typeahead_and_select(input, @second_agent['names'][0]['primary_name'])
    @driver.find_element(class: 'merge-button').click
    @driver.find_element(id: 'confirmButton').click

    assert { expect(@driver.find_element(css: 'h2').text).to eq('This record will be updated') }
  end

  it "merges record ids" do
    @driver.find_element(id: 'agent_agent_record_identifiers__0__append_').click
    @driver.find_element(:class, 'preview-merge').click

    target_value = @second_agent['agent_record_identifiers'][0]['record_identifier']
    id = "agent_corporate_entity_agent_record_identifier_accordion"

    @driver.find_element(:css, "##{id} div.panel:nth-child(2) span").click
    @driver.find_element_with_text("//div[@id='#{id}']//div", /#{target_value}/)

    @driver.find_element(class: 'close').click
  end

  it "merges agent places" do
    @driver.find_element(id: 'agent_agent_places__0__append_').click
    @driver.find_element(:class, 'preview-merge').click

    target_value = "Place of Birth"
    id = "agent_corporate_entity_agent_place_accordion"

    @driver.find_element(:css, "##{id} div.panel:nth-child(2) span").click
    @driver.find_element_with_text("//div[@id='#{id}']//div", /#{target_value}/)

    @driver.find_element(class: 'close').click
  end

  it "merges names" do
    @driver.find_element(id: 'agent_names__0__append_').click
    @driver.find_element(:class, 'preview-merge').click

    target_value = @second_agent['names'][0]['primary_name']
    id = "agent_name_accordion"

    @driver.find_element(:css, "##{id} div.panel:nth-child(2) span").click
    @driver.find_element_with_text("//div[@id='#{id}']//div", /#{target_value}/)

    @driver.find_element(class: 'close').click
  end
end

describe "disallows agents merge with related agents" do
  before(:all) do
    @repo = create(:repo, repo_code: "agents_test_#{Time.now.to_i}")

    @driver = Driver.get
    @driver.login_to_repo($admin, @repo)

    @first_agent = create(:json_agent_corporate_entity_full_subrec)
    @second_agent = create(:json_agent_corporate_entity_full_subrec)

    run_all_indexers
  end

  after(:all) do
    @driver ? @driver.quit : next
  end

  it 'tries to merge related agents and gets an error' do
    @driver.clear_and_send_keys([:id, 'global-search-box'], @first_agent['names'][0]['primary_name'])
    @driver.find_element(id: 'global-search-button').click
    @driver.find_element(:link, 'Edit').click

    @driver.find_element(css: '#related_agents button.add-related-agent-for-type-btn').click

    related_type_select = @driver.find_element(class: 'related-agent-type')
    related_type_select.select_option('agent_relationship_hierarchical')

    related_agent_linker = @driver.find_element(:id, 'token-input-agent_related_agents__1__ref_')
    @driver.typeahead_and_select(related_agent_linker, @second_agent['names'][0]['primary_name'])

    @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

    @driver.find_element(:link, 'Merge').click
    input = @driver.find_element(:id, 'token-input-merge_ref_')
    @driver.typeahead_and_select(input, @second_agent['names'][0]['primary_name'])

    @driver.find_element(class: 'merge-button').click
    @driver.find_element(id: 'confirmButton').click

    @driver.find_element_with_text('//div[contains(@class, "alert-danger")]', /have a relationship/)
  end
end

describe "agents record CRUD" do
  before(:all) do
    @repo = create(:repo, repo_code: "agents_test_#{Time.now.to_i}")

    @driver = Driver.get
    @driver.login_to_repo($admin, @repo)

    @hendrix = "Hendrix von #{Time.now.to_i}"

    @other_agent = create(:agent_person)

    run_all_indexers
  end

  after(:all) do
    @driver ? @driver.quit : next
  end

  describe 'Full Agent Record' do
    it 'reports errors and warnings when creating an invalid Person Agent' do
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')
      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
      @driver.find_element_with_text('//div[contains(@class, "error")]', /Primary Part of Name - Property is required but was missing/)
    end

    it 'reports a warning when Authority ID is provided without a Source' do
      @driver.clear_and_send_keys([:id, 'agent_names__0__authority_id_'], SecureRandom.hex)
      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      rules_select = @driver.find_element(id: 'agent_names__0__rules_')
      rules_select.select_option('local')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
      @driver.find_element_with_text('//div[contains(@class, "warning")]', /^Source - is required if there is an 'authority id'$/i)
    end

    it 'auto generates Sort Name when other name fields upon save' do
      @driver.find_element(id: 'agent_names__0__source_').select_option('local')

      @driver.clear_and_send_keys([:id, 'agent_names__0__authority_id_'], SecureRandom.hex)
      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      @driver.find_element_with_text('//h2', /#{@hendrix}/)

      @driver.clear_and_send_keys([:id, 'agent_names__0__rest_of_name_'], 'Johnny Allen')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      @driver.find_element_with_text('//h2', /#{@hendrix}, Johnny Allen/)
    end

    it 'changing Direct Order updates Sort Name' do
      @driver.find_element(id: 'agent_names__0__name_order_').select_option('direct')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      @driver.find_element_with_text('//h2', /Johnny Allen #{@hendrix}/)
    end

    it 'throws an error if no sort name is provided and auto gen is false' do
      @driver.find_element(:id, 'agent_names__0__sort_name_auto_generate_').click
      @driver.clear_and_send_keys([:id, 'agent_names__0__sort_name_'], '')
      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
      @driver.find_element_with_text('//div[contains(@class, "error")]', /Sort Name - Property is required but was missing/)
    end

    it 'allows setting of a custom sort name' do
      @driver.clear_and_send_keys([:id, 'agent_names__0__sort_name_'], 'General Patton')
      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      @driver.find_element_with_text('//h2', /General Patton/)
    end

    it 'can add a secondary name and validations match index of name form' do
      @driver.find_element(css: '#agent_person_names .subrecord-form-heading .btn:not(.show-all)').click
      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      @driver.find_element_with_text('//div[contains(@class, "error")]', /Primary Part of Name - Property is required but was missing/)

      @driver.clear_and_send_keys([:id, 'agent_names__1__primary_name_'], @hendrix)
      @driver.clear_and_send_keys([:id, 'agent_names__1__rest_of_name_'], 'Jimi')
    end

    it 'can save a person and view readonly view of person' do
      @driver.find_element(css: '#agent_person_contact_details .subrecord-form-heading .btn:not(.show-all)').click

      @driver.clear_and_send_keys([:id, 'agent_agent_contacts__0__name_'], 'Email Address')
      @driver.clear_and_send_keys([:id, 'agent_agent_contacts__0__email_'], 'jimi@rocknrollheaven.com')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      assert(5) { expect(@driver.find_element(css: '.record-pane h2').text).to eq('General Patton Agent') }
    end

    it 'can add multiple telephone numbers' do
      @driver.find_element(css: '#agent_agent_contacts__0__telephones_ .subrecord-form-heading .btn:not(.show-all)').click

      @driver.clear_and_send_keys([:id, 'agent_agent_contacts__0__telephones__0__number_'], '555-5555')
      @driver.clear_and_send_keys([:id, 'agent_agent_contacts__0__telephones__0__ext_'], '66')

      @driver.find_element(css: '#agent_agent_contacts__0__telephones_ .subrecord-form-heading .btn:not(.show-all)').click
      @driver.clear_and_send_keys([:id, 'agent_agent_contacts__0__telephones__1__number_'], '999-9999')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
      @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Agent Saved/)
    end

    it 'reports errors when updating a Person Agent with invalid data' do
      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], '')
      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
      @driver.find_element_with_text('//div[contains(@class, "error")]', /Primary Part of Name - Property is required but was missing/)
      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)
    end

    it 'can add a related agent' do
      @driver.find_element(css: 'button.add-related-agent-for-type-btn').click
      @driver.find_element(css: 'select.related-agent-type').select_option('agent_relationship_associative')

      token_input = @driver.find_element(:id, 'token-input-agent_related_agents__1__ref_')
      @driver.typeahead_and_select(token_input, @other_agent.names.first['sort_name'])

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      @driver.find_element(css: 'div.alert-success').click

      # will fail here if related agent not added correctly.
      @driver.find_element(css: '#agent_related_agents__0_')
    end

    it 'can remove contact details' do
      @driver.find_element(css: '#agent_person_contact_details .subrecord-form-remove').click
      @driver.find_element(css: '#agent_person_contact_details .confirm-removal').click

      assert(5) do
        @driver.ensure_no_such_element(id: 'agent_agent_contacts__0__name_')
      end

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      @driver.ensure_no_such_element(id: '#agent_agent_contacts__0__name_')
    end

    it 'can add an external document to an Agent' do
      @driver.find_element(css: '#agent_person_external_documents .subrecord-form-heading .btn:not(.show-all)').click

      @driver.clear_and_send_keys([:id, 'agent_external_documents__0__title_'], 'My URI document')
      @driver.clear_and_send_keys([:id, 'agent_external_documents__0__location_'], 'http://archivesspace.org')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      @driver.click_and_wait_until_gone(link: 'General Patton')

      # check external documents
      external_document_sections = @driver.blocking_find_elements(css: '#agent_person_external_documents .external-document')
      expect(external_document_sections.length).to eq 1
      external_document_sections[0].find_element(link: 'http://archivesspace.org')
    end

    it 'can add a date of existence to an Agent' do
      @driver.click_and_wait_until_gone(:link, 'Edit')
      @driver.find_element(css: '#agent_person_dates_of_existence .subrecord-form-heading .btn:not(.show-all)').click
      @driver.find_element(id: 'agent_dates_of_existence__0__date_type_structured_').select_option('single')
      @driver.clear_and_send_keys([:id, 'agent_dates_of_existence__0__structured_date_single__date_expression_'], '1973')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if date of existence not added correctly.
      @driver.find_element(id: 'agent_dates_of_existence__0_')
    end

    it 'can add a record identifier to an Agent' do
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_record_identifier .btn:not(.show-all)').click

      @driver.clear_and_send_keys([:id, 'agent_agent_record_identifiers__0__record_identifier_'], rand(10000))

      @driver.find_element(id: 'agent_agent_record_identifiers__0__source_').select_option('local')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_record_identifiers__0_')
    end

    it 'can add a record identifier to an Agent' do
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_record_identifier .btn:not(.show-all)').click

      @driver.clear_and_send_keys([:id, 'agent_agent_record_identifiers__0__record_identifier_'], rand(10000))

      @driver.find_element(id: 'agent_agent_record_identifiers__0__source_').select_option('local')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_record_identifiers__0_')
    end

    it 'can add a record control subrecord to an Agent' do
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_record_control .btn:not(.show-all)').click

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_record_controls__0_')
    end

    it 'can add an agency code to an Agent' do
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_other_agency_codes .btn:not(.show-all)').click

      @driver.clear_and_send_keys([:id, 'agent_agent_other_agency_codes__0__maintenance_agency_'], rand(10000))

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_other_agency_codes__0_')
    end

    it 'can add a conventions declaration to an Agent' do
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_conventions_declaration .btn:not(.show-all)').click

      @driver.find_element(id: 'agent_agent_conventions_declarations__0__name_rule_').select_option('local')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_conventions_declarations__0_')
    end

    it 'can add maintenance history to an Agent' do
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_maintenance_history .btn:not(.show-all)').click

      @driver.find_element(id: 'agent_agent_maintenance_histories__0__maintenance_event_type_').select_option('created')

      @driver.clear_and_send_keys([:id, 'agent_agent_maintenance_histories__0__event_date_'], '1980-02-12')

      @driver.clear_and_send_keys([:id, 'agent_agent_maintenance_histories__0__agent_'], 'HAL 9000')

      @driver.find_element(id: 'agent_agent_maintenance_histories__0__maintenance_agent_type_').select_option('machine')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_maintenance_histories__0_')
    end

    it 'can add source entry to an Agent' do
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_sources .btn:not(.show-all)').click

      @driver.clear_and_send_keys([:id, 'agent_agent_sources__0__source_entry_'], rand(10000))

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_sources__0_')
    end

    it 'can add alternate set to an Agent' do
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_alternate_set .btn:not(.show-all)').click

      @driver.clear_and_send_keys([:id, 'agent_agent_alternate_sets__0__set_component_'], rand(10000))

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_alternate_sets__0_')
    end

    it 'can add entity ids to an Agent' do
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_identifier .btn:not(.show-all)').click

      @driver.clear_and_send_keys([:id, 'agent_agent_identifiers__0__entity_identifier_'], rand(10000))

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_identifiers__0_')
    end

    it 'can add a name use date to an Agent' do
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_names__0__use_dates_ .btn:not(.show-all)').click

      @driver.find_element(id: 'agent_names__0__use_dates__0__date_type_structured_').select_option('single')
      @driver.clear_and_send_keys([:id, 'agent_names__0__use_dates__0__structured_date_single__date_expression_'], '1973')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_names__0__use_dates__0_')
    end

    it 'can add a parallel name to an Agent' do
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_names__0__parallel_names_ .btn:not(.show-all)').click

      @driver.clear_and_send_keys([:id, 'agent_names__0__parallel_names__0__primary_name_'], rand(10000))

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_names__0__parallel_names__0_')
    end

    it 'can add a name use date to a parallel name' do
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_names__0__parallel_names_ .btn:not(.show-all)').click

      @driver.clear_and_send_keys([:id, 'agent_names__0__parallel_names__0__primary_name_'], rand(10000))

      @driver.find_element(css: '#agent_names__0__parallel_names__0__use_dates_ .btn:not(.show-all)').click

      @driver.find_element(id: 'agent_names__0__parallel_names__0__use_dates__0__date_type_structured_').select_option('single')
      @driver.clear_and_send_keys([:id, 'agent_names__0__parallel_names__0__use_dates__0__structured_date_single__date_expression_'], '1973')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_names__0__parallel_names__0__use_dates__0_')
    end

    it 'can add gender to an Agent' do
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_gender .btn:not(.show-all)').click

      @driver.find_element(id: 'agent_agent_genders__0__gender_').select_option('not_specified')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_genders__0_')
    end

    it 'can add date to a gender' do
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_gender .btn:not(.show-all)').click

      @driver.find_element(id: 'agent_agent_genders__0__gender_').select_option('not_specified')


      @driver.find_element(css: '#agent_agent_genders__0__dates_ .btn:not(.show-all)').click

      @driver.find_element(id: 'agent_agent_genders__0__dates__0__date_type_structured_').select_option('single')
      @driver.clear_and_send_keys([:id, 'agent_agent_genders__0__dates__0__structured_date_single__date_expression_'], '1973')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_genders__0__dates__0_')
    end

    it 'can add a note to a gender' do
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_gender .btn:not(.show-all)').click

      @driver.find_element(id: 'agent_agent_genders__0__gender_').select_option('not_specified')

      @driver.find_element(css: '#agent_gender .subrecord-form-heading .btn.add-note').click
      @driver.find_element(css: '.top-level-note-type').select_option('note_text')

      @driver.execute_script("$('#agent_agent_genders__0__notes__0__content_').data('CodeMirror').setValue('this is a note')")
      @driver.execute_script("$('#agent_agent_genders__0__notes__0__content_').data('CodeMirror').save()")

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_genders__0__notes__0_')
    end

    it 'can create an agent_place' do
      # create subject
      @driver.find_element(:link, 'Create').click
      @driver.click_and_wait_until_gone(:link, 'Subject')
      term = rand(10000).to_s

      @driver.find_element(id: 'subject_source_').select_option('local')

      @driver.clear_and_send_keys([:id, 'subject_terms__0__term_'], term)
      @driver.find_element(id: 'subject_terms__0__term_type_').select_option('geographic')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
      run_index_round

      # create agent and add subrecord
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_place .btn:not(.show-all)').click

      # role
      @driver.find_element(id: 'agent_agent_places__0__place_role_').select_option('place_of_birth')

      # subject
      @driver.find_element(css: '#agent_agent_places__0__subjects_ .btn:not(.show-all)').click

      token_input = @driver.find_element(:id, 'token-input-agent_agent_places__0__subjects__0__ref_')

      @driver.typeahead_and_select(token_input, term)

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_places__0_')
    end

    it 'can add a date to an agent_place' do
      # create subject
      @driver.find_element(:link, 'Create').click
      @driver.click_and_wait_until_gone(:link, 'Subject')
      term = rand(10000).to_s

      @driver.find_element(id: 'subject_source_').select_option('local')

      @driver.clear_and_send_keys([:id, 'subject_terms__0__term_'], term)
      @driver.find_element(id: 'subject_terms__0__term_type_').select_option('geographic')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
      run_index_round

      # create agent and add subrecord
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_place .btn:not(.show-all)').click

      # role
      @driver.find_element(id: 'agent_agent_places__0__place_role_').select_option('place_of_birth')

      # subject
      @driver.find_element(css: '#agent_agent_places__0__subjects_ .btn:not(.show-all)').click

      token_input = @driver.find_element(:id, 'token-input-agent_agent_places__0__subjects__0__ref_')

      @driver.typeahead_and_select(token_input, term)


      # date
      @driver.find_element(css: '#agent_agent_places__0__dates_ .btn:not(.show-all)').click

      @driver.find_element(id: 'agent_agent_places__0__dates__0__date_type_structured_').select_option('single')
      @driver.clear_and_send_keys([:id, 'agent_agent_places__0__dates__0__structured_date_single__date_expression_'], '1973')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_places__0__dates__0_')
    end

    it 'can add a note to an agent_place' do
      # create subject
      @driver.find_element(:link, 'Create').click
      @driver.click_and_wait_until_gone(:link, 'Subject')
      term = rand(10000).to_s

      @driver.find_element(id: 'subject_source_').select_option('local')

      @driver.clear_and_send_keys([:id, 'subject_terms__0__term_'], term)
      @driver.find_element(id: 'subject_terms__0__term_type_').select_option('geographic')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
      run_index_round

      # create agent and add subrecord
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_place .btn:not(.show-all)').click

      # role
      @driver.find_element(id: 'agent_agent_places__0__place_role_').select_option('place_of_birth')

      # subject
      @driver.find_element(css: '#agent_agent_places__0__subjects_ .btn:not(.show-all)').click

      token_input = @driver.find_element(:id, 'token-input-agent_agent_places__0__subjects__0__ref_')

      @driver.typeahead_and_select(token_input, term)

      # note
      @driver.find_element(css: '#agent_person_agent_place .subrecord-form-heading .btn.add-note').click
      @driver.find_element(css: '.top-level-note-type').select_option('note_text')

      @driver.execute_script("$('#agent_agent_places__0__notes__0__content_').data('CodeMirror').setValue('this is a note')")
      @driver.execute_script("$('#agent_agent_places__0__notes__0__content_').data('CodeMirror').save()")

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_places__0__notes__0_')
    end

    it 'can create an agent_occupation' do
      # create subject
      @driver.find_element(:link, 'Create').click
      @driver.click_and_wait_until_gone(:link, 'Subject')
      term = rand(10000).to_s

      @driver.find_element(id: 'subject_source_').select_option('local')

      @driver.clear_and_send_keys([:id, 'subject_terms__0__term_'], term)
      @driver.find_element(id: 'subject_terms__0__term_type_').select_option('occupation')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
      run_index_round

      # create agent and add subrecord
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_occupation .btn:not(.show-all)').click

      # subject
      @driver.find_element(css: '#agent_agent_occupations__0__subjects_ .btn:not(.show-all)').click

      token_input = @driver.find_element(:id, 'token-input-agent_agent_occupations__0__subjects__0__ref_')

      @driver.typeahead_and_select(token_input, term)

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_occupations__0_')
    end

    it 'can add a date to an agent_occupation' do
      # create subject
      @driver.find_element(:link, 'Create').click
      @driver.click_and_wait_until_gone(:link, 'Subject')
      term = rand(10000).to_s

      @driver.find_element(id: 'subject_source_').select_option('local')

      @driver.clear_and_send_keys([:id, 'subject_terms__0__term_'], term)
      @driver.find_element(id: 'subject_terms__0__term_type_').select_option('occupation')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
      run_index_round

      # create agent and add subrecord
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_occupation .btn:not(.show-all)').click

      # subject
      @driver.find_element(css: '#agent_agent_occupations__0__subjects_ .btn:not(.show-all)').click

      token_input = @driver.find_element(:id, 'token-input-agent_agent_occupations__0__subjects__0__ref_')

      @driver.typeahead_and_select(token_input, term)


      # date
      @driver.find_element(css: '#agent_agent_occupations__0__dates_ .btn:not(.show-all)').click

      @driver.find_element(id: 'agent_agent_occupations__0__dates__0__date_type_structured_').select_option('single')
      @driver.clear_and_send_keys([:id, 'agent_agent_occupations__0__dates__0__structured_date_single__date_expression_'], '1973')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_occupations__0__dates__0_')
    end

    it 'can add a note to an agent_occupation' do
      # create subject
      @driver.find_element(:link, 'Create').click
      @driver.click_and_wait_until_gone(:link, 'Subject')
      term = rand(10000).to_s

      @driver.find_element(id: 'subject_source_').select_option('local')

      @driver.clear_and_send_keys([:id, 'subject_terms__0__term_'], term)
      @driver.find_element(id: 'subject_terms__0__term_type_').select_option('occupation')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
      run_index_round

      # create agent and add subrecord
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_occupation .btn:not(.show-all)').click

      # subject
      @driver.find_element(css: '#agent_agent_occupations__0__subjects_ .btn:not(.show-all)').click

      token_input = @driver.find_element(:id, 'token-input-agent_agent_occupations__0__subjects__0__ref_')

      @driver.typeahead_and_select(token_input, term)

      # note
      @driver.find_element(css: '#agent_person_agent_occupation .subrecord-form-heading .btn.add-note').click
      @driver.find_element(css: '.top-level-note-type').select_option('note_text')

      @driver.execute_script("$('#agent_agent_occupations__0__notes__0__content_').data('CodeMirror').setValue('this is a note')")
      @driver.execute_script("$('#agent_agent_occupations__0__notes__0__content_').data('CodeMirror').save()")

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_occupations__0__notes__0_')
    end

    it 'can create an agent_function' do
      # create subject
      @driver.find_element(:link, 'Create').click
      @driver.click_and_wait_until_gone(:link, 'Subject')
      term = rand(10000).to_s

      @driver.find_element(id: 'subject_source_').select_option('local')

      @driver.clear_and_send_keys([:id, 'subject_terms__0__term_'], term)
      @driver.find_element(id: 'subject_terms__0__term_type_').select_option('function')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
      run_index_round

      # create agent and add subrecord
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_function .btn:not(.show-all)').click

      # subject
      @driver.find_element(css: '#agent_agent_functions__0__subjects_ .btn:not(.show-all)').click

      token_input = @driver.find_element(:id, 'token-input-agent_agent_functions__0__subjects__0__ref_')

      @driver.typeahead_and_select(token_input, term)

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_functions__0_')
    end

    it 'can add a date to an agent_function' do
      # create subject
      @driver.find_element(:link, 'Create').click
      @driver.click_and_wait_until_gone(:link, 'Subject')
      term = rand(10000).to_s

      @driver.find_element(id: 'subject_source_').select_option('local')

      @driver.clear_and_send_keys([:id, 'subject_terms__0__term_'], term)
      @driver.find_element(id: 'subject_terms__0__term_type_').select_option('function')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
      run_index_round

      # create agent and add subrecord
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_function .btn:not(.show-all)').click

      # subject
      @driver.find_element(css: '#agent_agent_functions__0__subjects_ .btn:not(.show-all)').click

      token_input = @driver.find_element(:id, 'token-input-agent_agent_functions__0__subjects__0__ref_')

      @driver.typeahead_and_select(token_input, term)

      # date
      @driver.find_element(css: '#agent_agent_functions__0__dates_ .btn:not(.show-all)').click

      @driver.find_element(id: 'agent_agent_functions__0__dates__0__date_type_structured_').select_option('single')
      @driver.clear_and_send_keys([:id, 'agent_agent_functions__0__dates__0__structured_date_single__date_expression_'], '1973')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_functions__0__dates__0_')
    end

    it 'can add a note to an agent_function' do
      # create subject
      @driver.find_element(:link, 'Create').click
      @driver.click_and_wait_until_gone(:link, 'Subject')
      term = rand(10000).to_s

      @driver.find_element(id: 'subject_source_').select_option('local')

      @driver.clear_and_send_keys([:id, 'subject_terms__0__term_'], term)
      @driver.find_element(id: 'subject_terms__0__term_type_').select_option('function')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
      run_index_round

      # create agent and add subrecord
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_function .btn:not(.show-all)').click

      # subject
      @driver.find_element(css: '#agent_agent_functions__0__subjects_ .btn:not(.show-all)').click

      token_input = @driver.find_element(:id, 'token-input-agent_agent_functions__0__subjects__0__ref_')

      @driver.typeahead_and_select(token_input, term)

      # note
      @driver.find_element(css: '#agent_person_agent_function .subrecord-form-heading .btn.add-note').click
      @driver.find_element(css: '.top-level-note-type').select_option('note_text')

      @driver.execute_script("$('#agent_agent_functions__0__notes__0__content_').data('CodeMirror').setValue('this is a note')")
      @driver.execute_script("$('#agent_agent_functions__0__notes__0__content_').data('CodeMirror').save()")

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_functions__0__notes__0_')
    end

    it 'can create an agent_topic' do
      # create subject
      @driver.find_element(:link, 'Create').click
      @driver.click_and_wait_until_gone(:link, 'Subject')
      term = rand(10000).to_s

      @driver.find_element(id: 'subject_source_').select_option('local')

      @driver.clear_and_send_keys([:id, 'subject_terms__0__term_'], term)
      @driver.find_element(id: 'subject_terms__0__term_type_').select_option('topical')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
      run_index_round

      # create agent and add subrecord
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_topic .btn:not(.show-all)').click

      # subject
      @driver.find_element(css: '#agent_agent_topics__0__subjects_ .btn:not(.show-all)').click

      token_input = @driver.find_element(:id, 'token-input-agent_agent_topics__0__subjects__0__ref_')

      @driver.typeahead_and_select(token_input, term)

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_topics__0_')
    end

    it 'can add a date to an agent_topic' do
      # create subject
      @driver.find_element(:link, 'Create').click
      @driver.click_and_wait_until_gone(:link, 'Subject')
      term = rand(10000).to_s

      @driver.find_element(id: 'subject_source_').select_option('local')

      @driver.clear_and_send_keys([:id, 'subject_terms__0__term_'], term)
      @driver.find_element(id: 'subject_terms__0__term_type_').select_option('topical')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
      run_index_round

      # create agent and add subrecord
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_topic .btn:not(.show-all)').click

      # subject
      @driver.find_element(css: '#agent_agent_topics__0__subjects_ .btn:not(.show-all)').click

      token_input = @driver.find_element(:id, 'token-input-agent_agent_topics__0__subjects__0__ref_')

      @driver.typeahead_and_select(token_input, term)

      # date
      @driver.find_element(css: '#agent_agent_topics__0__dates_ .btn:not(.show-all)').click

      @driver.find_element(id: 'agent_agent_topics__0__dates__0__date_type_structured_').select_option('single')
      @driver.clear_and_send_keys([:id, 'agent_agent_topics__0__dates__0__structured_date_single__date_expression_'], '1973')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_topics__0__dates__0_')
    end

    it 'can add a note to an agent_topic' do
      # create subject
      @driver.find_element(:link, 'Create').click
      @driver.click_and_wait_until_gone(:link, 'Subject')
      term = rand(10000).to_s

      @driver.find_element(id: 'subject_source_').select_option('local')

      @driver.clear_and_send_keys([:id, 'subject_terms__0__term_'], term)
      @driver.find_element(id: 'subject_terms__0__term_type_').select_option('topical')

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
      run_index_round

      # create agent and add subrecord
      @driver.find_element(:link, 'Create').click
      @driver.find_element(:link, 'Agent').click
      @driver.click_and_wait_until_gone(:link, 'Person')

      @driver.clear_and_send_keys([:id, 'agent_names__0__primary_name_'], @hendrix)

      @driver.find_element(css: '#agent_person_agent_topic .btn:not(.show-all)').click

      # subject
      @driver.find_element(css: '#agent_agent_topics__0__subjects_ .btn:not(.show-all)').click

      token_input = @driver.find_element(:id, 'token-input-agent_agent_topics__0__subjects__0__ref_')

      @driver.typeahead_and_select(token_input, term)

      # note
      @driver.find_element(css: '#agent_person_agent_topic .subrecord-form-heading .btn.add-note').click
      @driver.find_element(css: '.top-level-note-type').select_option('note_text')

      @driver.execute_script("$('#agent_agent_topics__0__notes__0__content_').data('CodeMirror').setValue('this is a note')")
      @driver.execute_script("$('#agent_agent_topics__0__notes__0__content_').data('CodeMirror').save()")

      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if subrecord not added correctly.
      @driver.find_element(id: 'agent_agent_topics__0__notes__0_')
    end

    it 'can add a Biog/Hist note to an Agent' do
      @driver.find_element(css: '#agent_person_notes .subrecord-form-heading .btn.add-note').click
      @driver.find_element(css: '.top-level-note-type').select_option('note_bioghist')

      # ensure note form displayed
      @driver.find_element(:id, 'agent_notes__0__label_')

      biog = 'Jimi was an American musician and songwriter; and one of the most influential electric guitarists in the history of popular music.'

      @driver.execute_script("$('#agent_notes__0__subnotes__0__content_').data('CodeMirror').setValue('#{biog}')")
      @driver.execute_script("$('#agent_notes__0__subnotes__0__content_').data('CodeMirror').save()")


      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if date of existence not added correctly.
      @driver.find_element(id: 'agent_notes__0_')
    end

    it 'can add a General Context note to an Agent' do
      #@driver.click_and_wait_until_gone(:link, 'Edit')
      @driver.find_element(css: '#agent_person_notes .subrecord-form-heading .btn.add-note').click
      @driver.find_element(css: '.top-level-note-type').select_option('note_general_context')

      # ensure note form displayed
      @driver.find_element(:id, 'agent_notes__1__label_')

      biog = 'general context'

      @driver.execute_script("$('#agent_notes__1__subnotes__0__content_').data('CodeMirror').setValue('#{biog}')")
      @driver.execute_script("$('#agent_notes__1__subnotes__0__content_').data('CodeMirror').save()")


      @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

      # will fail here if date of existence not added correctly.
      @driver.find_element(id: 'agent_notes__1_')
    end

    it "displays the agent in the agent's index page" do
      run_all_indexers

      path = URI.encode('/agents?filter_term[]={"primary_type":"agent_person"}&sort=create_time+desc')
      @driver.get(URI.join($frontend, path))

      expect do
        @driver.find_paginated_element(xpath: "//td[contains(text(), 'General Patton')]")
      end.not_to raise_error
    end

    it 'returns agents in search results and shows their types correctly' do
      @driver.clear_and_send_keys([:id, 'global-search-box'], @hendrix)
      @driver.click_and_wait_until_gone(id: 'global-search-button')

      @driver.find_element_with_text('//td', /General Patton/)
      @driver.find_element_with_text('//td', /Person/)
    end

    it 'will not delete a corp entity agent linked to a repo' do
      @driver.clear_and_send_keys([:id, 'global-search-box'], @repo.repo_code)
      @driver.click_and_wait_until_gone(id: 'global-search-button')

      @driver.click_and_wait_until_gone(:link, 'Edit')

      @driver.find_element(:css, '.delete-record.btn').click
      @driver.click_and_wait_until_gone(:css, '#confirmChangesModal #confirmButton')

      assert (5) do
        @driver.find_element_with_text('//div[contains(@class, "alert-danger")]', /This agent is linked to a repository and can't be removed./)
      end
    end
  end

  describe 'Light Agent Record' do
    before(:all) do
      @corp_agent_full = create(:json_agent_corporate_entity_full_subrec)
      @corp_agent_basic = create(:agent_corporate_entity)
      run_all_indexers

      # user w/o full mode permissions
      @data_entry_user = create_user(@repo => ['repository-advanced-data-entry'])
      @driver.login_to_repo(@data_entry_user, @repo)
      @driver.navigate.to($frontend + "/agents/agent_person/new")
    end

    it 'displays agent_record_identifiers in form' do
      expect(@driver.is_visible?(:css, "#agent_person_agent_record_identifier")).to eq(true)
    end

    it 'hides agent_record_control from form' do
      expect(@driver.is_visible?(:css, "#agent_person_agent_record_control")).to eq(false)
    end

    it 'hides agent_other_agency_codes from form' do
      expect(@driver.is_visible?(:css, "#agent_person_agent_other_agency_codes")).to eq(false)
    end

    it 'hides agent_conventions_declarations from form' do
      expect(@driver.is_visible?(:css, "#agent_person_agent_conventions_declaration")).to eq(false)
    end

    it 'hides agent_maintenance_histories from form' do
      expect(@driver.is_visible?(:css, "#agent_person_agent_maintenance_history")).to eq(false)
    end

    it 'hides agent_other_agency_codes from form' do
      expect(@driver.is_visible?(:css, "#agent_person_agent_sources")).to eq(false)
    end

    it 'hides agent_sources from form' do
      expect(@driver.is_visible?(:css, "#agent_person_agent_sources")).to eq(false)
    end

    it 'hides agent_alternate_sets from form' do
      expect(@driver.is_visible?(:css, "#agent_person_agent_alternate_set")).to eq(false)
    end

    it 'displays agent_identifiers in form' do
      expect(@driver.is_visible?(:css, "#agent_person_agent_identifier")).to eq(true)
    end

    it 'displays agent_names in form' do
      expect(@driver.is_visible?(:css, "#agent_person_names")).to eq(true)
    end

    it 'displays dates of existence in form' do
      expect(@driver.is_visible?(:css, "#agent_person_dates_of_existence")).to eq(true)
    end

    it 'hides agent_genders from form' do
      expect(@driver.is_visible?(:css, "#agent_person_agent_gender")).to eq(false)
    end

    it 'hides agent_places from form' do
      expect(@driver.is_visible?(:css, "#agent_person_agent_place")).to eq(false)
    end

    it 'hides agent_occupations from form' do
      expect(@driver.is_visible?(:css, "#agent_person_agent_occupation")).to eq(false)
    end

    it 'hides agent_functions from form' do
      expect(@driver.is_visible?(:css, "#agent_person_agent_function")).to eq(false)
    end

    it 'hides agent_topic from form' do
      expect(@driver.is_visible?(:css, "#agent_person_agent_topic")).to eq(false)
    end

    it 'hides used_languages from form' do
      expect(@driver.is_visible?(:css, "#agent_person_agent_used_language")).to eq(false)
    end

    it 'displays agent_contacts in form' do
      # not available to data entry user
      expect(@driver.is_visible?(:css, "#agent_person_contact_details")).to eq(false)
    end

    it 'displays agent_notes in form' do
      expect(@driver.is_visible?(:css, "#agent_person_notes")).to eq(true)
    end

    it 'displays agent_external_documents in form' do
      expect(@driver.is_visible?(:css, "#agent_person_external_documents")).to eq(true)
    end

    it 'hides agent_resources from form' do
      expect(@driver.is_visible?(:css, "#agent_person_agent_resource")).to eq(false)
    end

    it 'displays related_agents in form' do
      expect(@driver.is_visible?(:css, "#related_agents")).to eq(true)
    end

    it 'alerts light mode users that there is hidden record content' do
      @driver.navigate.to($frontend + "/agents/agent_corporate_entity/#{@corp_agent_full.id}/edit")

      expect do
        @driver.find_element_with_text('//div[contains(@class, "alert-warning")]', /This agent has data that is only editable in Full mode. To enable it, ask your administrator to enable Full Mode on this instance and grant you Full Mode permission./)
      end.not_to raise_error
    end

    it 'does not alert light mode users of hidden content when there is none' do
      @driver.navigate.to($frontend + "/agents/agent_corporate_entity/#{@corp_agent_basic.id}/edit")

      expect do
        @driver.find_element(xpath: "//h2[contains(text(), '#{@corp_agent_basic.display_name['primary_name']}')]")
      end.not_to raise_error

      expect(@driver.find_element_with_text('//div[contains(@class, "alert-warning")]', /This agent has data that is only editable in Full mode. To enable it, ask your administrator to enable Full Mode on this instance and grant you Full Mode permission./, true, true)
      ).to be_nil
    end
  end
end

describe "agents record with too many related agents" do
  before(:all) do
    @repo = create(:repo, repo_code: "agents_test_#{Time.now.to_i}")

    @driver = Driver.get
    @driver.login_to_repo($admin, @repo)

    @big_agent = create(:agent_person, :related_agents => (1..5).map {
                      JSONModel(:agent_relationship_parentchild).new({ :ref => create(:agent_person).uri, :relator => 'is_child_of' }).to_hash
                    })
    @small_agent = create(:agent_person, :related_agents => (1..4).map {
                             JSONModel(:agent_relationship_parentchild).new({ :ref => create(:agent_person).uri, :relator => 'is_child_of' }).to_hash
                           })
  end

  after(:all) do
    @driver ? @driver.quit : next
  end

  it "does not lazy load related agents when there are fewer than four" do
    path = URI.encode("/agents/agent_person/#{@small_agent.id}/edit")
    puts path
    @driver.get(URI.join($frontend, path))
    (0..3).each do |i|
      expect(@driver.find_element(id: "agent_related_agents__#{i}_")).not_to be_nil
    end
  end

  it "lazy loads related agents when there are more than four" do
    path = URI.encode("/agents/agent_person/#{@big_agent.id}/edit")
    @driver.get(URI.join($frontend, path))
    expect(@driver.find_element(css: ".alert-too-many")).not_to be_nil
    @driver.find_elements(css: '.alert-too-many').each { |c| c.click }
    (0..4).each do |i|
      expect(@driver.find_element(id: "agent_related_agents__#{i}_")).not_to be_nil
    end
  end
end
