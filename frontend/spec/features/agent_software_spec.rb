require 'spec_helper.rb'
require 'rails_helper.rb'

describe 'AgentSoftware', js: true do
  let(:admin) { BackendClientMethods::ASpaceUser.new('admin', 'admin') }

  before(:each) do
    login_user(admin)
  end

  context 'Merge', js: true do
    it 'should merge two software agents' do
      agent_1_name = SecureRandom.hex
      agent_1 = create(:json_agent_software,
        names: [ build(:json_name_software, { software_name: agent_1_name }) ]
      )
      agent_2_name = SecureRandom.hex
      agent_2 = create(:json_agent_software,
        names: [ build(:json_name_software, { software_name: agent_2_name }) ]
      )

      run_index_round

      visit agent_1.uri
      page.has_xpath? '//div[@id="merge-dropdown"]'

      find('div[id="merge-dropdown"]').click
      find('#token-input-merge_ref_').send_keys(agent_2_name)
      wait_for_ajax
      find('#token-input-merge_ref_').send_keys :enter
      find('button.merge-button').click

      expect(page).to have_text 'Compare Agents'
      find('button#confirmButton').click

      expect(page).to have_text 'Merge Preview'
      find('.do-merge', match: :first).click
      expect(page).to have_text agent_1_name

      run_index_round

      click_on 'Browse'
      within('.dropdown-menu') do
        click_link 'Agents'
      end

      within('.search-listing-filter') do
        click_link 'Software'
      end

      expect(page).to have_text agent_1_name
      expect(page).not_to have_text agent_2_name
    end
  end
end
