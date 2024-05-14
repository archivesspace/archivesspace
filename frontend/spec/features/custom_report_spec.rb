# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Custom Reports', js: true do

  before(:each) do
    login_admin
  end

  context 'Index' do
    it 'is axe clean' do
      visit '/custom_report_templates'

      expect(page).to be_axe_clean.within '.record-toolbar', '.record-pane'
    end
  end

  context 'Templates' do
    it 'is axe clean' do
      visit '/custom_report_templates/new'

      expect(page).to be_axe_clean.within '.record-toolbar', '.record-pane'
    end

    it 'can check to display all fields in a custom report' do
      visit '/custom_report_templates/new'
      page.has_xpath? '//button[@id="check_all"]'

      # Nothing is checked now
      expect(page.all('input[id*="_include"]:checked').count).to eq(0)

      # Check all button
      first('button#check_all').click
      expect(page.all('input[id*="_include"]:checked').count).not_to eq(0)

      # Uncheck again
      first('button#check_all').click
      expect(page.all('input[id*="_include"]:checked').count).to eq(0)
    end
  end

end
