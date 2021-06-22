require 'spec_helper'
require 'rails_helper'

describe 'Repositories', js: true do
  def visit_repository_page
    visit '/'
    click_link 'Repositories'
    first('.record-title').click
  end

  def visit_repository_badge_page(badge)
    visit_repository_page
    click_button badge
  end

  it 'should only show archival objects for the record badge' do
    visit_repository_badge_page('Records')
    expect(current_path).to match(/repositories.*records/)
    expect(page).to have_content(/Found.*Test Repo.*Published Resource/)
    expect(page).to have_content('Item')
    expect(page).to_not have_content('Digital Record')
  end

  it 'should only show digital objects for the digital materials badge' do
    visit_repository_badge_page('Digital Materials')
    expect(current_path).to match(/repositories.*digital_objects/)
    expect(page).to have_content(/Found.*Test Repo/)
    expect(page).to have_content('Digital Record')
    expect(page).to_not have_content('Item')
  end
end
