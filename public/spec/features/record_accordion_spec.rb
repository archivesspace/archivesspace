require 'spec_helper'
require 'rails_helper'

describe 'Accordion of additional record information blocks', js: true do
  before(:each) do
    visit('/')
    click_link 'Collections'
    expect(current_path).to eq ('/repositories/resources')
    resource = first("a.record-title")
    visit(resource['href'])

    $panels = page.all('.upper-record-details + .acc_holder div.panel.panel-default')
  end

  it 'should be found after the upper record details of a resource page' do
    expect(page).to have_css('div.upper-record-details + div.acc_holder')
  end

  it 'should have all panels expanded by default' do
    $panels.each do |panel|
      expect(panel).to have_css('.note_panel.show')
    end

  end

  it 'should collapse then expand all panels on button clicks' do
    accordion_toggle_btn = page.find('.upper-record-details + .acc_holder > a.acc_button')
    accordion_toggle_btn.click

    $panels.each do |panel|
      expect(panel).to_not have_css('.note_panel.show', visible: :hidden)
    end

    accordion_toggle_btn.click

    $panels.each do |panel|
      expect(panel).to have_css('.note_panel.show', visible: true)
    end

  end

end
