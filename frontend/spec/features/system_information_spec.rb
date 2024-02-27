# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'System Information', js: true do
  let(:admin_user) { BackendClientMethods::ASpaceUser.new('admin', 'admin') }
  let!(:repository) { create(:repo, repo_code: "system_information_#{Time.now.to_i}") }
  let(:archivist_user) { create_user(repository => ['repository-archivists']) }

  it 'should not let any old fool see this' do
    login_user(archivist_user)
    select_repository(repository)

    click_on 'System'
    expect(page).to_not have_text 'System Information'

    visit '/system_info'

    expect(page).to have_text 'Unable to Access Page'
    expect(page).to have_text "The page you've tried to access may no longer exist or you may not have permission to view it."
  end

  it 'should let the admin see this' do
    login_user(admin_user)
    select_repository(repository)

    click_on 'System'
    click_on 'System Information'

    expect(page).to have_text 'Frontend System Information'
    expect(page).to have_text 'VERSION'
    expect(page).to have_text 'APPCONFIG'
    expect(page).to have_text 'MEMORY'
    expect(page).to have_text 'CPU_COUNT'
  end
end
