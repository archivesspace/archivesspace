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
end
