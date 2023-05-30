require 'spec_helper'
require 'rails_helper'

describe 'Top Containers', js: true do

  it 'abides by search and browse column preferences' do
    login_admin
    @tc = create(:top_container)
    run_index_round
    visit '/'
    click_link(id: 'user-menu-dropdown')
    click_link('Global Preferences (admin)')
    find(id: 'preference_defaults__top_container_browse_column_1_').select('ILS Holding ID')
    find(id: 'preference_defaults__top_container_sort_column_').select('URI')
    click_button('Save Preferences')
    visit '/top_containers'
    find(id: 'exported').select('Yes')
    click_button('Search')
    expect(find('th.header.headerSortDown')).to have_content('URI')
    expect(page).to have_content('ILS Holding ID')
  end

end
