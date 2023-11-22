require 'spec_helper'
require 'rails_helper'

describe 'Record innards', js: true do
  it 'should display when a scope note is inherited' do
    visit('/search?utf8=✓&op[]=&q[]="Resource+with+scope+note"&limit=resource&field[]=&from_year[]=&to_year[]=')
    resource = first("a[class='record-title']", text: 'Resource with scope note')
    visit(resource['href'])
    click_link 'Collection Organization'
    finished_all_ajax_requests?
    res = first("div[data-record-number='0']")
    res_href = res.first("a")['href']
    first_ao = first("div[data-record-number='1']")
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
end
