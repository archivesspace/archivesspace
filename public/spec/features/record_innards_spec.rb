require 'spec_helper'
require 'rails_helper'

describe 'Record innards', js: true do
  it 'should display when a scope note is inherited' do
    visit('/')
    click_link 'Collections'
    expect(current_path).to eq ('/repositories/resources')
    resource = first("a[class='record-title']", text: 'Resource with scope note')
    visit(resource['href'])
    click_link 'Collection Organization'
    finished_all_ajax_requests?
    res = first("div[id='record-number-0']")
    res_href = res.first("a")['href']
    first_ao = first("div[id='record-number-1']")
    first_ao_href = first_ao.first("a")['href']
    # Resource with scope note should not be prepended with "From the"
    visit(res_href)
    within '.upper-record-details' do
      expect(page).not_to have_css(".note-content", text: "From the")
    end
    # Archival object child of a resource with a scope note should be prepended with "From the"
    visit(first_ao_href)
    within '.upper-record-details' do
      expect(page).to have_css(".note-content", text: "From the")
    end
  end

  it 'should display subjects organized by type' do
    visit('/')
    click_link 'Collections'
    expect(current_path).to eq ('/repositories/resources')
    resource = first("a[class='record-title']", text: 'Resource with Subject')
    visit(resource['href'])
    expect(page).to have_content('Temporal')
    expect(page).to have_content('Term 1 -- Term 2')
  end
end
