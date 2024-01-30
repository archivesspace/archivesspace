# frozen_string_literal: true

require_relative '../spec_helper'
require 'pry'

describe 'Resources and archival objects' do
  before(:all) do
    @repo = create(:repo, repo_code: "resources_test_#{Time.now.to_i}")
    set_repo @repo

    @accession = create(:accession,
                        collection_management: build(:collection_management))

    @resource = create(:resource)

    @archival_object = create(:archival_object,
                              component_id: 'component-id',
                              resource: { 'ref' => @resource.uri })

    @user = create_user(@repo => ['repository-managers'])
    @driver = Driver.get.login_to_repo(@user, @repo)
  end

  before(:each) do
    @driver.go_home
  end

  after(:all) do
    @driver ? @driver.quit : next
  end

  it 'can spawn a resource from an existing accession' do
    @driver.get_view_page(@accession)

    # Spawn a resource from the accession we just created
    @driver.find_element(:link, 'Spawn').click
    @driver.find_element(:link, 'Resource').click

    # The relationship back to the original accession is prepopulated
    expect(@driver.find_element(css: 'div.accession').text).to match(@accession.title)

    @driver.complete_4part_id('resource_id_%d_')

    @driver.find_element(:id, 'resource_level_').select_option('collection')

    res_lang_combo = @driver.find_element(xpath: '//*[@id="resource_lang_materials__0__language_and_script__language_"]')
    res_lang_combo.clear
    res_lang_combo.click
    res_lang_combo.send_keys('eng')
    res_lang_combo.send_keys(:tab)

    fa_lang_combo = @driver.find_element(xpath: '//*[@id="resource_finding_aid_language_"]')
    fa_lang_combo.clear
    fa_lang_combo.click
    fa_lang_combo.send_keys('eng')
    fa_lang_combo.send_keys(:tab)

    fa_script_combo = @driver.find_element(xpath: '//*[@id="resource_finding_aid_script_"]')
    fa_script_combo.clear
    fa_script_combo.click
    fa_script_combo.send_keys('Latn')
    fa_script_combo.send_keys(:tab)

    # no collection managment
    expect(@driver.find_elements(:id, 'resource_collection_management__cataloged_note_').length).to eq(0)

    # condition and content descriptions have come across as notes fields
    notes_toggle = @driver.blocking_find_elements(css: '#resource_notes_ .collapse-subrecord-toggle')
    notes_toggle[0].click
    @driver.wait_for_ajax

    @driver.find_element_orig(:css, '#resource_notes__0__subnotes__0__content_').wait_for_class('initialised')
    @driver.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').toTextArea()")
    assert(5) { expect(@driver.find_element(id: 'resource_notes__0__subnotes__0__content_').attribute('value')).to eq(@accession.content_description) }

    notes_toggle[1].click
    @driver.wait_for_ajax

    sleep 1
    expect(@driver.find_element(id: 'resource_notes__1__content__0_').text).to match(@accession.condition_description)

    @driver.find_element(id: 'resource_dates__0__date_type_').select_option('single')
    @driver.clear_and_send_keys([:id, 'resource_dates__0__begin_'], '1978')

    @driver.clear_and_send_keys([:id, 'resource_extents__0__number_'], '10')
    @driver.find_element(id: 'resource_extents__0__extent_type_').select_option('cassettes')

    @driver.click_and_wait_until_gone(css: "form#resource_form button[type='submit']")

    # Success!
    expect(@driver.find_element_with_text('//div', /Resource .* created/)).not_to be_nil
    expect(@driver.find_element(:id, 'resource_dates__0__begin_').attribute('value')).to eq('1978')

    run_periodic_index
  end

  it 'reports errors and warnings when creating an invalid Resource' do
    @driver.find_element(:link, 'Create').click
    @driver.click_and_wait_until_gone(:link, 'Resource')
    @driver.find_hidden_element(:css, '#resource_title_').wait_for_class('initialised')
    @driver.execute_script("$('#resource_title_').data('CodeMirror').setValue('')")
    @driver.find_element(css: "form#resource_form button[type='submit']").click

    @driver.find_element_with_text('//div[contains(@class, "error")]', /Identifier - Property is required but was missing/)
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Title - Property is required but was missing/)
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Number - Property is required but was missing/)
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Type - Property is required but was missing/)
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Language of Description - Property is required but was missing/)
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Script of Description - Property is required but was missing/)

    # checks that form field has error styling (red outline)
    expect(@driver.find_element(css: '.identifier-fields').attribute('class')).to include('has-error')

    @driver.click_and_wait_until_gone(:css, 'a.btn.btn-cancel')
  end

  it 'prepopulates the top container modal with search for current resource when linking on the resource edit page' do
    # Create some top containers
    location = create(:location)
    container_location = build(:container_location,
                               ref: location.uri)
    container = create(:top_container,
                        container_locations: [container_location])
    ('A'..'E').each do |l|
      create(:top_container,
             indicator: "Letter #{l}",
             container_locations: [container_location])
    end

    run_index_round

    @driver.get_edit_page(@resource)

    @driver.find_element_with_text('//button', /Add Container Instance/).click

    resource_title = @driver.find_element(css: 'h2').text[0...-9]

    @driver.find_element(css: '#resource_instances__0__instance_type_').select_option('text')

    add_instance_fields_area = @driver.find_element(css: '#resource_instances__0__container_')
    add_instance_fields_area.find_element(css: '.btn.btn-default.dropdown-toggle.last').click
    @driver.wait_for_dropdown
    @driver.find_elements(:link, 'Browse')[1].click

    sleep 1

    @driver.find_element(css: '.token-input-delete-token').click
    @driver.clear_and_send_keys([:css, '#q'], '*')

    inputs = @driver.find_element(css: '.modal-content').find_elements(css: 'input')
    inputs.each do |input|
      if input.attribute('value') == "Search"
        input.click
        break
      end
    end

    sleep 2

    @driver.find_element(css: '.modal-content').find_elements(css: 'tr')[1].find_element(css: 'input').click

    @driver.find_element(css: "#addSelectedButton").click
    @driver.find_element(css: "form#resource_form button[type='submit']").click

    run_periodic_index

    add_instance_fields_area = @driver.find_element(css: '#resource_instances__0__container_')
    add_instance_fields_area.find_element(css: '.btn.btn-default.dropdown-toggle.last').click
    @driver.wait_for_dropdown
    @driver.find_elements(:link, 'Browse')[1].click

    sleep 1

    expect(@driver.find_element(css: '.modal-content').find_elements(css: 'tr').length).to eq(2)

    # Clean up after ourselves so the other tests run ok
    @driver.find_element(css: '.modal-content').find_element(css: '.btn.btn-cancel.btn-default').click
    sleep 1
    @driver.find_element(css: '#resource_instances__0_').find_element(css: '.subrecord-form-remove').click
    sleep 1
    @driver.find_element(css: '.confirm-removal').click

    @driver.find_element(css: "form#resource_form button[type='submit']").click

    run_periodic_index
  end

  it 'can add a rights statement with linked agent to a Resource' do
    @driver.find_element(:link, 'Browse').click
    @driver.wait_for_dropdown
    @driver.click_and_wait_until_gone(:link, 'Resources')
    row = @driver.find_paginated_element(xpath: "//tr[.//*[contains(text(), '#{@resource.title}')]]")
    @driver.click_and_wait_until_element_gone(row.find_element(:link, 'Edit'))

    # add a rights sub record
    @driver.find_element(css: '#resource_rights_statements_ .subrecord-form-heading .btn:not(.show-all)').click

    @driver.find_element(id: 'resource_rights_statements__0__rights_type_').select_option('copyright')
    @driver.find_element(id: 'resource_rights_statements__0__status_').select_option('copyrighted')
    @driver.clear_and_send_keys([:id, 'resource_rights_statements__0__start_date_'], '2012-01-01')
    combo = @driver.find_element(xpath: '//*[@id="resource_rights_statements__0__jurisdiction_"]')
    combo.clear
    combo.click
    combo.send_keys('AU')
    combo.send_keys(:tab)

    # add linked agent
    @driver.find_element(css: '#resource_rights_statements__0__linked_agents_ .subrecord-form-heading .btn:not(.show-all)').click
    combo2 = @driver.find_element(xpath: '//*[@id="token-input-resource_rights_statements__0__linked_agents__0__ref_"]')
    combo2.clear
    combo2.click
    combo2.send_keys('resources')
    @driver.find_element(:css, 'li.token-input-dropdown-item2').click

    # save changes
    @driver.click_and_wait_until_gone(css: "form#resource_form button[type='submit']")
    run_index_round

    expect(@driver.find_element_with_text('//div[contains(@class, "alert-success")]', /\bResource\b.*\bupdated\b/)).not_to be_nil

    # check the show page
    @driver.click_and_wait_until_gone(link: @resource.title)
    expect do
      @driver.find_element(:id, 'resource_rights_statements_')
      @driver.find_element(:css, '#resource_rights_statements_ .accordion-toggle').click
      @driver.find_element(:id, 'rights_statement_0')
      @driver.find_element(:id, 'rights_statement_0_linked_agents')
    end.not_to raise_error
  end

  it 'can create a resource' do
    resource_title = "Pony <emph render='italic'>Express</emph>"
    resource_stripped = 'Pony Express'
    resource_regex = /^.*?\bPony\b.*?$/m

    @driver.find_element(:link, 'Create').click
    @driver.click_and_wait_until_gone(:link, 'Resource')

    @driver.find_hidden_element(:css, '#resource_title_').wait_for_class('initialised')
    @driver.execute_script("$('#resource_title_').data('CodeMirror').setValue('#{resource_title.gsub(/'/, '"')}')")
    @driver.complete_4part_id('resource_id_%d_')

    fa_lang_combo = @driver.find_element(xpath: '//*[@id="resource_finding_aid_language_"]')
    fa_lang_combo.clear
    fa_lang_combo.click
    fa_lang_combo.send_keys('eng')
    fa_lang_combo.send_keys(:tab)

    fa_script_combo = @driver.find_element(xpath: '//*[@id="resource_finding_aid_script_"]')
    fa_script_combo.clear
    fa_script_combo.click
    fa_script_combo.send_keys('Latn')
    fa_script_combo.send_keys(:tab)

    @driver.find_element(id: 'resource_dates__0__date_type_').select_option('single')
    @driver.clear_and_send_keys([:id, 'resource_dates__0__begin_'], '1978')
    @driver.find_element(:id, 'resource_level_').select_option('collection')

    combo = @driver.find_element(xpath: '//*[@id="resource_lang_materials__0__language_and_script__language_"]')
    combo.clear
    combo.click
    combo.send_keys('eng')
    combo.send_keys(:tab)

    @driver.clear_and_send_keys([:id, 'resource_extents__0__number_'], '10')
    @driver.find_element(id: 'resource_extents__0__extent_type_').select_option('cassettes')
    @driver.find_element(css: "form#resource_form button[type='submit']").click

    # The new Resource shows up on the tree
    assert(5) do
      sleep 2
      expect(tree_current.text.strip).to match(resource_regex)
    end
  end

  it 'reports warnings when updating a Resource with invalid data' do
    @driver.get_edit_page(@resource)

    @driver.find_hidden_element(:css, '#resource_title_').wait_for_class('initialised')
    @driver.execute_script("$('#resource_title_').data('CodeMirror').setValue('')")

    sleep(5)
    if @driver.find_element(css: "form#resource_form button[type='submit']").enabled?
      sleep(5)
      @driver.find_elements(css: "form#resource_form button[type='submit']")[1].click
    end

    expect do
      @driver.find_element_with_text('//div[contains(@class, "error")]', /Title - Property is required but was missing/)
    end.not_to raise_error

    @driver.click_and_wait_until_gone(:css, 'a.btn.btn-cancel')
  end

  it 'reports errors if adding an empty child to a Resource' do
    @driver.get_edit_page(@resource)

    @driver.find_element(:link, 'Add Child').click
    @driver.wait_for_ajax
    @driver.find_hidden_element(:css, '#archival_object_title_').wait_for_class('initialised')
    @driver.execute_script("$('#archival_object_title_').data('CodeMirror').setValue('')")
    @driver.wait_for_ajax

    sleep(5) unless @driver.find_element(id: 'createPlusOne')
    # False start: create an object without filling it out
    @driver.find_element(id: 'createPlusOne').click

    @driver.find_element_with_text('//div[contains(@class, "error")]', /Level of Description - Property is required but was missing/)

    # click on another node
    tree_click(tree_node(@resource))

    @driver.click_and_wait_until_gone(:id, 'dismissChangesButton')
  end

  it 'reports error if title is empty and no date is provided' do
    @driver.get("#{$frontend}#{@resource.uri.sub(%r{/repositories/\d+}, '')}/edit")

    @driver.find_element(:link, 'Add Child').click
    @driver.wait_for_ajax
    @driver.find_element(:id, 'archival_object_level_').select_option('item')
    @driver.find_hidden_element(:css, '#archival_object_title_').wait_for_class('initialised')
    @driver.execute_script("$('#archival_object_title_').data('CodeMirror').setValue('')")
    @driver.wait_for_ajax

    # False start: create an object without filling it out
    @driver.find_element(id: 'createPlusOne').click
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Dates - one or more required \(or enter a Title\)/i)

    @driver.find_element_with_text('//div[contains(@class, "error")]', /Title - must not be an empty string \(or enter a Date\)/i)

    tree_click(tree_node(@resource))
    @driver.click_and_wait_until_gone(:id, 'dismissChangesButton')
  end

  it 'can create a new digital object instance with a note to a resource' do
    @driver.get_edit_page(@resource)

    # Wait for the form to load in
    @driver.find_element(css: "form#resource_form button[type='submit']")
    @driver.find_element(css: '#resource_instances_ .subrecord-form-heading .btn[data-instance-type="digital-instance"]').click

    # Wait for the linker to initialise to make sure the dropdown click events are bound
    sleep 1
    @driver.find_hidden_element(css: '#resource_instances__0__digital_object__ref_.initialised')

    elt = @driver.find_element(css: "div[data-id-path='resource_instances__0__digital_object_']")

    elt.find_element(css: 'a.dropdown-toggle').click
    @driver.wait_for_dropdown
    elt.find_element(css: 'a.linker-create-btn').click

    modal = @driver.find_element(css: '#resource_instances__0__digital_object__ref__modal')

    @driver.find_hidden_element(:css, '#digital_object_title_.initialised')
    @driver.execute_script("$('#digital_object_title_').data('CodeMirror').setValue('digital_object_title')")
    modal.clear_and_send_keys([:id, 'digital_object_digital_object_id_'], Digest::MD5.hexdigest(Time.now.to_s))

    @driver.execute_script("$('#digital_object_notes.initialised .subrecord-form-heading .btn.add-note').focus()")
    modal.find_element(css: '#digital_object_notes.initialised .subrecord-form-heading .btn.add-note').click
    modal.find_last_element(css: '#digital_object_notes select.top-level-note-type').select_option_with_text('Summary')

    modal.clear_and_send_keys([:id, 'digital_object_notes__0__label_'], 'Summary label')
    @driver.execute_script("$('#digital_object_notes__0__content__0_').data('CodeMirror').setValue('Summary content')")
    @driver.execute_script("$('#digital_object_notes__0__content__0_').data('CodeMirror').save()")

    @driver.execute_script("$('#digital_object_notes__0__content__0_').data('CodeMirror').toTextArea()")
    expect(@driver.find_element(id: 'digital_object_notes__0__content__0_').attribute('value')).to eq('Summary content')

    modal.find_element(:id, 'createAndLinkButton').click
    @driver.click_and_wait_until_gone(css: "form#resource_form button[type='submit']")

    @driver.find_element(:css, '.token-input-token .digital_object').click

    # so the subject is here now
    assert(5) { expect(@driver.find_element(:css, '.token-input-token .digital_object').text).to match(/digital_object_title/) }
  end


  it 'can have a lot of associated records that do not show in the field but are not lost' do
    subjects = []
    accessions = []
    classifications = []
    dos = []
    instances = []
    agents = []

    10.times do |_i|
      subjects << create(:subject)
      accessions << create(:accession)
      classifications << create(:classification)
      dos << create(:digital_object)
      instances = dos.map { |d| { instance_type: 'digital_object', digital_object: { ref: d.uri } } }
      agents << create(:agent_person)
    end

    linked_agents = agents.map do |a|
      { ref: a.uri,
        role: 'creator',
        relator: generate(:relator),
        title: generate(:alphanumstr) }
    end

    resource = create(:resource,
                      linked_agents: linked_agents,
                      subjects: subjects.map { |s| { ref: s.uri } },
                      related_accessions: accessions.map { |a| { ref: a.uri } },
                      instances: instances,
                      classifications: classifications.map { |c| { ref: c.uri } })

    run_index_round

    # let's go to the edit page
    @driver.get_edit_page(resource)

    # Wait for the form to load in
    @driver.find_element(css: "form#resource_form button[type='submit']")

    # now lets make a small change...
    @driver.find_element(css: '#resource_extents_ .subrecord-form-heading .btn:not(.show-all)').click
    @driver.clear_and_send_keys([:id, 'resource_extents__1__number_'], '5')
    @driver.find_element(id: 'resource_extents__1__extent_type_').select_option('volumes')

    # submit it
    @driver.find_element(css: "form#resource_form button[type='submit']").click

    # no errors!
    expect(@driver.find_element_with_text('//div', /\bResource\b.*\bupdated\b/)).not_to be_nil

    # let's open all all the too-manys and make sure everything is still
    # there..
    @driver.find_elements(css: '.alert-too-many').each { |c| c.click }

    [subjects, accessions, classifications, dos].each do |klass|
      klass.each do |a|
        expect(@driver.find_element(id: a[:uri].gsub('/', '_')).text).to match(/#{ a[:display_title] }/)
      end
    end

    # agents are weird.
    linked_agents.each_with_index do |a, i|
      assert(5) { expect(@driver.find_element(css: "#resource_linked_agents__#{i}__role_").get_select_value).to eq(a[:role]) }
      if a.key?(:title)
        assert(5) { expect(@driver.find_element(css: "#resource_linked_agents__#{i}__title_").attribute('value')).to eq(a[:title]) }
      end
      assert(5) { expect(@driver.find_input_by_name("resource[linked_agents][#{i}][relator]").attribute('value')).to eq(a[:relator]) }
      assert(5) { expect(@driver.find_element(css: "#resource_linked_agents__#{i}_ .linker-wrapper .token-input-token").text).to match(/#{ agents[i][:primary_name] }/) }
    end

    # Delete the resource
    @driver.find_element(:css, '.delete-record.btn').click
    @driver.click_and_wait_until_gone(:css, '#confirmChangesModal #confirmButton')
  end

  it 'can edit a Resource, add a second Extent, then remove it' do
    @driver.get_edit_page(@resource)

    @driver.find_element(css: '#resource_extents_ .subrecord-form-heading .btn:not(.show-all)').click

    @driver.clear_and_send_keys([:id, 'resource_extents__1__number_'], '5')
    @driver.find_element(id: 'resource_extents__1__extent_type_').select_option('volumes')

    @driver.find_element(css: "form#resource_form button[type='submit']").click

    expect(@driver.find_element_with_text('//div', /\bResource\b.*\bupdated\b/)).not_to be_nil

    @driver.find_element(:link, 'Close Record').click

    # it can see two Extents on the saved Resource
    extent_headings = @driver.blocking_find_elements(css: '#resource_extents_ .panel-heading')

    expect(extent_headings.length).to eq 2
    assert(5) { expect(extent_headings[0].text).to match /^\d.*/ }
    assert(5) { expect(extent_headings[1].text).to match /^\d.*/ }

    # it can remove an Extent when editing a Resource
    @driver.get("#{$frontend}#{@resource.uri.sub(%r{/repositories/\d+}, '')}/edit")

    @driver.blocking_find_elements(css: '#resource_extents_ .subrecord-form-remove')[1].click
    @driver.find_element(css: '#resource_extents_ .confirm-removal').click
    @driver.find_element(css: "form#resource_form button[type='submit']").click

    @driver.find_element(:link, 'Close Record').click

    extent_headings = @driver.blocking_find_elements(css: '#resource_extents_ .panel-heading')

    expect(extent_headings.length).to eq 1
    assert(5) { expect(extent_headings[0].text).to match /^\d.*/ }
  end

  # Archival Object Trees
  it 'can populate the archival object tree' do
    @driver.get_edit_page(@resource)

    @driver.find_element(:link, 'Add Child').click

    @driver.find_hidden_element(:css, '#archival_object_title_').wait_for_class('initialised')
    @driver.execute_script("$('#archival_object_title_').data('CodeMirror').setValue('Lost mail')")
    @driver.find_element(:id, 'archival_object_level_').select_option('item')

    @driver.click_and_wait_until_gone(id: 'createPlusOne')

    %w[January February December].each do |month|
      sleep 5
      @driver.find_hidden_element(:css, '#archival_object_title_').wait_for_class('initialised')
      @driver.execute_script("$('#archival_object_title_').data('CodeMirror').setValue('#{month}')")
      @driver.find_element(:id, 'archival_object_level_').select_option('item')
      @driver.click_and_wait_until_gone(id: 'createPlusOne')
    end

    elements = tree_nodes_at_level(1).map { |li| li.text.strip }

    %w[January February December].each do |month|
      expect(elements.any? { |elt| elt =~ /#{month}/ }).to be_truthy
    end

    @driver.click_and_wait_until_gone(:css, 'a.btn.btn-cancel')
  end

  it 'can cancel edits to Archival Objects' do
    ao_id = @archival_object.uri.sub(%r{.*/}, '')
    @driver.get("#{$frontend}#{@resource.uri.sub(%r{/repositories/\d+}, '')}/edit#tree::archival_object_#{ao_id}")

    # sanity check..
    tree_click(tree_node(@archival_object))
    pane_resize_handle = @driver.find_element(css: '.ui-resizable-handle.ui-resizable-s')

    @driver.clear_and_send_keys([:id, 'archival_object_component_id_'], 'unimportant change')

    tree_click(tree_node(@resource))
    @driver.click_and_wait_until_gone(:id, 'dismissChangesButton')
  end

  it 'reports warnings when updating an Archival Object with invalid data' do
    ao_id = @archival_object.uri.sub(%r{.*/}, '')
    @driver.get("#{$frontend}#{@resource.uri.sub(%r{/repositories/\d+}, '')}/edit#tree::archival_object_#{ao_id}")

    # Wait for the form to load in
    @driver.find_element(css: "form#archival_object_form button[type='submit']")

    @driver.find_element(:id, 'archival_object_level_').select_option('item')
    @driver.find_hidden_element(:css, '#archival_object_title_').wait_for_class('initialised')
    @driver.execute_script("$('#archival_object_title_').data('CodeMirror').setValue('')")
    @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

    expect do
      @driver.find_element_with_text('//div[contains(@class, "error")]', /Title - must not be an empty string/)
    end.not_to raise_error
    tree_click(tree_node(@resource))
    @driver.click_and_wait_until_gone(:id, 'dismissChangesButton')
  end

  it 'can update an existing Archival Object' do
    @driver.get_edit_page(@archival_object)

    # Wait for the form to load in
    @driver.find_element(css: "form#archival_object_form button[type='submit']")

    @driver.find_hidden_element(:css, '#archival_object_title_').wait_for_class('initialised')
    @driver.execute_script("$('#archival_object_title_').data('CodeMirror').setValue('save this please')")
    @driver.find_element(css: "form .record-pane button[type='submit']").click
    @driver.wait_for_ajax
    assert(5) { expect(@driver.find_element(:css, 'h2').text).to eq('save this please Archival Object') }
    assert(5) { expect(@driver.find_element(css: 'div.alert.alert-success').text).to eq('Archival Object save this please updated') }
    @driver.find_hidden_element(:css, '#archival_object_title_').wait_for_class('initialised')
    @driver.execute_script("$('#archival_object_title_').data('CodeMirror').setValue('#{@archival_object.title}')")
    @driver.click_and_wait_until_gone(css: "form .save-changes button[type='submit']")
  end

  it 'can add a assign, remove, and reassign a Subject to an archival object' do
    @driver.get_edit_page(@archival_object)

    @driver.find_element(css: '#archival_object_subjects_ .subrecord-form-heading .btn:not(.show-all)').click
    sleep(10)

    @driver.find_element(css: '#archival_object_subjects_ .linker-wrapper a.btn').click

    @driver.find_element(css: '#archival_object_subjects_ a.linker-create-btn').click

    @driver.find_element(:css, '.modal #subject_terms_ .btn:not(.show-all)').click

    @driver.clear_and_send_keys([id: 'subject_terms__0__term_'], "#{$$}TestTerm123")
    @driver.find_element(id: 'subject_terms__0__term_type_').select_option('cultural_context')
    @driver.clear_and_send_keys([id: 'subject_terms__1__term_'], "#{$$}FooTerm456")
    @driver.find_element(id: 'subject_terms__1__term_type_').select_option('cultural_context')
    @driver.find_element(id: 'subject_source_').select_option('local')

    @driver.find_element(:id, 'createAndLinkButton').click

    # remove the linked Subject but find it using typeahead and re-add it" do
    @driver.find_element(:css, '.token-input-delete-token').click

    # search for the created subject
    assert(5) do
      run_index_round
      @driver.clear_and_send_keys([:id, 'token-input-archival_object_subjects__0__ref_'], "#{$$}TestTerm123")
      @driver.find_element(:css, 'li.token-input-dropdown-item2').click
    end

    @driver.click_and_wait_until_gone(:css, "form#archival_object_form button[type='submit']")

    # so the subject is here now
    assert(5) { expect(@driver.find_element(:css, '#archival_object_subjects_ ul.token-input-list').text).to match(/#{$$}FooTerm456/) }
  end

  it 'can view a read only Archival Object' do
    @driver.get_edit_page(@archival_object)

    @driver.find_element(:link, 'Close Record').click

    assert(5) { expect(@driver.find_element(:css, '.record-pane h2').text).to eq("#{@archival_object.title} Archival Object") }
  end

  xit 'exports and downloads the resource to xml' do
    @driver.get_view_page(@resource)

    @driver.find_element(:link, 'Export').click
    response = @driver.find_element(:link, 'Download EAD').click
    @driver.wait_for_ajax
    assert(10) { expect(Dir.glob(File.join(Dir.tmpdir, '*_ead.xml')).length).to eq(1) }
    system("rm -f #{File.join(Dir.tmpdir, '*_ead.xml')}")
  end

  # # this is a pretty weak test, but pdf functionality has been move down to
  # jobs, where it's tested..
  it 'displays a link for downloading pdf' do
    @driver.get("#{$frontend}#{@resource.uri.sub(%r{/repositories/\d+}, '')}")

    @driver.find_element(:link, 'Export').click
    expect do
      @driver.find_element_with_text(:link, /Print Resource to PDF/)
    end
  end

  it 'shows component id in browse view for archival objects' do
    @driver.find_element(:link, 'Browse').click
    @driver.wait_for_dropdown
    @driver.click_and_wait_until_gone(:link, 'Resources')
    @driver.find_element(:link, 'Show Components').click
    expect do
      @driver.find_element_with_text('//td', /#{@archival_object.component_id}/)
      @driver.find_element_with_text('//th', /Identifier/)
    end.not_to raise_error
    expect do
      @driver.find_element_with_text('//th', /Component ID/, false, true)
    end.to raise_error(Selenium::WebDriver::Error::NoSuchElementError)
  end

  it 'shows component id for search and filter to archival objects' do
    @driver.find_element(:id, 'global-search-button').click
    @driver.find_element(:link, 'Archival Object').click
    expect do
      @driver.find_element_with_text('//td', /#{@archival_object.component_id}/)
      @driver.find_element_with_text('//th', /Component ID/)
    end.not_to raise_error
    expect do
      @driver.find_element_with_text('//th', /Identifier/, false, true)
    end.to raise_error(Selenium::WebDriver::Error::NoSuchElementError)
  end

  it 'allows for publication and unpublication of all or part of the record tree' do
    @driver.get_edit_page(@resource)

    # the resource was created without specifying publish, so it should be unpublished
    expect(@driver.find_element(id: 'resource_publish_').attribute('checked')).to be_nil

    # click the publish all button
    @driver.find_element_with_text('//button', /Publish All/).click
    sleep(5)
    @driver.find_element(id: 'confirmButton').click
    sleep(10)
    expect(@driver.find_element(id: 'resource_publish_').attribute('checked')).not_to be_nil

    # confirm that the archival object is also published
    @driver.get_edit_page(@archival_object)
    expect(@driver.find_element(id: 'archival_object_publish_').attribute('checked')).not_to be_nil

    # unpublish the archival object
    @driver.find_element_with_text('//button', /Unpublish All/).click
    sleep(5)
    @driver.find_element(id: 'confirmButton').click
    sleep(10)
    expect(@driver.find_element(id: 'archival_object_publish_').attribute('checked')).to be_nil

    # confirm that this hasn't unpublished the resource
    @driver.get_edit_page(@resource)
    expect(@driver.find_element(id: 'resource_publish_').attribute('checked')).not_to be_nil

    # now unpublish all from the resource
    @driver.find_element_with_text('//button', /Unpublish All/).click
    sleep(5)
    @driver.find_element(id: 'confirmButton').click
    sleep(10)
    expect(@driver.find_element(id: 'resource_publish_').attribute('checked')).to be_nil

    # confirm that the archival object is still unpublished
    @driver.get_edit_page(@archival_object)
    expect(@driver.find_element(id: 'archival_object_publish_').attribute('checked')).to be_nil

    # publish the archival object
    @driver.find_element_with_text('//button', /Publish All/).click
    sleep(5)
    @driver.find_element(id: 'confirmButton').click
    sleep(10)
    expect(@driver.find_element(id: 'archival_object_publish_').attribute('checked')).not_to be_nil

    # confirm that this hasn't published the resource
    @driver.get_edit_page(@resource)
    expect(@driver.find_element(id: 'resource_publish_').attribute('checked')).to be_nil

    # finally, unpublish all to tidy up
    @driver.find_element_with_text('//button', /Unpublish All/).click
    sleep(5)
    @driver.find_element(id: 'confirmButton').click
    sleep(10)
    expect(@driver.find_element(id: 'resource_publish_').attribute('checked')).to be_nil
  end

  it 'can apply and remove filters when browsing for linked agents in the linker modal' do
    person = create(:agent_person)
    corp = create(:agent_corporate_entity)

    run_all_indexers
    @driver.get_edit_page(@resource)

    @driver.find_element(:link, "Agent Links").click
    @driver.find_element(:css, "#resource_linked_agents_ button").click
    @driver.find_element(:css, "#resource_linked_agents_ .linker-wrapper .input-group-btn a").click
    @driver.find_element(:css, "#resource_linked_agents_ .linker-browse-btn").click
    @driver.wait_for_ajax
    expect(@driver.find_element(:css, ".linker-container").text).to match(/Filter by/)
    @driver.find_element(:css, ".linker-container").find_element(:link, "Corporate Entity").click
    @driver.wait_for_ajax
    expect(@driver.find_element(:css, ".linker-container").text).to match(/Filtered By/)
    expect(@driver.is_visible?(:css, ".linker-container .glyphicon-remove")).to be_truthy
    @driver.find_element(:css, ".linker-container").find_element(:css, ".glyphicon-remove").click
    @driver.wait_for_ajax
    expect(@driver.is_visible?(:css, ".linker-container .glyphicon-remove")).to be_falsey
  end

  it 'adds the result for calculate extent to the correct subrecord' do
    @driver.get_edit_page(@resource)

    @driver.find_element(css: '#resource_deaccessions_ .subrecord-form-heading .btn:not(.show-all)').click

    expect(@driver.find_element(id: 'resource_deaccessions__0__date__label_').get_select_value).to eq('deaccession')

    @driver.clear_and_send_keys([:id, 'resource_deaccessions__0__description_'], 'Lalala describing the deaccession')
    @driver.find_element(css: '#resource_deaccessions__0__date__date_type_').select_option('single')
    @driver.clear_and_send_keys([:id, 'resource_deaccessions__0__date__begin_'], '2012-05-14')

    @driver.find_element(css: '#resource_deaccessions__0__extents_ .subrecord-form-heading .btn:not(.show-all)').click

    @driver.clear_and_send_keys([:id, 'resource_deaccessions__0__extents__0__number_'], '4')
    @driver.find_element(id: 'resource_deaccessions__0__extents__0__extent_type_').select_option('cassettes')

    @driver.find_element(css: "form#resource_form button[type='submit']").click

    @driver.find_element(id: 'other-dropdown').click
    @driver.wait_for_dropdown

    @driver.find_element(:link, 'Calculate Extent').click
    sleep 1

    @driver.find_element(id: 'extent_portion_').select_option('whole')
    @driver.find_element(id: 'extent_number_').send_keys('1')
    @driver.find_element(id: 'extent_extent_type_').select_option('linear_feet')

    @driver.find_element(:link, 'Create Extent').click
    sleep 1

    @driver.find_element(xpath: '//section[@id="resource_extents_"]//li[@data-index="1"]')

  end

  it 'enforces required fields in extent calculator' do
    @driver.get_edit_page(@resource)

    @driver.find_element(id: 'other-dropdown').click
    @driver.wait_for_dropdown

    @driver.find_element(:link, 'Calculate Extent').click
    sleep 1

    @driver.find_element(id: 'extent_number_').clear

    @driver.find_element(:link, 'Create Extent').click
    sleep 1

    expect { @driver.switch_to.alert }.not_to raise_error

    #make sure to close it so as not to interfere with other tests
    @driver.switch_to.alert.accept
  end

end
