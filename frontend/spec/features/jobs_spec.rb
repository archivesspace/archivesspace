# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Jobs', js: true do
  before(:all) do
    @repo = create(:repo, repo_code: "jobs_test_#{Time.now.to_i}", publish: true)
    set_repo(@repo)
  end

  before(:each) do
    login_admin
    select_repository(@repo)
  end

  it 'can create a find and replace job', skip: 'UPGRADE waiting on bootstrap fixes' do
    resource = create(:resource)

    run_index_round

    sleep 5.seconds

    click_link('Repository settings')
    click_link('Background Jobs')
    click_link('Create Job')
    within('.dropdown-menu') do
      click_link('Batch Find and Replace (Beta)')
    end
    fill_in('token-input-job_ref_', with: resource.title)
    find(:css, 'li.token-input-dropdown-item2').click
    select('Extent', from: 'Record or subrecord type')
    select('Container Summary', from: 'Target property')
    fill_in('String to find', with: 'abc')
    fill_in('Replacement string', with: 'def')
    click_button('Start Job')
    wait_for_job_to_complete(page)
    expect(page).to have_content('Find and Replace Job')
    click_button('Refresh Page')
    expect(page).to have_content('Completed')
  end

  it 'can create a print to pdf job' do
    resource = create(:resource)

    run_index_round

    click_link('Repository settings')
    click_link('Background Jobs')
    click_link('Create Job')
    within('.dropdown-menu') do
      click_link('Generate PDF')
    end
    fill_in('token-input-job_source_', with: resource.title)
    find(:css, 'li.token-input-dropdown-item2').click
    click_button('Start Job')
    wait_for_job_to_complete(page)
    expect(page).to have_content('print_to_pdf_job')
    click_button('Refresh Page')
    sleep 1.seconds
    expect(page).to have_content('Completed')
  end

  it 'can create a report job' do
    click_link('Repository settings')
    click_link('Background Jobs')
    click_link('Create Job')
    within('.dropdown-menu') do
      click_link('Create Report')
    end
    within('.report-list') do
      click_button('Accession Report')
    end
    select('CSV', from: 'Format')
    click_button('Start Job')
    wait_for_job_to_complete(page)
    expect(page).to have_content('report_job')
    click_button('Refresh Page')
    sleep 1.seconds
    expect(page).to have_content('Completed')
  end

  it 'can display a list of background jobs' do
    # first make sure there is at least a job to populate the list with
    click_link('Repository settings')
    click_link('Background Jobs')
    click_link('Create Job')
    within('.dropdown-menu') do
      click_link('Create Report')
    end
    click_button('Accession Report')
    click_button('Start Job')
    wait_for_job_to_complete(page)
    expect(page).to have_content('report_job')
    click_button('Refresh Page')
    sleep 1.seconds
    expect(page).to have_content('Completed')

    # don't forget to index or it won't show up!
    run_index_round
    click_link('Background Jobs')

    expect(find(id: 'tabledSearchResults')).to have_content('Accession Report')
  end

  it 'can import an accession and display import type' do
    template_file = File.expand_path(
      '../../../../backend/spec/examples/aspace_accession_import_template.csv', __FILE__)

    click_link('Repository settings')
    click_link('Background Jobs')
    click_link('Create Job')
    within('.dropdown-menu') do
      click_link('Import Data')
    end

    # can this be done without calling the javascript directly?
    execute_script("return $('#job_filenames_ > span > input')[0]").send_keys(template_file)
    click_button('Start Job')
    wait_for_job_to_complete(page)
    expect(page).to have_content('Import Job')
    click_button('Refresh Page')
    sleep 1.seconds
    expect(page).to have_content('Completed')
  end

end
