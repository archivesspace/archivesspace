# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'
require 'csv'

describe 'Search Listing', js: true do
  before(:all) do
    @now = Time.now.to_i

    @admin = BackendClientMethods::ASpaceUser.new('admin', 'admin')

    @repository = create(:repo, repo_code: "search_listing_test_#{@now}")

    set_repo @repository

    @accession_1 = create(:accession, title: "Accession 1 #{@now}")
    @accession_2 = create(:accession, title: "Accession 2 #{@now}", content_description: "Test content description #{@now}")
    @resource = create(:resource, title: "Resource 1 #{@now}", finding_aid_filing_title: "Finding aid filing title #{@now}")
    @archival_object_1 = create(:archival_object, title: "Archival Object Resource 1 #{@now}", resource: { ref: @resource.uri })
    @archival_object_2 = create(:archival_object, title: "Archival Object Resource 2 #{@now}", resource: { ref: @resource.uri })
    @archival_object_3 = create(:archival_object, title: "Archival Object Resource 3 #{@now}", resource: { ref: @resource.uri })
    @digital_object_1 = create(:digital_object, title: "Digital Object 1 #{@now}")

    # Create top containers for CSV export testing
    @top_container_1 = create(:top_container, type: 'box', indicator: 'ID1', barcode: "BC001#{@now}")
    @top_container_2 = create(:top_container, type: 'folder', indicator: 'ID2', barcode: "BC002#{@now}")

    @suppressed_resource = create(:resource, title: "Suppressed resource #{@now}",
                                  instances: [build(:instance_digital, digital_object: { 'ref' => @digital_object_1.uri })])

    @suppressed_resource.set_suppressed(true)

    @viewer_user = create_user(@repository => ['repository-viewers'])

    run_index_round
  end

  before(:each) do
    login_user(@admin)
    select_repository(@repository)
  end

  describe 'search results' do
    it 'supports global searches' do
      find('#global-search-button').click
      expect(page).to have_text 'Search Results'
    end

    it 'supports filtering global searches by type' do
      find('#global-search-button').click
      expect(page).to have_text 'Search Results'

      click_on 'Accession'

      expect(page).to have_text 'Search Results'

      element = find('.search-listing-filter')
      expect(element).to have_text 'Filtered By'
      expect(element).to have_text 'Record Type: Accession'

      element = find('#tabledSearchResults')
      expect(element).to have_text @accession_1.title
      expect(element).to have_text @accession_2.title
    end

    it 'supports some basic fulltext search globally' do
      element = find('#global-search-box')
      element.fill_in with: "content description #{@now}"
      find('#global-search-button').click

      element = find('#tabledSearchResults')
      expect(element).to have_text @accession_2.title
    end

    context 'when search terms found in finding aid filing title only' do
      it 'includes the record in the search results' do
        element = find('#global-search-box')
        element.fill_in with: "Finding aid filing title #{@now}"
        find('#global-search-button').click

        element = find('#tabledSearchResults')
        expect(element).to have_text @resource.title
      end
    end

    it 'displays search results with context' do
      element = find('#global-search-box')
      element.fill_in with: "Object Resource 1 #{@now}"
      find('#global-search-button').click

      element = find('#tabledSearchResults')
      expect(element).to have_text @archival_object_1.title
    end

    it 'does not display suppressed records to viewers' do
      visit 'logout'

      login_user(@viewer_user)
      select_repository(@repository)

      element = find('#global-search-box')
      element.fill_in with: 'Suppressed'
      find('#global-search-button').click

      expect(page).to have_text 'No records found'
    end

    it 'does display suppressed records to admins' do
      element = find('#global-search-box')
      element.fill_in with: 'Suppressed'
      find('#global-search-button').click

      element = find('#tabledSearchResults')
      expect(element).to have_text @suppressed_resource.title
    end

    it 'does display digital objects linked to suppressed records to viewers' do
      visit 'logout'

      login_user(@viewer_user)
      select_repository(@repository)

      element = find('#global-search-box')
      element.fill_in with: "Digital Object 1 #{@now}"
      find('#global-search-button').click

      row = find(:xpath, "//table//tr[contains(., '#{@digital_object_1.title}')]")
      cells = row.all('td')
      expect(cells[1]).to have_text @digital_object_1.title
      expect(cells[2].text).to eq('')
    end

    it 'displays the same columns for search then filter by record type as for browse' do
      visit 'logout'

      login_user(@viewer_user)
      select_repository(@repository)

      click_on 'Browse'
      click_on 'Resources'
      expect(page).to have_text 'Resources'
      elements = all('#tabledSearchResults th')
      elements_from_browse = elements.collect { |col| col.text }.reject { |header| header.empty? }

      find('#global-search-button').click
      click_on 'Resource'
      elements = all('#tabledSearchResults th')
      elements_from_search = elements.collect { |col| col.text }.reject { |header| header.empty? }

      expect(elements_from_browse).to eq(elements_from_search)
    end

    it 'shows all sortable columns in sort dropdown' do
      find('#global-search-button').click
      sortable_columns = all('th.sortable')

      click_on 'Relevance'
      dropdown_elements = find('ul.sort-opts')

      sortable_columns.each do |column|
        expect(dropdown_elements).to have_link column.text
      end
    end

    describe 'column sorting' do
      let(:sortable_column_label) { 'Identifier' }

      it 'cycles between ascending and descending on repeated clicks' do
        # Do a global search and filter to accessions
        find('#global-search-button').click
        expect(page).to have_text 'Search Results'
        click_on 'Accession'

        # Wait for table to load
        expect(page).to have_css('#tabledSearchResults')
        expect(page).to have_text @accession_1.title

        # Find the sortable column header and click it
        within('#tabledSearchResults thead') do
          click_link sortable_column_label
        end

        # First click: sort ascending
        expect(page).to have_css('th.sort-asc', text: sortable_column_label, wait: 5)

        # Second click: sort descending
        within('#tabledSearchResults thead') do
          click_link sortable_column_label
        end
        expect(page).to have_css('th.sort-desc', text: sortable_column_label, wait: 5)

        # Third click: should cycle back to ascending (not reset to default)
        within('#tabledSearchResults thead') do
          click_link sortable_column_label
        end
        expect(page).to have_css('th.sort-asc', text: sortable_column_label, wait: 5)

        # Fourth click: back to descending
        within('#tabledSearchResults thead') do
          click_link sortable_column_label
        end
        expect(page).to have_css('th.sort-desc', text: sortable_column_label, wait: 5)
      end
    end

    describe 'results table sorting' do
      include_context 'results table setup'

      let(:now) { Time.now.to_i }
      let(:record_type) { 'multi' }
      let(:browse_path) { '/search' }
      let(:record_1) { create(:resource, title: "Resource #{now}", id_0: "1") }
      let(:record_2) { create(:accession, title: "Accession #{now}", id_0: "2") }
      let(:default_sort_key) { 'score' }
      let(:sorting_in_url) { true }
      let(:filter_results) { true }
      let(:initial_sort) { [record_1.title, record_2.title] }
      let(:additional_browse_columns) { { 6 => 'URI' } }
      let(:column_headers) do
        {
          'Record Type' => 'primary_type',
          'Title' => 'title_sort',
          'Identifier' => 'identifier',
          'URI' => 'uri'
        }
      end
      let(:sort_expectations) do
        # Re: URI sorting, this is multi-record type so URIs should sort by record type string before id integer
        {
          'primary_type' => { asc: [record_2.title, record_1.title], desc: [record_1.title, record_2.title] },
          'title_sort' => { asc: [record_2.title, record_1.title], desc: [record_1.title, record_2.title] },
          'identifier' => { asc: [record_1.title, record_2.title], desc: [record_2.title, record_1.title] },
          'uri' => { asc: [record_2.title, record_1.title], desc: [record_1.title, record_2.title] }
        }
      end

      it_behaves_like 'results table sorting'
    end
  end

  context 'CSV export' do
    describe 'Top Containers' do
      it 'exports CSV with correct headers and data matching web page display' do
        # Clear any existing CSV files to avoid spec contamination
        files = Dir.glob(File.join(Dir.tmpdir, '*.csv'))
        files.each { |file| File.delete file }

        visit '/search'
        click_on 'Top Container'

        expect(page).to have_text 'Search Results'
        expect(page).to have_text @top_container_1.indicator

        click_on 'Download CSV'

        files = Dir.glob(File.join(Dir.tmpdir, '*.csv'))
        expect(files.length).to be >= 1

        csv_file = File.read(files.last)
        csv_data = CSV.parse(csv_file)
        csv_headers = csv_data[0]

        expect(csv_headers).to include('Type')
        expect(csv_headers).to include('Indicator')
        expect(csv_headers).to include('Barcode')

        container_1_row = csv_data.find { |row| row.include?(@top_container_1.indicator) }
        container_2_row = csv_data.find { |row| row.include?(@top_container_2.indicator) }
        expect(container_1_row).to include(@top_container_1.barcode)
        expect(container_1_row).to include(@top_container_1.type)
        expect(container_2_row).to include(@top_container_2.barcode)
        expect(container_2_row).to include(@top_container_2.type)
      end
    end
  end
end
