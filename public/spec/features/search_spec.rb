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

    expect(page).to have_content('Showing Results')
    expect(page).to have_content('Published Accession')
    expect(page).to have_content('Published Accession with Deaccession')
    expect(page).to have_content('Accession for Phrase Search')
    expect(page).to have_content('Accession with Relationship')
    expect(page).to have_content('Accession with Deaccession')
    expect(page).to have_content('Accession with Lang/Script')
    expect(page).to have_content('Accession with Lang Material Note')
    expect(page).to have_content('Accession without Lang Material Note')
    expect(page).to have_content('Published Resource')
    expect(page).to have_content('Resource with Deaccession')

    find('#sort').select("Identifier (descending)")

    click_on('Sort')

    expect(page).to have_content('Digital Object 5')
    expect(page).to have_content('Digital Object 4')
    expect(page).to have_content('Digital Object 3')
    expect(page).to have_content('Digital Object 2')
    expect(page).to have_content('Digital Object With Classification')
    expect(page).to have_content('Digital Object 1')
    expect(page).to have_content('Born digital')
    expect(page).to have_content('Resource with digital instance')
    expect(page).to have_content('Resource with scope note')
    expect(page).to have_content('Resource with Subject')
  end
end
