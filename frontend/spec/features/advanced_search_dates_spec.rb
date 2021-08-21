require 'date'
require 'spec_helper.rb'
require 'rails_helper.rb'

describe 'AdvancedSearchDates', js: true do

  before(:each) do
    visit '/'
    page.has_xpath? '//input[@id="login"]'

    within "form.login" do
      fill_in "username", with: "admin"
      fill_in "password", with: "admin"

      click_button "Sign In"
    end

    page.has_no_xpath? '//input[@id="login"]'

    page.has_css? 'button[title="Show Advanced Search"]'
    click_button('button[title="Show Advanced Search"]')
    click_link('.advanced-search-add-row-dropdown')
    click_link('.advanced-search-add-date-row')
    page.has_css? 'input#v1.date-field'

    date_field = find 'input#v1.date-field'
    submit_btn = find 'form.advanced-search .btn.btn-primary'

    now = DateTime.now
    year = now.strftime('%Y')
    month = now.strftime('%Y-%m')
    day = now.strftime('%Y-%m-%d')
  end

  it 'accepts a year date in yyyy format' do
    within "form.advanced-search" do
      date_field.fill_in(with: year)
      submit_btn.click
    end

    expect(page).to have_text 'Search Results'
  end

  it 'accepts a month date in yyyy-mm format' do
    within "form.advanced-search" do
      date_field.fill_in(with: month)
      submit_btn.click
    end

    expect(page).to have_text 'Search Results'
  end

  it 'accepts a day date in yyyy-mm-dd format' do
    within "form.advanced-search" do
      date_field.fill_in(with: day)
      submit_btn.click
    end

    expect(page).to have_text 'Search Results'
  end

end
