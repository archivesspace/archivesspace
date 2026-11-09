# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Suppressed controlled values', js: true do
  def add_enumeration_value(enumeration_name, value)
    enumeration = JSONModel(:enumeration).all.find { |e| e.name == enumeration_name }
    enumeration.values += [value]
    enumeration.save
    MemoryLeak::Resources.refresh(:enumerations)

    JSONModel(:enumeration).find(enumeration.id).enumeration_values.find { |v| v['value'] == value }
  end

  def cleanup_enumeration_value(enumeration_name, enumeration_value)
    JSONModel(:enumeration_value).find(enumeration_value['id']).set_suppressed(false)
    enumeration = JSONModel(:enumeration).all.find { |e| e.name == enumeration_name }
    enumeration.values -= [enumeration_value['value']]
    enumeration.save
  end

  before(:all) do
    now = Time.now.to_i
    @repository = create(:repo, repo_code: "suppressed_values_test_#{now}")
    set_repo(@repository)

    @date_label = "suppressed_label_#{now}"
    @restriction_type = "suppressed_restriction_#{now}"
    @subject_source = "suppressed_source_#{now}"
    @name_source = "suppressed_name_source_#{now}"
    @enumeration_values = {
      'date_label' => add_enumeration_value('date_label', @date_label),
      'restriction_type' => add_enumeration_value('restriction_type', @restriction_type),
      'subject_source' => add_enumeration_value('subject_source', @subject_source),
      'name_source' => add_enumeration_value('name_source', @name_source)
    }

    @resource = create(:resource,
                       dates: [build(:date, label: @date_label)],
                       notes: [{
                         'jsonmodel_type' => 'note_multipart',
                         'type' => 'accessrestrict',
                         'subnotes' => [{ 'jsonmodel_type' => 'note_text', 'content' => 'Restricted' }],
                         'rights_restriction' => { 'local_access_restriction_type' => [@restriction_type] }
                       }])
    @subject = create(:subject, source: @subject_source)
    @merge_destination = create(:agent_person, names: [build(:name_person, source: @name_source)])
    @merge_candidate = create(:agent_person)

    @enumeration_values.each_value { |v| JSONModel(:enumeration_value).find(v['id']).set_suppressed(true) }
    MemoryLeak::Resources.refresh(:enumerations)

    admin_session = JSONModel::HTTP.current_backend_session
    run_index_round
    JSONModel::HTTP.current_backend_session = admin_session
  end

  after(:all) do
    @resource.delete
    @subject.delete
    @merge_destination.delete
    @enumeration_values.each { |enumeration_name, value| cleanup_enumeration_value(enumeration_name, value) }
    MemoryLeak::Resources.refresh(:enumerations)
  end

  before(:each) do
    login_admin_and_select_repository(@repository)
  end

  it 'shows them as selected on an edit form, saves them unchanged and warns' do
    visit "/resources/#{@resource.id}/edit"

    expect(page).to have_select('resource_dates__0__label_', selected: "#{@date_label} (suppressed)")
    expect(page).to have_select('resource_notes__0__rights_restriction__local_access_restriction_type_',
                                selected: ["#{@restriction_type} (suppressed)"], visible: :all)

    find('button', text: 'Save Resource', match: :first).click

    expect(page).to have_text "Resource #{@resource.title} updated"
    expect(page).to have_css('.alert-warning', text: 'This record was saved with suppressed controlled values')
    expect(page).to have_css('.alert-warning', text: "Date Label: #{@date_label}")
    expect(page).to have_css('.alert-warning', text: "Local Access Restriction Type: #{@restriction_type}")

    saved = JSONModel(:resource).find(@resource.id)
    expect(saved.dates.first['label']).to eq(@date_label)
    expect(saved.notes.first['rights_restriction']['local_access_restriction_type']).to eq([@restriction_type])
  end

  it 'keeps the warning across the redirect after saving' do
    visit "/subjects/#{@subject.id}/edit"

    expect(page).to have_select('subject_source_', selected: "#{@subject_source} (suppressed)")

    find('button', text: 'Save', match: :first).click

    expect(page).to have_text 'Subject Saved'
    expect(page).to have_css('.alert-warning', text: "Subject Source: #{@subject_source}")
    expect(JSONModel(:subject).find(@subject.id).source).to eq(@subject_source)

    visit "/subjects/#{@subject.id}"
    expect(page).to have_text("#{@subject_source} (suppressed)")
  end

  it 'keeps them when merging agents' do
    visit "/agents/agent_person/#{@merge_destination.id}/edit"
    click_on 'Merge'
    find('#token-input-merge_ref_').fill_in with: @merge_candidate.names.first['primary_name']
    find('li.token-input-dropdown-item2', match: :first).click
    find('.merge-button').click
    within('#confirmChangesModal') { click_on 'Compare Agents' }

    find('.preview-merge', match: :first).click
    within('#mergePreviewModal') { expect(page).to have_text(@merge_destination.names.first['primary_name']) }
    page.execute_script("$('#mergePreviewModal').modal('hide')")

    find('button.do-merge', text: 'Merge', match: :first).click

    expect(page).to have_text 'Agent(s) Merged'
    expect(JSONModel(:agent_person).find(@merge_destination.id).names.first['source']).to eq(@name_source)
  end

  it 'does not offer them on a new record' do
    visit '/resources/new'

    expect(page).to have_select('resource_dates__0__label_')
    expect(page).not_to have_css('#resource_dates__0__label_ option', text: @date_label)
  end
end
