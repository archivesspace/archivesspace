require 'spec_helper.rb'
require 'rails_helper.rb'

describe 'Accessibility', js: true , db: 'accessibility' do

  it 'should have aria attributes on datepicker advance buttons' do
    visit '/'
    fill_in "username", with: "admin"
    fill_in "password", with: "admin"

    click_button "Sign In"
    page.has_no_xpath? "//input[@id='login']"

    visit "/resources/1/edit#tree::resource_1"

    page.has_no_css? ".datepicker"
    
    date_field = find "input#resource_dates__0__begin_.date-field.initialised"
    date_field.click
    
    page.has_css? ".datepicker"

    within ".datepicker" do
      prev_th = find ".datepicker-days thead > tr > th.prev"
      next_th = find ".datepicker-days thead > tr > th.next"
      
      expect(prev_th).to have_xpath "self::[@role='button'][@aria-label='Previous']"
      expect(next_th).to have_xpath "self::[@role='button'][@aria-label='Next']"
    end

  end

end
