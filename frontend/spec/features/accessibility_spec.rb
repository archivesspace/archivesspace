require 'spec_helper'
require 'rails_helper'

describe 'Accessibility', js: true, db: 'accessibility' do

  before(:all) do
    run_indexer
  end

  before(:each) do
    login_admin
  end

  xit 'sets the selected state on sidebar elements' do
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

    xit 'should have aria attributes on datepicker advance buttons' do
      visit "/resources/1/edit#tree::resource_1"

      page.has_no_css? ".datepicker"

      datepicker_toggle = find "input#resource_dates__0__begin_.date-field.initialised + .input-group-append button"
      datepicker_toggle.click

      page.has_css? ".datepicker"

      within ".datepicker" do
        prev_th = find ".datepicker-days thead > tr > th.prev"
        next_th = find ".datepicker-days thead > tr > th.next"

        expect(prev_th).to have_xpath "self::th[@role='button'][@aria-label='Previous']"
        expect(next_th).to have_xpath "self::th[@role='button'][@aria-label='Next']"
      end
    end

    xit 'should have role=button on datepicker day, month and year selectors' do
      visit "/resources/1/edit#tree::resource_1"

      page.has_no_css? ".datepicker"

      datepicker_toggle = find "input#resource_dates__0__begin_.date-field.initialised + .input-group-append button"
      datepicker_toggle.click

      page.has_css? ".datepicker"

      within ".datepicker" do
        current_day = find "td.day.active"
        expect(current_day).to have_xpath "self::td[@role='button']"

        selection_bar = find ".datepicker-switch"
        selection_bar.click

        current_month = find "span.month.active"
        expect(current_month).to have_xpath "self::span[@role='button']"

        selection_bar = find ".datepicker-switch"
        selection_bar.click

        current_year = find "span.year.active"
        expect(current_year).to have_xpath "self::span[@role='button']"
      end
    end

    xit 'should open via keyboard' do
      visit "/resources/1/edit#tree::resource_1"

      page.has_no_css? ".datepicker"

      datepicker_toggle = find "input#resource_dates__0__begin_.date-field.initialised + .input-group-append button"
      datepicker_toggle.native.send_keys(:return)

      page.has_css? ".datepicker"
    end
  end

  context 'Advanced search' do

    xit 'sets the expanded state on advanced search dropdown' do
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

    xit 'advanced search form fields are in logical order in DOM' do
      visit '/'
      page.has_css? "div.repository-header"

      within "div.repository-header" do
        switcher = find "button.search-switcher"
        switcher.send_keys :tab

        # Doesn't tab down into hidden advanced search form
        expect(page.evaluate_script("document.activeElement.outerHTML")).to include("repository-label")

        # Expand advanced search and tab into it
        switcher.click
        last_button_in_navbar = find "a.context-help"
        last_button_in_navbar.send_keys :tab

        expect(page.evaluate_script("document.activeElement.classList[0]")).to include("advanced-search-row-op-input")
      end
    end

    xit 'advanced search form fields all have visible labels' do
      visit '/'
      page.has_css? "div.repository-header"

      within "div.repository-header" do
        switcher = find "button.search-switcher"
        switcher.click

        expect(page).to be_axe_clean.checking_only :'label-title-only'
      end
    end

    xit 'expands and dismisses repository popover with keyboard alone' do
      visit '/'
      page.has_css? "div.repository-header"

      within "div.repository-header" do
        expect(page).not_to have_xpath("*//span[starts-with(@aria-describedby,'popover')]")
        repo = find "span.repository-label"
        repo.send_keys ''
        expect(page).to have_xpath("*//span[starts-with(@aria-describedby,'popover')]")

        repo.send_keys :escape
        expect(page).not_to have_xpath("*//span[starts-with(@aria-describedby,'popover')]")
      end
    end
  end

  context "resource toolbar" do

    # 519098
    xit "does not have any <a> tags without a @href attributes" do
      visit "/resources/1"
      page.has_css? "div.record-toolbar"
      expect(page).to have_no_xpath("//a[not(@href)]")
    end

    # 519100, #519357
    xit "supports aria-expanded for event and merge dropdowns" do
      visit "/resources/1"
      page.has_css? "div.record-toolbar"

      within "div.record-toolbar" do
        ["#add-event-dropdown button.add-event-action",
         "#merge-dropdown button.merge-action",
         "#transfer-dropdown button.transfer-action"].each do |css|
          eval("expect(page).to have_css(\"#{css}[aria-expanded='false']\")")
          sleep(1)
          find(css).click
          find("#{css}[aria-expanded='true']")
          eval("expect(page).to have_css(\"#{css}[aria-expanded='true']\")")
          find(css).click
          find("#{css}[aria-expanded='false']")
          eval("expect(page).to have_css(\"#{css}[aria-expanded='false']\")")
        end

        # #merge-dropdown a.dropdown-toggle is inside the merge menu, so we need to drop that down first so the target element is visible
        find("#merge-dropdown button.merge-action").click

        dropdown_ctrl = find("#merge-dropdown #form_merge .dropdown-toggle")

        expect(dropdown_ctrl).to have_xpath("self::*[@aria-expanded='false']")
        dropdown_ctrl.click
        expect(dropdown_ctrl).to have_xpath("self::*[@aria-expanded='true']")
        dropdown_ctrl.click
        expect(dropdown_ctrl).to have_xpath("self::*[@aria-expanded='false']")
      end
    end

    # 519346
    # it "conveys purpose of the control through programmatic label" do
    # end

    # 519349
    # it "has acceptable color contrast in dropdowns" do
    # end

    # 519350
    # see https://www.w3.org/TR/wai-aria-1.1/#combobox
    # also see: https://github.com/archivesspace/archivesspace/commit/9bcb1a8884c2a9f8d4d82a67b114b016fa3d0c2c

    # 519344
    xit "has visual labels for add event dropdown" do
      visit "/resources/1"

      using_wait_time(15) do
        expect(page).to have_selector("#add-event-dropdown", visible: true)
      end

      within "#add-event-dropdown" do
        find("button.add-event-action").click
        expect(page).to have_xpath("//select[@id='add_event_event_type']")
        expect(page).not_to have_css("label.sr-only")
        expect(page).to have_xpath("//label[@for='add_event_event_type']")
      end
    end

    # 519396
    xit "sets role as none for ul element in merge dropdown" do
      visit "/resources/1"

      using_wait_time(15) do
        expect(page).to have_selector('#merge-dropdown', visible: true)
      end

      within "#merge-dropdown" do
        find(" button.merge-action").click
        expect(page).to have_css("ul[role='none']")
      end
    end

    # # 519396
    xit "sets role as none for ul element in transfer dropdown" do
      visit "/resources/1"

      using_wait_time(15) do
        expect(page).to have_selector('#transfer-dropdown', visible: true)
      end

      within "#transfer-dropdown" do
        find("button.transfer-action").click
        expect(page).to have_css("ul[role='none']")
      end
    end

    xit "has role and aria attributes for the merge dropdown combobox" do
      visit "/resources/1"

      using_wait_time(15) do
        expect(page).to have_selector('div#merge-dropdown', visible: true)
      end

      within "div#merge-dropdown" do
        find("button.merge-action").click
        page.has_css?("ul.merge-form")
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

  describe "color contrast" do

    # 518792, 520876, 522397, 519342, 522396, 519349
    xit "has acceptable color contrast in placeholders" do
       # untestable: axe testing gem is not capable of choosing colors in CSS
    end

    # 519486, #519494
    xit "has acceptable color contrast in the datepicker" do
      visit "/resources/1/edit"

      using_wait_time(15) do
        expect(page).to have_selector('h2', visible: true)
      end

      datepicker_toggle = find "input#resource_dates__0__begin_.date-field.initialised + .input-group-append button"
      datepicker_toggle.click

      expect(page).to be_axe_clean.checking_only :'color-contrast'
    end

    # 521639, 521325, 523750, 519045, 518914, 523671, 520640, 519498, 523670
    xit "has acceptable color contrast for active menu dropdowns" do
      visit "/resources/1/edit"

      using_wait_time(15) do
        expect(page).to have_selector('.sidebar-entry-resource_linked_agents_', visible: true)
      end

      find(".sidebar-entry-resource_linked_agents_ a").click
      within "#resource_linked_agents_" do
        find(".alert-too-many").click
        click_button "Add Agent Link"
        agent_subrecords = find_all("li.linked_agent_initialised")
        within agent_subrecords.last do
          dropdown_button = find(".linker-wrapper .input-group-append > .dropdown-toggle")
          dropdown_button.click
          expect(page).to be_axe_clean.checking_only :'color-contrast'
        end
      end
    end

    # 523686, 523750, 523684,523683
    xit "has acceptable color contrast in the linkers" do
      visit "/resources/1/edit"

      using_wait_time(15) do
        expect(page).to have_selector('.sidebar-entry-resource_linked_agents_', visible: true)
      end

      find(".sidebar-entry-resource_linked_agents_ a").click
      within "#resource_linked_agents_" do
        find(".alert-too-many").click
        click_link "Add Agent Link"
        agent_subrecords = find_all("li.linked_agent_initialised")
        within agent_subrecords.last do
          field = find("input[role='searchbox']")
          field.send_keys "a"
          within "ul[role='listbox']" do
            expect(page).to be_axe_clean.checking_only :'color-contrast'
          end
        end
      end
    end

    # 523681
    xit "has acceptable color contrast for active textarea and input boxes" do
      visit "/resources/1/edit"

      using_wait_time(15) do
        expect(page).to have_selector('h2', visible: true)
      end

      date_field = find "textarea#resource_repository_processing_note_"
      date_field.click

      expect(page).to be_axe_clean.checking_only :'color-contrast'
    end

    # 523636, 523634, 523633, 523632, 523631, 523630, 523629, 523628, 523627, 523637, 523635
    xit "has acceptable color contrast in disabled buttons" do
      visit "/enumerations?id=14"
      expect(page).to be_axe_clean.checking_only :'color-contrast'
    end

    # 518955, 519449, 521318, 523762, 518915, 522650, 519400, 522670
    # 523750, 523751, 519035, 523540, 523680, 522581, 519418, 523679
    xit "has acceptable color contrast for tree expand/collapse button, drag & drop image, form element borders and required field indicators" do
      visit "/resources/1/edit"
      expect(page).to be_axe_clean.checking_only :'color-contrast'
    end
  end
end # of main describe
