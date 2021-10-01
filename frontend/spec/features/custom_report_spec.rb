# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Custom Reports', js: true do

  before(:each) do
    visit '/'
    page.has_xpath? '//input[@id="login"]'

    within "form.login" do
      fill_in "username", with: "admin"
      fill_in "password", with: "admin"

      click_button "Sign In"
    end

    page.has_no_xpath? '//input[@id="login"]'
  end

  context 'Index' do
    it 'is axe clean' do
      visit '/custom_report_templates'

      expect(page).to be_axe_clean.within('.record-toolbar' '.record-pane')
    end
  end

  context 'Templates' do
    it 'is axe clean' do
      visit '/custom_report_templates/new'

      expect(page).to be_axe_clean.within('.record-toolbar' '.record-pane')
    end
  end

end
