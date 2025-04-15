require 'spec_helper'
require 'rails_helper'

describe 'Request feature', js: true do
  before(:all) do
    @resource = create(:resource, publish: true)
    run_indexers
  end

  before(:each) do
    allow(AppConfig).to receive(:[]).and_call_original
  end

  context 'when AppConfig[:pui_page_actions_request] is set to true' do
    before :each do
      allow(AppConfig).to receive(:[]).with(:pui_page_actions_request) { true }
      visit(@resource.uri)
      wait_for_jquery
    end

    it 'shows the request button' do
      expect(page).to have_button('Request')
    end

    it 'hides the modal by default' do
      expect(page).to have_css('#request_modal', visible: false)
      expect(page).to have_css('#request_form', visible: false)
    end

    context 'when the Request button is clicked' do
      before :each do
        click_button 'Request'
        wait_for_jquery
      end

      it 'the modal becomes visible' do
        expect(page).to have_css('#request_modal', visible: true)
        expect(page).to have_css('#request_form', visible: true)
      end
    end
  end

  context 'when AppConfig[:pui_page_actions_request] is set to false' do
    before :each do
      allow(AppConfig).to receive(:[]).with(:pui_page_actions_request) { false }
    end

    it 'does not include the request button or modal in the DOM' do
      visit(@resource.uri)
      expect(page).not_to have_button('Request')
      expect(page).not_to have_css('#request_modal')
      expect(page).not_to have_css('#request_form')
    end
  end
end
