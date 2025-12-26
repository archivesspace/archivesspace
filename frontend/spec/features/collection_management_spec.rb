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

  context 'index view' do
    describe 'results table' do
      let(:now) { Time.now.to_i }
      let(:record_type) { 'collection_management'}
      let(:browse_path) { '/collection_management' }
      let(:record_1) do
        create(
          :accession,
          title: "Accession with Collection Management #{now}",
          id_0: now.to_s,
          collection_management: {
            "processing_status" => "completed",
            "processing_priority" => "medium",
            "processing_hours_total" => "2",
            "processing_funding_source" => "AAA"
          }
        )
      end
      let(:record_2) do
        create(
          :resource,
          title: "Resource with Collection Management #{now}",
          collection_management: {
            "processing_status" => "new",
            "processing_priority" => "high",
            "processing_hours_total" => "1",
            "processing_funding_source" => "ZZZ"
          }
        )
      end
      let(:initial_sort) { [record_1.title, record_2.title] }

      describe 'sorting' do
        include_context 'results table setup'

        let(:default_sort_key) { 'title_sort' }
        let(:primary_column_class) { 'parent_title' }
        let(:additional_browse_columns) do
          {
            6 => 'Processing Funding Source',
            7 => 'URI'
          }
        end
        let(:column_headers) {
          {
            'Title' => 'title_sort',
            'Record Type' => 'parent_type',
            'Processing Priority' => 'processing_priority',
            'Processing Status' => 'processing_status',
            'Total Hours' => 'processing_hours_total',
            'Processing Funding Source' => 'processing_funding_source',
            'URI' => 'uri'
          }
        }
        let(:primary_sort_expectations) do
          {
           'title_sort' => {
              asc: [record_1.title, record_2.title],
              desc: [record_2.title, record_1.title]
            },
            'parent_type' => {
              asc: [record_1.title, record_2.title],
              desc: [record_2.title, record_1.title]
            },
            'processing_priority' => {
              asc: [record_2.title, record_1.title],
              desc: [record_1.title, record_2.title]
            },
            'processing_status' => {
              asc: [record_1.title, record_2.title],
              desc: [record_2.title, record_1.title]
            },
            'processing_hours_total' => {
              asc: [record_2.title, record_1.title],
              desc: [record_1.title, record_2.title]
            },
            'processing_funding_source' => {
              asc: [record_1.title, record_2.title],
              desc: [record_2.title, record_1.title]
            },
            'uri' => uri_id_as_string_sort_expectations([record_1, record_2], ->(r) { r.title })
          }
        end
        # Uses same processing_priority ("high") as record_2 to create a tie
        let(:record_3) do
          create(
            :resource,
            title: "Resource Z with Collection Management #{now}",
            collection_management: {
              "processing_status" => "in_progress",
              "processing_priority" => "high",
              "processing_hours_total" => "2",
              "processing_funding_source" => "MMM"
            }
          )
        end
        let(:secondary_sort_cases) do
          [
            {
              # Case 1: primary title_sort asc, secondary processing_priority asc - no-op since titles are unique
              primary_key:   'title_sort',
              primary_dir:   :asc,
              secondary_key: 'processing_priority',
              secondary_dir: :asc,
              expected_after_primary: [
                record_1.title,
                record_2.title,
                record_3.title
              ],
              expected_after_both: [
                record_1.title,
                record_2.title,
                record_3.title
              ]
            },
            {
              # Case 2: primary processing_priority asc, secondary title_sort desc - secondary changes order
              primary_key:   'processing_priority',
              primary_dir:   :asc,
              secondary_key: 'title_sort',
              secondary_dir: :desc,
              expected_after_primary: [
                record_2.title,
                record_3.title,
                record_1.title
              ],
              expected_after_both: [
                record_3.title,
                record_2.title,
                record_1.title
              ]
            },
            {
              # Case 3: primary processing_hours_total asc, secondary processing_status desc - secondary changes order
              primary_key:   'processing_hours_total',
              primary_dir:   :asc,
              secondary_key: 'processing_status',
              secondary_dir: :desc,
              expected_after_primary: [
                record_2.title,
                record_1.title,
                record_3.title,
              ],
              expected_after_both: [
                record_2.title,
                record_3.title,
                record_1.title,
              ]
            }
          ]
        end

        it_behaves_like 'results table sorting'
      end
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
end
