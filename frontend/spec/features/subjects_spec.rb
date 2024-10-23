# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Subjects', js: true do
  let(:repository) { create(:repo, repo_code: "subjects_#{Time.now.to_i}") }
  let(:archivist_user) { create_user(repository => ['repository-archivists']) }

  before(:each) do
    login_user(archivist_user)
    select_repository(repository)
  end

  it 'reports errors and warnings when creating an invalid Subject' do
    click_on 'Create'
    click_on 'Subject'
    click_on 'Add External Document'

    element = find('#subject_terms_ .subrecord-form-remove')
    element.click
    click_on 'Confirm Removal'

    # Click on save
    element = find('button', text: 'Save', match: :first)
    element.click

    expect(page).to have_text 'Terms and Subdivisions - At least 1 item(s) is required'
  end

  it 'can create a new subject' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Subject'

    select 'Local sources', from: 'Source'

    fill_in 'subject_terms__0__term_', with: "First Term #{now}"
    select 'Function', from: 'subject_terms__0__term_type_'
    click_on 'Add Term/Subdivision'
    # NOTE: Original selenium spec was using the following, but for some reason does exist in the dropdown.
    # @driver.find_element(id: 'subject_terms__0__term_type_').select_option('cultural_context')
    # Might require a call to: create_subjects & run_index_round
    fill_in 'subject_terms__1__term_', with: "Second Term #{now}"
    select 'Geographic', from: 'subject_terms__1__term_type_'

    # Click on save
    element = find('button', text: 'Save', match: :first)
    element.click

    expect(page).to have_text 'Subject Created'
    element = find('.record-pane h2')
    expect(element).to have_text "First Term #{now} -- Second Term #{now}"
  end

  it 'does not create a new subject if there is another identical subject' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Subject'

    fill_in 'subject_authority_id_', with: "Authority ID #{now}"
    select 'Local sources', from: 'Source'
    fill_in 'subject_terms__0__term_', with: "Subject Term #{now}"
    select 'Temporal', from: 'subject_terms__0__term_type_'

    # Click on save
    element = find('button', text: 'Save', match: :first)
    element.click

    expect(page).to have_text 'Subject Created'
    element = find('.record-pane h2')

    split_url = current_url.split('/')
    split_url.pop
    existing_subject_id = split_url.pop

    run_index_round

    # Create an identical subject
    click_on 'Create'
    click_on 'Subject'

    fill_in 'subject_authority_id_', with: "Authority ID #{now}"
    select 'Local sources', from: 'Source'
    fill_in 'subject_terms__0__term_', with: "Subject Term #{now}"
    select 'Temporal', from: 'subject_terms__0__term_type_'

    # Click on save
    element = find('button', text: 'Save', match: :first)
    element.click

    element = find('.alert.alert-danger.with-hide-alert')
    expect(element.text).to eq "Terms and Subdivisions - Subject records cannot be identical\nAuthority ID - Subject heading identifier must be unique within source\nView conflicting record"
    expect(page).to have_link(text: 'View conflicting record', href: "http://localhost:8080/resolve/readonly?uri=/subjects/#{existing_subject_id}")
  end

  it 'can present a browse list of Subjects' do
    now = Time.now.to_i
    subject = create(:subject, terms: [build(:term, {term: "Term #{now}", term_type: 'temporal'})])
    run_index_round

    click_on 'Browse'
    click_on 'Subjects'
    click_on 'Terms Ascending'
    click_on 'Created'

    element = all('#tabledSearchResults tbody tr').first
    expect(element).to have_text subject.title
  end

  it 'can reorder the terms and have them maintain order' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Subject'
    select 'Local sources', from: 'Source'
    fill_in 'subject_terms__0__term_', with: "First Term #{now}"
    select 'Function', from: 'subject_terms__0__term_type_'
    click_on 'Add Term/Subdivision'
    fill_in 'subject_terms__1__term_', with: "Second Term #{now}"
    select 'Geographic', from: 'subject_terms__1__term_type_'

    # Click on save
    element = find('button', text: 'Save', match: :first)
    element.click

    expect(page).to have_text 'Subject Created'
    element = find('.record-pane h2')
    expect(element).to have_text "First Term #{now} -- Second Term #{now}"

    first_element = find('#subject_terms__0_ .drag-handle')
    second_element = find('#subject_terms__1_ .drag-handle')

    second_element.drag_to(first_element)

    elements = all('#subject_terms_ ul li')
    expect(elements.length).to eq(2)

    within elements[0] do
      element = find('input#subject_terms__1__term_')
      expect(element.value).to eq("Second Term #{now}")
    end

    within elements[1] do
      element = find('input#subject_terms__0__term_')
      expect(element.value).to eq("First Term #{now}")
    end

    # Click on save
    element = find('button', text: 'Save', match: :first)
    element.click

    expect(page).to have_text 'Subject Saved'

    expect(find('input#subject_terms__0__term_').value).to eq("Second Term #{now}")
    expect(find('input#subject_terms__1__term_').value).to eq("First Term #{now}")
  end

  it 'can use plus+1 submit to quickly add another' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Subject'
    select 'Local sources', from: 'Source'
    fill_in 'subject_terms__0__term_', with: "First Term #{now}"
    select 'Function', from: 'subject_terms__0__term_type_'

    element = find('#createPlusOne')
    element.click

    expect(page).to have_text 'Subject Created'
    expect(page).to have_text 'New Subject'

    expect(find('#subject_source_').value).to eq('')
    expect(find('#subject_terms__0__term_').value).to eq('')
    expect(find('#subject_terms__0__term_type_').value).to eq('')
  end

  it 'can export a csv of browse list subjects' do
    now = Time.now.to_i
    subject_1 = create(:subject, terms: [build(:term, {term: "Term A #{now}", term_type: 'temporal'})])
    subject_2 = create(:subject, terms: [build(:term, {term: "Term B #{now}", term_type: 'temporal'})])
    run_index_round

    click_on 'Browse'
    click_on 'Subjects'
    expect(page).to have_text 'Subjects'

    # Delete any existing CSV files
    csv_files = Dir.glob(File.join(Dir.tmpdir, '*.csv'))
    csv_files.each do |file|
      File.delete(file)
    end

    csv_files = Dir.glob(File.join(Dir.tmpdir, '*.csv'))
    expect(csv_files.length).to eq(0)

    click_on 'Download CSV'

    csv_files = Dir.glob(File.join(Dir.tmpdir, '*.csv'))
    expect(csv_files.length).to eq(1)

    csv = File.read(csv_files[0])
    expect(csv).to include(subject_1.title)
    expect(csv).to include(subject_2.title)
  end
end
