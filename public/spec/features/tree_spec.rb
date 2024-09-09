require 'spec_helper'
require 'rails_helper'

describe 'Tree', js: true do
  it 'displays items in the resource tree' do
    visit('/')
    click_link 'Collections'
    fill_in 'Search within results', with: 'Resource with digital instance'
    click_button 'Search'
    click_link 'Resource with digital instance'
    expect(page).to have_content('Resource with digital instance')
    within 'div[title="AO with DO"]' do
      expect(page).to have_css('.has_digital_instance')
    end
    within 'div[title="AO without DO"]' do
      expect(page).to_not have_css('.has_digital_instance')
    end
  end
end
