# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Notes', js: true do
  before(:all) do
    now = Time.now.to_i
    @repository = create(:repo, repo_code: "notes_test_#{now}")

    set_repo @repository

    @archivist_user = create_user(@repository => ['repository-archivists'])
  end

  before(:each) do
    login_user(@archivist_user)

    ensure_repository_access

    select_repository(@repository)
  end

  it 'can attach notes to resources and confirms before removing a note entry' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    run_index_round

    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    find('button', text: 'Add Note', match: :first).click
    element = find('#resource_notes_ [data-index="0"] select.form-control.top-level-note-type')
    element.select 'Accruals'

    find('button', text: 'Add Note', match: :first).click
    element = find('#resource_notes_ [data-index="1"] select.form-control.top-level-note-type')
    element.select 'Accruals'

    find('button', text: 'Add Note', match: :first).click
    element = find('#resource_notes_ [data-index="2"] select.form-control.top-level-note-type')
    element.select 'Accruals'

    elements = all('#resource_notes_ > .subrecord-form-container > .subrecord-form-list > li')
    expect(elements.length).to eq 3

    elements[1].find('.subrecord-form-remove').click
    click_on 'Confirm Removal'

    elements[0].find('.subrecord-form-remove').click
    click_on 'Confirm Removal'

    fill_in 'resource_notes__2__label_', with: "Multipart Note #{now}"
    page.execute_script("$('#resource_notes__2__subnotes__0__content_').data('CodeMirror').setValue('Multipart Note Content #{now}')")
    page.execute_script("$('#resource_notes__2__subnotes__0__content_').data('CodeMirror').save()")

    find('button', text: 'Save Resource', match: :first).click

    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Resource Resource Title #{now} updated"
  end

  it 'can edit an existing resource note to add subparts after saving' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    run_index_round

    visit "resources/#{resource.id}/edit"
    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    find('button', text: 'Add Note', match: :first).click
    element = find('#resource_notes_ [data-index="0"] select.form-control.top-level-note-type')
    element.select 'Accruals'
    fill_in 'resource_notes__0__label_', with: "Multipart Note #{now}"
    page.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').setValue('Multipart Note Content #{now}')")
    page.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').save()")

    # Click on save
    find('button', text: 'Save Resource', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Resource Resource Title #{now} updated"

    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    notes = all('#resource_notes_ .subrecord-form-fields')
    expect(notes.length).to eq 1
    note = notes[0]
    note.find('.collapse-subrecord-toggle').click

    within note do
      click_on 'Add Sub Note'
    end
    element = find('#resource_notes_ .sort-enabled.initialised[data-index="1"] select.form-control.multipart-note-type')
    element.select 'Chronology'
    element = find('#resource_notes__0__subnotes__1__title_')
    element.fill_in with: 'Chronology Title'

    within note do
      click_on 'Add Sub Note'
    end
    element = find('#resource_notes_ .sort-enabled.initialised[data-index="2"] select.form-control.multipart-note-type')
    element.select 'Defined List'
    element = find('#resource_notes__0__subnotes__2__title_')
    element.fill_in with: 'Defined List'

    within note do
      click_on 'Add Item'
      click_on 'Add Item'
    end

    fill_in 'resource_notes__0__subnotes__2__items__0__label_', with: "Resource Subnote Item Label 1 #{now}"
    fill_in 'resource_notes__0__subnotes__2__items__0__value_', with: "Resource Subnote Item Value 1 #{now}"
    fill_in 'resource_notes__0__subnotes__2__items__1__label_', with: "Resource Subnote Item Label 2 #{now}"
    fill_in 'resource_notes__0__subnotes__2__items__1__value_', with: "Resource Subnote Item Value 2 #{now}"

    # Click on save
    find('button', text: 'Save Resource', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Resource Resource Title #{now} updated"
  end

  it 'can create an ordered list subnote and list items maintain proper order' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    run_index_round

    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    find('button', text: 'Add Note', match: :first).click
    element = find('#resource_notes_ [data-index="0"] select.form-control.top-level-note-type')
    element.select 'Accruals'
    fill_in 'resource_notes__0__label_', with: "Multipart Note #{now}"
    page.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').setValue('Multipart Note Content #{now}')")
    page.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').save()")
    page.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').toTextArea()")

    notes = all('#resource_notes_ .subrecord-form-fields')
    note = notes[0]

    within note do
      click_on 'Add Sub Note'
    end

    element = find('#resource_notes_ .sort-enabled.initialised[data-index="1"] select.form-control.multipart-note-type')
    element.select 'Ordered List'
    element = find('#resource_notes__0__subnotes__1__title_')
    element.fill_in with: "Ordered List Title #{now}"

    within note do
      click_on 'Add Item'
      click_on 'Add Item'
      click_on 'Add Item'
      click_on 'Add Item'
    end
    find('#resource_notes__0__subnotes__1__items__0_').fill_in with: "Item 1 #{now}"
    find('#resource_notes__0__subnotes__1__items__1_').fill_in with: "Item 2 #{now}"
    find('#resource_notes__0__subnotes__1__items__2_').fill_in with: "Item 3 #{now}"
    find('#resource_notes__0__subnotes__1__items__3_').fill_in with: "Item 4 #{now}"

    # Click on save
    find('button', text: 'Save Resource', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Resource Resource Title #{now} updated"

    find('#resource_notes_ #resource_notes__0_ .collapse-subrecord-toggle').click

    expect(find('input#resource_notes__0__subnotes__1__items__0_').value).to eq "Item 1 #{now}"
    expect(find('input#resource_notes__0__subnotes__1__items__1_').value).to eq "Item 2 #{now}"
    expect(find('input#resource_notes__0__subnotes__1__items__2_').value).to eq "Item 3 #{now}"
    expect(find('input#resource_notes__0__subnotes__1__items__3_').value).to eq "Item 4 #{now}"

    notes = all('#resource_notes_ .subrecord-form-fields')
    note = notes[0]
    within note do
      click_on 'Add Item'
      click_on 'Add Item'
    end
    find('#resource_notes__0__subnotes__1__items__4_').fill_in with: "Item 5 #{now}"
    find('#resource_notes__0__subnotes__1__items__5_').fill_in with: "Item 6 #{now}"

    # Click on save
    find('button', text: 'Save Resource', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Resource Resource Title #{now} updated"

    wait_for_ajax

    find('#resource_notes_ #resource_notes__0_ .collapse-subrecord-toggle').click

    expect(find('input#resource_notes__0__subnotes__1__items__0_').value).to eq "Item 1 #{now}"
    expect(find('input#resource_notes__0__subnotes__1__items__1_').value).to eq "Item 2 #{now}"
    expect(find('input#resource_notes__0__subnotes__1__items__2_').value).to eq "Item 3 #{now}"
    expect(find('input#resource_notes__0__subnotes__1__items__3_').value).to eq "Item 4 #{now}"
    expect(find('input#resource_notes__0__subnotes__1__items__4_').value).to eq "Item 5 #{now}"
    expect(find('input#resource_notes__0__subnotes__1__items__5_').value).to eq "Item 6 #{now}"

  end

  it 'can add a top-level bibliography too' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    run_index_round

    visit "resources/#{resource.id}/edit"
    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    find('button', text: 'Add Note', match: :first).click
    element = find('#resource_notes_ [data-index="0"] select.form-control.top-level-note-type')
    element.select 'Bibliography'
    fill_in 'resource_notes__0__label_', with: "Top-level Bibliography Label #{now}"

    page.execute_script("$('#resource_notes__0__content__0_').data('CodeMirror').setValue('Top-level Bibliography Content #{now}')")
    page.execute_script("$('#resource_notes__0__content__0_').data('CodeMirror').save()")
    page.execute_script("$('#resource_notes__0__content__0_').data('CodeMirror').toTextArea()")
    expect(find('#resource_notes__0__content__0_').value).to eq "Top-level Bibliography Content #{now}"

    notes = all('#resource_notes_ .subrecord-form-fields')
    note = notes[0]
    within note do
      click_on 'Add Item'
      click_on 'Add Item'
    end

    fill_in 'resource_notes__0__items__0_', with: "Top-level bibliography item 1 #{now}"
    fill_in 'resource_notes__0__items__1_', with: "Top-level bibliography item 2 #{now}"

    # Click on save
    find('button', text: 'Save Resource', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Resource Resource Title #{now} updated"

    find('#resource_notes_ #resource_notes__0_ .collapse-subrecord-toggle').click
    expect(find('#resource_notes__0__label_').value).to eq "Top-level Bibliography Label #{now}"
    expect(find('#resource_notes__0__content__0_ .CodeMirror').text).to include "Top-level Bibliography Content #{now}"
    expect(find('input#resource_notes__0__items__0_').value).to eq "Top-level bibliography item 1 #{now}"
    expect(find('input#resource_notes__0__items__1_').value).to eq "Top-level bibliography item 2 #{now}"
  end

  it 'can wrap note content text with EAD mark up' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    run_index_round

    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    find('button', text: 'Add Note', match: :first).click
    element = find('#resource_notes_ [data-index="0"] select.form-control.top-level-note-type')
    element.select 'Accruals'
    fill_in 'resource_notes__0__label_', with: "Multipart Note #{now}"
    page.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').setValue('Multipart Note Content #{now}')")
    page.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').save()")
    page.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').toTextArea()")

    notes = all('#resource_notes_ .subrecord-form-fields')
    note = notes[0]

    within note do
      click_on 'Add Sub Note'
    end

    element = find('#resource_notes_ .sort-enabled.initialised[data-index="1"] select.form-control.multipart-note-type')
    element.select 'Ordered List'
    element = find('#resource_notes__0__subnotes__1__title_')
    element.fill_in with: "Ordered List Title #{now}"

    # Click on save
    find('button', text: 'Save Resource', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Resource Resource Title #{now} updated"

    find('#resource_notes_ #resource_notes__0_ .collapse-subrecord-toggle').click

    page.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').setValue('Wrapped content')")
    page.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').setSelection({line: 0, ch: 0}, {line: 0, ch: 7})")

    element = find('select.mixed-content-wrap-action', visible: true)
    element.select 'blockquote'

    page.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').save()")
    page.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').toTextArea()")

    expect(find('#resource_notes__0__subnotes__0__content_').value).to eq '<blockquote>Wrapped</blockquote> content'

    # Click on save
    find('button', text: 'Save Resource', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Resource Resource Title #{now} updated"
  end

  it 'can add a deaccession record' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    run_index_round

    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    click_on 'Add Deaccession'

    select 'Deaccession', from: 'resource_deaccessions__0__date__label_'
    fill_in 'resource_deaccessions__0__description_', with: "Deaccession Description #{now}"
    select 'Single', from: 'resource_deaccessions__0__date__date_type_'
    fill_in 'resource_deaccessions__0__date__begin_', with: '2012-05-14'

    # Click on save
    find('button', text: 'Save Resource', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Resource Resource Title #{now} updated"

    click_on 'Close Record'

    elements = all('#resource_deaccessions_ .accordion.details')
    expect(elements.length).to eq 1
  end

  it 'types for rights statements are correct' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    run_index_round

    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    click_on 'Add Rights Statement'

    within '#rights_statement_notes' do
      click_on 'Add Note'
    end

    # Ensure option values are only note_rights_statement
    elements = all('#rights_statement_notes .top-level-note-type option')
    option_values = elements.map { |element| element.value if element.value.present? }.compact.uniq
    expect(option_values.length).to eq 1
    expect(option_values[0]).to eq 'note_rights_statement'

    element = find('#rights_statement_notes .top-level-note-type')
    element.select 'Additional Information'

    expect(find('#resource_rights_statements__0__notes__0__type_').value).to eq 'additional_information'

    click_on 'Add Act'

    within '#resource_rights_statements__0__acts_' do
      click_on 'Add Note'
    end

    # Ensure option values are only note_rights_statement_act
    elements = all('#resource_rights_statements__0__acts_ .top-level-note-type option')
    option_values = elements.map { |element| element.value if element.value.present? }.compact.uniq
    expect(option_values.length).to eq 1
    expect(option_values[0]).to eq 'note_rights_statement_act'

    element = find('#resource_rights_statements__0__acts_ .top-level-note-type')
    element.select 'Additional Information'
    expect(find('#resource_rights_statements__0__acts__0__notes__0__type_').value).to eq 'additional_information'

    # Click on save
    find('button', text: 'Save Resource', match: :first).click
    element = find('.alert.alert-danger.with-hide-alert')
    expect(element.text).to eq "Content - At least 1 item(s) is required\nAct Type - Property is required but was missing\nRestriction - Property is required but was missing\nStart Date - Property is required but was missing\nContent - At least 1 item(s) is required\nRights Type - Property is required but was missing"

    expect(find('#resource_rights_statements__0__notes__0__type_').value).to eq 'additional_information'
    expect(find('#resource_rights_statements__0__acts__0__notes__0__type_').value).to eq 'additional_information'

    find('#rights_statement_notes .add-note').click

    # Ensure option values are only note_rights_statement
    elements = all('#rights_statement_notes .top-level-note-type option')
    option_values = elements.map { |element| element.value if element.value.present? }.compact.uniq
    expect(option_values.length).to eq 1
    expect(option_values[0]).to eq 'note_rights_statement'

    element = find('#rights_statement_notes .top-level-note-type')
    element.select 'Additional Information'
    expect(find('#resource_rights_statements__0__notes__1__type_').value).to eq 'additional_information'

    find('#rights_statement_act_notes.initialised .add-note').click

    # Ensure option values are only note_rights_statement_act
    elements = all('#resource_rights_statements__0__acts_ .top-level-note-type option')
    option_values = elements.map { |element| element.value if element.value.present? }.compact.uniq
    expect(option_values.length).to eq 1
    expect(option_values[0]).to eq 'note_rights_statement_act'

    element = find('#resource_rights_statements__0__acts_ .top-level-note-type')
    element.select 'Additional Information'
    expect(find('#resource_rights_statements__0__acts__0__notes__0__type_').value).to eq 'additional_information'
  end

  it 'can attach notes to archival objects' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Resource'

    fill_in 'resource_title_', with: "Resource Title #{now}"
    fill_in 'resource_id_0_', with: "1 #{now}"
    fill_in 'resource_id_1_', with: "2 #{now}"
    fill_in 'resource_id_2_', with: "3 #{now}"
    fill_in 'resource_id_3_', with: "4 #{now}"
    select 'Collection', from: 'resource_level_'

    element = find('#resource_lang_materials__0__language_and_script__language_')
    element.click
    element.fill_in with: 'Eng'
    element.send_keys(:tab)

    fill_in 'resource_extents__0__number_', with: '10'
    select 'Cassettes', from: 'resource_extents__0__extent_type_'
    select 'Single', from: 'resource_dates__0__date_type_'
    fill_in 'resource_dates__0__begin_', with: '1978'

    element = find('#resource_finding_aid_language_')
    element.click
    element.fill_in with: 'Eng'
    element.send_keys(:tab)

    element = find('#resource_finding_aid_script_')
    element.click
    element.fill_in with: 'Latin'
    element.send_keys(:tab)

    # Click on save
    find('button', text: 'Save Resource', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Resource Resource Title #{now} created"

    click_on 'Add Child'

    fill_in 'archival_object_title_', with: "Archival Object Title #{now}"
    select 'Item', from: 'archival_object_level_'

    element = find('#notes .add-note')
    3.times do
      element.click
    end

    element = find('#notes [data-index="0"] select.form-control.top-level-note-type')
    element.select 'Accruals'

    element = find('#notes [data-index="1"] select.form-control.top-level-note-type')
    element.select 'Accruals'

    element = find('#notes [data-index="2"] select.form-control.top-level-note-type')
    element.select 'Accruals'

    elements = all('#notes > .subrecord-form-container > .subrecord-form-list > li')
    expect(elements.length).to eq 3
  end

  it 'can attach special notes to digital objects' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Digital Object'
    fill_in 'digital_object_title_', with: "Resource Title #{now}"
    fill_in 'digital_object_digital_object_id_', with: "Identifier #{now}"

    using_wait_time(15) do
      within '#digital_object_notes_' do
        click_on 'Add Note'
      end
    end

    element = find('#digital_object_notes_ select.top-level-note-type')
    element.select 'Summary'
    fill_in 'digital_object_notes__0__label_', with: "Summary Label #{now}"
    page.execute_script("$('#digital_object_notes__0__content__0_').data('CodeMirror').setValue('Summary Content #{now}')")
    page.execute_script("$('#digital_object_notes__0__content__0_').data('CodeMirror').save()")
    page.execute_script("$('#digital_object_notes__0__content__0_').data('CodeMirror').toTextArea()")
    expect(find('#digital_object_notes__0__content__0_').value).to eq "Summary Content #{now}"

    # Click on save
    find('button', text: 'Save Digital Object', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Digital Object Resource Title #{now} Created"

    expect(find('#digital_object_title_').value).to eq "Resource Title #{now}"

    find('#digital_object_notes_ .collapse-subrecord-toggle').click

    element = find('#digital_object_notes__0__content__0_')
    element.text
    expect(element.text).to include "Content\nSummary Content #{now}"
  end

  it 'shows a validation error when note content is empty' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    run_index_round

    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    find('#resource_notes_ > div .add-note').click

    element = find('#resource_notes_ select.top-level-note-type')
    element.select 'Abstract'

    # Click on save
    find('button', text: 'Save Resource', match: :first).click
    element = find('.alert.alert-danger.with-hide-alert')
    expect(element.text).to eq 'Content - At least 1 item(s) is required'
  end
end
