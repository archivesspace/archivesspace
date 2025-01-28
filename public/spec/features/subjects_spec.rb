require 'spec_helper'
require 'rails_helper'

describe 'Subjects', js: true do
  it 'should be able to see all subjects' do
    visit('/')
    click_link 'Subjects'
    within all('.col-sm-12')[0] do
      expect(page).to have_content("Showing Subjects: 1 - 2 of 2")
    end
  end

  it 'displays subject page' do
    visit('/')
    click_link 'Subjects'
    click_link 'Term 1'
    expect(current_path).to match(/subjects\/\d+/)
    expect(page).to have_content('Term 1')
  end

  it 'does not highlight repository uri' do
    visit('/')

    click_on 'Repositories'
    click_on 'Test Repo 1'
    find('#whats-in-container form .btn.btn-default.subject').click

    expect(page).to_not have_text Pathname.new(current_path).parent.to_s
  end
end
