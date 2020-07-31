require 'spec_helper'
require 'rails_helper'

describe 'Citation modal', js: true do
  it 'should be visible' do
    visit('/')
    click_link 'Collections'
    expect(current_path).to eq ('/repositories/resources')
    resource = first("a[class='record-title']", text: 'Resource with scope note')
    visit(resource['href'])
    within '.page_actions' do
      expect(page).to have_css('#cite_sub')
    end
  end


  it 'should default to item citation' do
    visit('/')
    click_link 'Collections'
    expect(current_path).to eq ('/repositories/resources')
    resource = first("a[class='record-title']", text: 'Resource with scope note')
    visit(resource['href'])
    within '.page_actions' do
      click_button('Citation')
    end
    within '#cite_modal' do
      active_tab = first('li.active')
      expect(active_tab).to have_selector('a', exact_text: 'Cite Item')
      expect(active_tab).not_to have_selector('a', exact_text: 'Cite Item Description')
      active_panel = first('p.active')
      expect(active_panel).not_to have_text('http')
    end
  end


  it 'should have functioning tab for item description citation' do
    visit('/')
    click_link 'Collections'
    expect(current_path).to eq ('/repositories/resources')
    resource = first("a[class='record-title']", text: 'Resource with scope note')
    visit(resource['href'])
    within '.page_actions' do
      click_button('Citation')
    end
    within '#cite_modal' do
      click_link('Cite Item Description')
      finished_all_ajax_requests?
      active_tab = first('li.active')
      expect(active_tab).to have_selector('a', exact_text: 'Cite Item Description')
      expect(active_tab).not_to have_selector('a', exact_text: 'Cite Item')
      active_panel = first('p.active')
      expect(active_panel).to have_text('http')
    end
  end

end
