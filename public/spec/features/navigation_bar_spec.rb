require 'spec_helper'
require 'rails_helper'

describe 'Navigation Bar', js: true do
  it 'should direct links to the appropriate path' do
    visit('/')
    click_link 'Repositories'
    expect(current_path).to eq ('/repositories')
    page.go_back
    click_link 'Collections'
    expect(current_path).to eq ('/repositories/resources')
    page.go_back
    # click_link 'Digital Materials'
    # expect(page).to have_current_path(objects_path(:limit => 'digital_object'))
    # page.go_back
    click_link 'Unprocessed Material'
    expect(current_path).to eq ('/accessions')
    page.go_back
    # click_link 'Subjects'
    # expect(current_path).to eq ('/subjects')
    # page.go_back
    # click_link 'Names'
    # expect(current_path).to eq ('/agents')
    # page.go_back
    # click_link 'Record Groups'
    # expect(current_path).to eq ('/classifications')
    # page.go_back
    click_link 'Search The Archives'
    expect(current_path).to eq ('/search')
  end

  describe 'accessibility' do
    context 'on mobile devices' do
      before (:each) do
        page.driver.browser.manage.window.resize_to(800, 600)
        visit('/')
      end

      after (:each) do
        # Reset browser window to prevent impacting other tests
        width, height = default_window_size
        page.driver.browser.manage.window.resize_to(width, height)
      end

      describe 'the menu' do
        let(:control_element_selector) { 'button.navbar-toggler' }
        let(:controlled_element_id) { 'collapsemenu' }

        it_behaves_like 'having an accessible exapandable element'
      end
    end
  end
end
