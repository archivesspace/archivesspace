require 'spec_helper'
require 'rails_helper'

describe 'Classifications', js: true do
  it 'should be able to see all published resources in a repository' do
    visit('/')
    click_link 'Record Groups'
    within all('.col-sm-12')[0] do
      expect(page).to have_content("Showing Record Groups: 1 - ")
    end
  end

  it 'displays show page' do
    visit('/')
    click_link 'Record Groups'
    click_link 'My Special Classification'
  end


  it 'does not highlight repository uri' do
    visit('/')

    click_on 'Repositories'
    click_on 'Test Repo 1'
    find('#whats-in-container form .btn.btn-default.classification').click

    expect(page).to_not have_text Pathname.new(current_path).parent.to_s
  end
end
