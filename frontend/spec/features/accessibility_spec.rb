require 'spec_helper.rb'
require 'rails_helper.rb'

describe 'Accessibility', js: true , db: 'accessibility' do

  it 'sets the selected state on sidebar elements' do
    visit '/'
    fill_in "username", with: "admin"
    fill_in "password", with: "admin"

    click_button "Sign In"
    page.has_no_xpath? "//input[@id='login']"

    visit "/resources/1"

    page.has_css? "div#archivesSpaceSidebar"

    within "div#archivesSpaceSidebar" do
      tablist = find "ul.as-nav-list"

      expect(tablist).to have_xpath "self::ul[@role='tablist']"
      expect(tablist).not_to have_xpath "li[@role='tab'][@aria-selected='true']"

      find("li.sidebar-entry-resource_extents_ a").click
      expect(tablist).to have_xpath("li[@role='tab'][@aria-selected='true']/a[@href='#resource_extents_']")

      find("li.sidebar-entry-resource_dates_ a").click
      expect(tablist).to have_xpath("li[@role='tab'][@aria-selected='true']/a[@href='#resource_dates_']")
      expect(tablist).to have_no_xpath("li[@role='tab'][@aria-selected='true']/a[@href='#resource_extents_']")
    end
  end

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

      expect(prev_th).to have_xpath "self::th[@role='button'][@aria-label='Previous']"
      expect(next_th).to have_xpath "self::th[@role='button'][@aria-label='Next']"
    end
  end
end
