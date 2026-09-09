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
        expect(page).to have_css('#request_modal')
      end

      it 'the modal becomes visible' do
        aggregate_failures do
          expect(page).to have_css('#request_modal', visible: true)
          expect(page).to have_css('#request_form', visible: true)
        end
      end

      it 'shows Bootstrap validation feedback when required fields are empty' do
        within '#request_modal' do
          find('#request_btn').click
          wait_for_jquery

          aggregate_failures do
            expect(page).to have_css('#request_form.was-validated')
            expect(page).to have_css('#user_name:invalid')
            expect(page).to have_css('#user_email:invalid')
            expect(page).to have_css('.invalid-feedback', text: 'Please enter your name', visible: true)
            expect(page).to have_css('.invalid-feedback', text: 'Please enter a valid email address', visible: true)
          end
        end

        expect(page).to have_css('#request_modal', visible: true)
      end

      it 'shows email validation feedback for an invalid email format' do
        within '#request_modal' do
          fill_in 'user_name', with: 'Test User'
          fill_in 'user_email', with: 'not-an-email'
          find('#request_btn').click
          wait_for_jquery

          aggregate_failures do
            expect(page).to have_css('#request_form.was-validated')
            expect(page).to have_css('#user_name:valid')
            expect(page).to have_css('#user_email:invalid')
            expect(page).to have_css('.invalid-feedback', text: 'Please enter a valid email address', visible: true)
          end
        end

        expect(page).to have_css('#request_modal', visible: true)
      end

      it 'clears previous validation state when the modal is reopened' do
        within '#request_modal' do
          find('#request_btn').click
          wait_for_jquery
          expect(page).to have_css('#request_form.was-validated')
        end

        within '#request_modal' do
          find('#request_modal_footer_close').click
        end
        expect(page).to have_css('#request_modal', visible: :hidden)

        find('button.page_action.request').click
        wait_for_jquery

        within '#request_modal' do
          expect(page).not_to have_css('#request_form.was-validated')
        end
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
