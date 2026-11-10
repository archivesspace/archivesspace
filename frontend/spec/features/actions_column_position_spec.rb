# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

# The Action Buttons (View/Edit) Position preference places the View/Edit
# column at the start of each results row (just after any selection column)
# or at the end of the row. 'start' (Left) is the default.
describe 'Action Buttons (View/Edit) Position', js: true do
  before(:all) do
    @now = Time.now.to_i
    @repo = create(:repo, repo_code: "actions_position_#{@now}")
    set_repo(@repo)

    @agent = create(:agent_person)
    @accession = create(:accession, title: "Actions position accession #{@now}",
                                    linked_agents: [{ 'ref' => @agent.uri, 'role' => 'source' }])
    @resource = create(:resource, title: "Actions position resource #{@now}")
    @archival_object = create(:archival_object, title: "Actions position AO #{@now}",
                                                resource: { 'ref' => @resource.uri })

    JSONModel(:job).from_hash(
      'job' => { 'jsonmodel_type' => 'report_job', 'report_type' => 'AccessionReport', 'format' => 'csv' }
    ).save

    @viewer = create_user(@repo => ['repository-viewers'])

    run_index_round
  end

  before(:each) do
    login_admin
    select_repository(@repo)
  end

  # position: :left or :right, matching the Action Buttons (View/Edit) Position setting.
  # Left means just after the checkbox column when there is one, otherwise first.
  def expect_actions_column(position)
    table = find('#tabledSearchResults', match: :first)
    has_checkboxes = table.has_css?('thead tr > th.multiselect-column:first-child', wait: false)

    { 'thead tr' => 'th', 'tbody tr:first-child' => 'td' }.each do |row, cell|
      selector = if position == :right
                   "#{cell}.table-record-actions:last-child"
                 elsif has_checkboxes
                   "#{cell}.multiselect-column:first-child + #{cell}.table-record-actions"
                 else
                   "#{cell}.table-record-actions:first-child"
                 end

      expect(table).to have_css("#{row} > #{selector}")
    end
  end

  def search_for(text)
    find('#global-search-box').fill_in with: text
    find('#global-search-button').click
    expect(page).to have_css('#tabledSearchResults')
  end

  describe 'default (Left)' do
    it 'puts the actions column just after the checkbox column on browse pages' do
      visit '/accessions'
      expect(page).to have_css('#tabledSearchResults th.multiselect-column')
      expect_actions_column(:left)

      visit '/agents'
      expect(page).to have_css('#tabledSearchResults th.multiselect-column')
      expect_actions_column(:left)
    end

    it 'puts the actions column first on browse pages without a checkbox column' do
      login_user(@viewer)
      select_repository(@repo)

      visit '/accessions'
      expect(page).to have_css('#tabledSearchResults')
      expect(page).not_to have_css('#tabledSearchResults th.multiselect-column')
      expect_actions_column(:left)
    end

    it 'puts the actions column first on search results' do
      search_for(@now.to_s)
      expect_actions_column(:left)

      click_on 'Accession'
      expect(page).to have_text 'Record Type: Accession'
      expect_actions_column(:left)
    end

    it 'puts the View action first on the Background Jobs table' do
      visit '/jobs'
      expect(page).to have_css('#tabledSearchResults tbody tr')
      expect_actions_column(:left)
      expect(find('#tabledSearchResults tbody tr:first-child td:first-child')).to have_link('View')
    end

    it 'applies to resource browse results that include components' do
      visit '/resources?include_components=true'
      expect(page).to have_css('#tabledSearchResults tbody tr', text: @archival_object.title)
      expect_actions_column(:left)
    end

    it 'applies to embedded record-page tables' do
      visit "/agents/agent_person/#{@agent.id}"

      within '#linked_agents' do
        expect(page).to have_css('#tabledSearchResults tbody tr', text: @accession.title)
        table = find('#tabledSearchResults')
        expect(table).to have_css(
          'thead tr > th.table-record-actions:first-child, ' \
          'thead tr > th.multiselect-column:first-child + th.table-record-actions'
        )
      end
    end

    it 'does not add an actions column to linker tables' do
      visit '/accessions?linker=true'
      expect(page).to have_css('#tabledSearchResults tbody tr')
      expect(page).not_to have_css('#tabledSearchResults .table-record-actions')
    end
  end

  describe 'changing to Right' do
    {
      global: 'Global Preferences (admin)',
      repository: 'Repository Preferences (admin)',
      default_repository: 'Default Repository Preferences'
    }.each do |scope, label|
      it "moves the actions column to the end of the row when set in #{label}" do
        with_actions_column_position('accession', 'Right', scope: scope) do
          expect(page).to have_text 'Preferences updated'

          visit '/accessions'
          expect_actions_column(:right)

          # Search broadly enough to get several record types, so the Record
          # Type filter (and its 'Accession' link) is shown
          search_for(@now.to_s)
          click_on 'Accession'
          expect(page).to have_text 'Record Type: Accession'
          expect_actions_column(:right)
        end

        visit '/accessions'
        expect_actions_column(:left)
      end
    end

    it 'moves the search results actions column independently of browse tables' do
      with_actions_column_position('multi', 'Right') do
        search_for(@now.to_s)
        expect_actions_column(:right)

        visit '/accessions'
        expect_actions_column(:left)
      end
    end

    it 'shows the inherited value as the default and restores Left on reset' do
      with_actions_column_position('accession', 'Right', scope: :default_repository) do
        find('#user-menu-dropdown').click
        click_link 'Repository Preferences (admin)'
        expect(page).to have_select('preference_defaults__accession_actions_column_position_',
                                    selected: '> Accept Default: Right')
      end

      set_actions_column_position('accession', 'Right', scope: :default_repository)
      click_on 'Reset Defaults'
      within '#confirmChangesModal' do
        click_on 'Reset Defaults'
      end
      expect(page).to have_text 'Preferences set to application defaults'

      find('#user-menu-dropdown').click
      click_link 'Default Repository Preferences'
      expect(page).to have_select('preference_defaults__accession_actions_column_position_',
                                  selected: '> Accept Default: Left')

      visit '/accessions'
      expect_actions_column(:left)
    end
  end

  describe 'Top Container Management' do
    before(:all) do
      set_repo(@repo)
      @tc_accession_container = create(:top_container, indicator: "TCA #{@now}", barcode: "tca#{@now}")
      @tc_containers = [
        create(:top_container, indicator: "TC #{@now} 2", barcode: "tcb#{@now}"),
        create(:top_container, indicator: "TC #{@now} 1", barcode: "tcc#{@now}")
      ]
      @tc_accession = create(:accession,
                             title: "TC actions position accession #{@now}",
                             instances: [build(:json_instance,
                                               sub_container: build(:json_sub_container,
                                                                    top_container: { ref: @tc_accession_container.uri }))])
      run_all_indexers
    end

    let(:results) { '#bulk_operation_results table' }

    def search_top_containers(clear_saved_sort: false)
      visit '/top_containers'
      page.execute_script("sessionStorage.removeItem('top_container_sort')") if clear_saved_sort
      fill_in 'Keyword', with: @now.to_s
      click_button 'Search'
      expect(page).to have_css("#{results} tbody tr", minimum: 2)
    end

    def sorted_header_keys
      all("#{results} thead th.headerSortUp, #{results} thead th.headerSortDown").map { |th| th['data-sort-key'] }
    end

    # position: :left or :right, matching the Action Buttons (View/Edit) Position setting.
    # This table always starts with a selection column, so Left means second.
    def expect_tc_actions_column(position)
      selector = if position == :right
                   'th.table-record-actions:last-child'
                 else
                   'th:first-child + th.table-record-actions'
                 end

      expect(page).to have_css("#{results} thead tr > #{selector}")
      expect(page).to have_css("#{results} tbody tr:first-child > #{selector.gsub('th', 'td')}")
    end

    it 'puts the actions column just after the selection column by default' do
      search_top_containers
      expect_tc_actions_column(:left)
    end

    it 'puts the actions column at the end of the row when set to Right' do
      with_actions_column_position('top_container_mgmt', 'Right') do
        search_top_containers
        expect_tc_actions_column(:right)
      end
    end

    it 'applies the default sort to the displayed column wherever the actions column is' do
      with_preference_selections({ 'top_container_mgmt_sort_column' => 'Indicator' }) do
        search_top_containers(clear_saved_sort: true)
        expect(sorted_header_keys).to eq(['indicator'])

        with_actions_column_position('top_container_mgmt', 'Right') do
          search_top_containers(clear_saved_sort: true)
          expect(sorted_header_keys).to eq(['indicator'])
        end
      end
    end

    it 'does not sort by the actions column' do
      with_preference_selections({ 'top_container_mgmt_sort_column' => 'Indicator' }) do
        search_top_containers(clear_saved_sort: true)

        find("#{results} thead th.table-record-actions").click
        expect(page).not_to have_css("#{results} thead th.table-record-actions.headerSortUp")
        expect(page).not_to have_css("#{results} thead th.table-record-actions.headerSortDown")
        expect(sorted_header_keys).to eq(['indicator'])
      end
    end

    it 'does not select the row when View is clicked' do
      search_top_containers

      # Keep the page in place so the row selection state can be checked
      page.execute_script(<<~JS)
        document.querySelectorAll('#bulk_operation_results .table-record-actions a').forEach(function (link) {
          link.addEventListener('click', function (event) { event.preventDefault(); });
        });
      JS

      within "#{results} tbody tr:first-child" do
        click_link 'View'
        expect(find('input[type="checkbox"]')).not_to be_checked
      end
      expect(page).not_to have_css("#{results} tbody tr.selected")
    end

    it 'keeps a user-selected sort on the same column after the actions column moves' do
      with_preference_selections({ 'top_container_mgmt_sort_column' => 'Barcode' }) do
        search_top_containers(clear_saved_sort: true)
        expect(sorted_header_keys).to eq(['barcode'])

        find("#{results} thead th[data-sort-key='indicator']").click
        expect(sorted_header_keys).to eq(['indicator'])

        with_actions_column_position('top_container_mgmt', 'Right') do
          search_top_containers
          expect_tc_actions_column(:right)
          expect(sorted_header_keys).to eq(['indicator'])
        end
      end
    end

    it 'falls back to the default sort when the saved sort column is no longer displayed' do
      with_preference_selections({ 'top_container_mgmt_sort_column' => 'Barcode' }) do
        search_top_containers(clear_saved_sort: true)
        find("#{results} thead th[data-sort-key='indicator']").click
        expect(sorted_header_keys).to eq(['indicator'])

        with_browse_column_preferences('top_container_mgmt', { 6 => 'Location Profile' }) do
          search_top_containers
          expect(page).not_to have_css("#{results} thead th[data-sort-key='indicator']")
          expect(sorted_header_keys).to eq(['barcode'])
        end
      end
    end

    it 'applies no sort when the default sort column is not displayed' do
      with_preference_selections({ 'top_container_mgmt_sort_column' => 'Exported to ILS' }) do
        search_top_containers(clear_saved_sort: true)
        expect(page).not_to have_css("#{results} thead th[data-sort-key='exported_to_ils']")
        expect(sorted_header_keys).to be_empty

        # The table sorter is still working
        find("#{results} thead th[data-sort-key='indicator']").click
        expect(sorted_header_keys).to eq(['indicator'])
      end
    end

    it 'applies to the Manage Top Containers modal' do
      visit "/accessions/#{@tc_accession.id}/edit"
      find('#other-dropdown button').click
      click_button 'Manage Top Containers'

      within '#accessTopContainersModal' do
        wait_for_ajax
        expect(page).to have_css('#bulk_operation_results tbody tr', text: @tc_accession_container.indicator)
        expect(page).to have_css('#bulk_operation_results thead tr > th:first-child + th.table-record-actions')
      end
    end

    it 'has no actions column in the browse (linker) modal' do
      visit "/accessions/#{@tc_accession.id}/edit"

      click_on 'Add Container Instance'
      select 'Text', from: 'accession_instances__1__instance_type_'

      within '#accession_instances__1__container_' do
        find('button.dropdown-toggle[aria-label="Link to top container"]').click
        click_on 'Browse'
      end

      within '#accession_instances__1__sub_container__top_container__ref__modal' do
        expect(page).to have_text 'Browse Top Containers'
        wait_for_ajax
        all('.token-input-delete-token').each(&:click)
        fill_in 'Keyword', with: @now.to_s
        click_on 'Search'
        wait_for_ajax

        # The browse modal renders its results inside #topContainerBrowseContainer
        expect(page).to have_css('#topContainerBrowseContainer tbody tr', minimum: 2)
        expect(page).not_to have_css('#topContainerBrowseContainer .table-record-actions')
        expect(page).to have_css('#topContainerBrowseContainer tbody tr:first-child td:first-child input[type="radio"]')
      end
    end
  end
end
