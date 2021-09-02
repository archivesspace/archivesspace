require 'spec_helper.rb'
require 'rails_helper.rb'

describe 'Accessibility', js: true , db: 'accessibility' do

  before(:all) do
    PeriodicIndexer.new.run_index_round
  end

  before(:each) do
    visit '/'
    if page.has_xpath? "//input[@id='login']"

      within "form.login" do
        fill_in "username", with: "admin"
        fill_in "password", with: "admin"

        click_button "Sign In"
      end
    end

    page.has_no_xpath? "//input[@id='login']"
  end

  after(:each) do
    page.instance_variable_set(:@touched, false)
  end

  it 'sets the selected state on sidebar elements' do
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

  context 'Datepicker' do

    it 'should have aria attributes on datepicker advance buttons' do
      visit '/'

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

  context 'Advanced search' do

    it 'sets the expanded state on advanced search dropdown' do
      visit '/'
      page.has_css? "div.repository-header"

      within "div.repository-header" do
        switcher = find "button.search-switcher"

        expect(switcher).to have_xpath "self::button[@aria-expanded='false']"
        expect(switcher).not_to have_xpath "self::button[@aria-expanded='true']"

        switcher.click
        expect(switcher).to have_xpath "self::button[@aria-expanded='true']"
        expect(switcher).not_to have_xpath "self::button[@aria-expanded='false']"
      end
    end

    it 'advanced search form fields are in logical order in DOM' do
      visit '/'
      page.has_css? "div.repository-header"

      within "div.repository-header" do
        switcher = find "button.search-switcher"
        switcher.send_keys :tab

        # Doesn't tab down into hidden advanced search form
        expect(page.evaluate_script("document.activeElement.outerHTML")).to include("repository-label")

        # Expand advanced search and tab into it
        switcher.click
        switcher.send_keys :tab

        expect(page.evaluate_script("document.activeElement.classList[0]")).to include("advanced-search-row-op-input")
      end
    end

    it 'advanced search form fields all have visible labels' do
      visit '/'
      page.has_css? "div.repository-header"

      within "div.repository-header" do
        switcher = find "button.search-switcher"
        switcher.click

        expect(page).to be_axe_clean.checking_only :'label-title-only'
      end
    end

    it 'expands and dismisses repository popover with keyboard alone' do
      visit '/'
      page.has_css? "div.repository-header"

      within "div.repository-header" do
        expect(page).not_to have_xpath("*//div[starts-with(@id,'popover')]")
        repo = find "span.repository-label"
        repo.send_keys ''

        expect(page).to have_xpath("*//div[starts-with(@id,'popover')]")

        repo.send_keys :escape
        expect(page).not_to have_xpath("*//div[starts-with(@id,'popover')]")
      end
    end
  end

  context "resource toolbar" do

    # 519098
    it "does not have any <a> tags without a @href attributes" do
      visit "/resources/1"
      page.has_css? "div.record-toolbar"
      expect(page).to have_no_xpath("//a[not(@href)]")
    end

    # 519100
    it "supports aria-expanded for event and merge dropdowns" do
      visit "/resources/1"
      page.has_css? "div.record-toolbar"

      within "div.record-toolbar" do
        ["#add-event-dropdown button.add-event-action",
         "#merge-dropdown button.merge-action",
         "#transfer-dropdown button.transfer-action"].each do |css|
          dropdown_ctrl = find(css)
          expect(dropdown_ctrl).to have_xpath("self::*[@aria-expanded='false']")
          dropdown_ctrl.click
          expect(dropdown_ctrl).to have_xpath("self::*[@aria-expanded='true']")
          dropdown_ctrl.click
          expect(dropdown_ctrl).to have_xpath("self::*[@aria-expanded='false']")
        end
      end
    end

    # 519344
    it "has visual labels for add event dropdown" do
      visit "/resources/1"
      page.has_css? "div.record-toolbar"

      within "#add-event-dropdown" do
        find("button.add-event-action").click
        expect(page).to have_xpath("//select[@id='add_event_event_type']")
        expect(page).not_to have_css("label.sr-only")
        expect(page).to have_xpath("//label[@for='add_event_event_type']")
      end
    end

    # 519346
    it "conveys purpose of the control through programmatic label" do
      visit "/resources/1#tree::resource_1"
      # tbd / not sure what to do (if anything?)
    end

    # 519349
    it "has acceptable color contrast in dropdowns" do
      # tbd
    end

    # 519350
    # see https://www.w3.org/TR/wai-aria-1.1/#combobox
    # also see: https://github.com/archivesspace/archivesspace/commit/9bcb1a8884c2a9f8d4d82a67b114b016fa3d0c2c
    it "has role and aria attributes for the merge dropdown combobox" do
      visit "/resources/1"

      find("#merge-dropdown button.merge-action").click
      page.has_css?("ul.merge-form")

      within "div#merge-dropdown" do
        combobox = find("div[role='combobox']")
        combobox.assert_matches_selector("div[aria-expanded='false']")
        searchbox = find("input[role='searchbox']")
        searchbox.assert_matches_selector("input[type='text'][aria-multiline='false']")
        searchbox.fill_in with: 'a'
        combobox.assert_matches_selector("div[aria-expanded='true']")
        listbox = find("ul[role='listbox']")
        listbox.assert_matches_selector("div[role='combobox'] ul")
        searchbox.assert_matches_selector("input[aria-controls='merge_ref__listbox']")
      end
    end
  end

end
