require 'spec_helper'
require 'rails_helper'

describe 'Resources', js: true do
  before(:all) do
    @repo = create(:repo, repo_code: "resource_test_#{Time.now.to_i}",
                          publish: true)
    set_repo @repo
    @resource = create(:resource, publish: true)
    @aos = (0..5).map do
      create(:archival_object,
             resource: { 'ref' => @resource.uri }, publish: true)
    end
    run_all_indexers
  end

  it 'Should be able to see resources in a repository' do
    visit('/')
    click_link 'Collections'
    click_link @resource.title
    click_link 'Collection Organization'
    finished_all_ajax_requests?
    page.go_back
    finished_all_ajax_requests?
    expect(page).not_to(
      have_content(
        'Your request could not be completed due to an unexpected error'
      )
    )
  end
end
