# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Collection Management', js: true do
  before(:all) do
    @repository = create(:repo, repo_code: "collection_management_test_#{Time.now.to_i}", publish: true)
    @user = create_user(@repository => ['repository-archivists'])

    run_all_indexers
  end

  before(:each) do
    login_user(@user)
    select_repository(@repo)
  end


  it 'should be fine with no records' do
    click_on 'Browse'
    click_on 'Collection Management'
    expect(page).to have_text 'No records found'
  end

  it 'is browseable even when its linked accession has no title' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Accession'
    fill_in("Identifier", with: "Test Accession Identifier #{now}")
    click_on 'Add Collection Management Fields'
    select 'High', from: 'Processing Priority'
    select 'Completed', from: 'Processing Status'

    # Click on save
    element = find('button', text: 'Save Accession', match: :first)
    element.click

    expect(page).to have_text "Accession created"

    run_index_round

    click_on 'Browse'
    click_on 'Collection Management'

    element = find('#tabledSearchResults tbody tr')
    expect(element).to have_text "Test Accession Identifier #{now}"
    within element do
      click_on 'View'
    end

    click_on 'Edit'

    element = find('#accession_collection_management_ .subrecord-form-remove')
    element.click

    click_on 'Confirm Removal'
    # Click on save
    element = find('button', text: 'Save Accession', match: :first)
    element.click
    expect(page).to have_text "Accession updated"

    run_index_round

    visit '/'
    click_on 'Browse'
    click_on 'Collection Management'
    expect(page).to have_text 'No records found'
  end

  it 'should only allow numbers for some values' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Accession'
    fill_in("Title", with: "Test Accession Title #{now}")
    fill_in("Identifier", with: "Test Accession Identifier #{now}")
    click_on 'Add Collection Management Fields'
    fill_in 'Processing hrs/unit Estimate', with: '5 hours'
    fill_in 'Processing Total Extent', with: '6 hours'
    select 'Completed', from: 'Processing Status'
    select 'Cassettes', from: 'Extent Type'

    # Click on save
    element = find('button', text: 'Save Accession', match: :first)
    element.click

    expect(page).to have_text 'Processing hrs/unit Estimate - Must be a number with no more than nine digits and five decimal places.'
    expect(page).to have_text 'Processing Total Extent - Must be a number with no more than nine digits and five decimal places.'

    fill_in 'Processing hrs/unit Estimate', with: '5'
    fill_in 'Processing Total Extent', with: '6'

    # Click on save
    element = find('button', text: 'Save Accession', match: :first)
    element.click
    expect(page).to have_text "Accession Test Accession Title #{now} created"
  end

  it 'can export a list of jobs to CSV' do
    visit 'collection_management'

    # Delete any existing CSV files
    csv_files = Dir.glob(File.join(Dir.tmpdir, '*.csv'))
    csv_files.each do |file|
      File.delete(file)
    end

    click_on 'Download CSV'

    csv_files = Dir.glob(File.join(Dir.tmpdir, '*.csv'))
    expect(csv_files.length).to eq(1)
  end
end
