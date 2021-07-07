require 'spec_helper'
require 'rails_helper'

describe 'Classifications', js: true do
  it 'should be able to see all published resources in a repository' do
    visit('/')
    click_link 'Record Groups'
    within all('.col-sm-12')[0] do
      expect(page).to have_content("Showing Record Groups: 1 - 1 of 1")
    end
  end

  it 'displays show page' do
    visit('/')
    click_link 'Record Groups'
    click_link 'Classification'
    expect(page).to have_content('Classification')
  end
end
