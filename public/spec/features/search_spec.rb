require 'spec_helper'
require 'rails_helper'

describe 'Search', js: true do
  it 'should go to the correct page' do
    visit('/')
    click_link 'Search The Archives'
    expect(current_path).to eq ('/search')
    finished_all_ajax_requests?
    within all('.col-sm-12')[0] do
      expect(page).to have_content('Search The Archives')
    end
  end

  it 'should use an asterisk for a keyword search when no inputs and search button pressed' do
    visit('/search')
    click_on('submit_search')
    expect(page).to have_selector("div[class='searchstatement']", text: "keyword(s): *")
  end

  it "should submit form, not delete row when search row is added and enter pressed in search field" do
    visit('/search')
    click_on('Add a search row')
    find('#q1').native.send_keys(:return)
    expect(page).to have_content('Showing Results')
  end

  it "should sort by identifier on results page" do
    visit('/search')
    click_on('Add a search row')
    find('#q1').native.send_keys(:return)

    find('#sort').select("Identifier (descending)")

    click_on('Sort')

    identifiers_desc = find_all('span.component').to_a

    expect(identifiers_desc[1].text > identifiers_desc[2].text).to be true
    expect(identifiers_desc[2].text > identifiers_desc[3].text).to be true
  end
end
