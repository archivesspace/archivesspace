require 'spec_helper'
require 'rails_helper'

describe 'Accessibility', js: true, db: 'accessibility' do
  before (:each) do
    visit('/')
    page.has_text? "Welcome to ArchivesSpace"
  end

  context 'Welcome page' do
    it "does not skip heading levels" do
      expect(page).to be_axe_clean.checking_only :'heading-order'
    end

    it "sets alt text correctly for main logo" do
      expect(page).to have_xpath("//img[@class='logo' and @alt='ArchivesSpace - a community served by Lyrasis.']")
    end

    it "has skip links that pass color contrast", :db => 'accessibility' do
      visit "/"
      page.has_css? 'div.skipnav'

      # Show the skiplink by giving it focus
      body = find "body"
      body.send_keys :tab

      expect(page).to be_axe_clean.checking_only :'color-contrast'
    end
  end

  context 'Repositories pages' do
    before (:each) do
      click_link 'Repositories'
    end

    it "does not skip heading levels" do
      expect(page).to be_axe_clean.checking_only :'heading-order'
    end

    context 'individual repository page' do
      before (:each) do
        first("a[class='record-title']").click
      end

      it "does not skip heading levels" do
        expect(page).to be_axe_clean.checking_only :'heading-order'
      end
    end
  end

  context 'Digital Materials pages' do
    before (:each) do
      click_link 'Digital Materials'
    end

    it "does not skip heading levels" do
      expect(page).to be_axe_clean.checking_only :'heading-order'
    end

    context 'individual digital materials page' do
      before (:each) do
        first("a[class='record-title']").click
      end

      it "does not skip heading levels" do
        expect(page).to be_axe_clean.checking_only :'heading-order'
      end
    end
  end

  context 'Accessions pages' do
    before (:each) do
      click_link 'Unprocessed Material'
    end

    it "does not skip heading levels" do
      expect(page).to be_axe_clean.checking_only :'heading-order'
    end

    context 'individual accession page' do
      before (:each) do
        first("a[class='record-title']").click
      end

      it "does not skip heading levels" do
        expect(page).to be_axe_clean.checking_only :'heading-order'
      end
    end
  end

  context 'Subjects pages' do
    before (:each) do
      click_link 'Subjects'
    end

    it "does not skip heading levels" do
      expect(page).to be_axe_clean.checking_only :'heading-order'
    end

    context 'individual subject page' do
      before (:each) do
        first("a[class='record-title']").click
      end

      it "does not skip heading levels" do
        expect(page).to be_axe_clean.checking_only :'heading-order'
      end
    end
  end

  context 'Names pages' do
    before (:each) do
      click_link 'Names'
    end

    it "does not skip heading levels" do
      expect(page).to be_axe_clean.checking_only :'heading-order'
    end

    context 'individual name page' do
      before (:each) do
        first("a[class='record-title']").click
      end

      it "does not skip heading levels" do
        expect(page).to be_axe_clean.checking_only :'heading-order'
      end
    end
  end

  context 'Record Groups pages' do
    before (:each) do
      click_link 'Record Groups'
    end

    it "does not skip heading levels" do
      expect(page).to be_axe_clean.checking_only :'heading-order'
    end

    context 'individual record group page' do
      before (:each) do
        first("a[class='record-title']").click
      end

      it "does not skip heading levels" do
        expect(page).to be_axe_clean.checking_only :'heading-order'
      end
    end
  end

  context 'Search pages' do
    before (:each) do
      click_link 'Search The Archives'
    end

    it "does not skip heading levels" do
      expect(page).to be_axe_clean.checking_only :'heading-order'
    end

    it "has visible labels in the main search form" do
      within "form#advanced_search" do
        expect(page).not_to have_css("label.sr-only")

        expect(page).to have_xpath("//label[@for='q0']")
        expect(page).to have_xpath("//input[@type='text'][@id='q0']")

        expect(page).to have_xpath("//label[@for='limit']")
        expect(page).to have_xpath("//select[@id='limit']")

        expect(page).to have_xpath("//label[@for='field0']")
        expect(page).to have_xpath("//select[@id='field0']")

        expect(page).to have_xpath("//label[@for='from_year0']")
        expect(page).to have_xpath("//input[@id='from_year0']")

        expect(page).to have_xpath("//label[@for='to_year0']")
        expect(page).to have_xpath("//input[@id='to_year0']")

        first('.btn.btn-light.border').click

        expect(page).to have_xpath("//label[@for='op1']")
        expect(page).to have_xpath("//select[@id='op1']")

        expect(page).to have_xpath("//label[@for='field1']")
        expect(page).to have_xpath("//select[@id='field1']")

        expect(page).to have_xpath("//label[@for='from_year1']")
        expect(page).to have_xpath("//input[@id='from_year1']")

        expect(page).to have_xpath("//label[@for='to_year1']")
        expect(page).to have_xpath("//input[@id='to_year1']")
      end
    end
  end

  # keep this at the end; it kills the server for some reason...
  context 'Resources pages' do
    before (:each) do
      click_link 'Collections'
    end

    it "does not skip heading levels" do
      expect(page).to be_axe_clean.checking_only :'heading-order'
    end

    context 'individual resource page' do
      before (:each) do
        first("a[class='record-title']").click
      end

      it "does not skip heading levels" do
        expect(page).to be_axe_clean.checking_only :'heading-order'
      end

      it 'should support resizing sidebar with keyboard' do
        visit '/repositories/5/resources/22'
        page.has_css? 'div.sidebar'

        sidebar_width = find('div.sidebar').evaluate_script("window.getComputedStyle(this)['width']")
        handle = find('input.resizable-sidebar-handle')

        5.times do
          handle.native.send_keys :arrow_left
        end

        new_sidebar_width = find('div.sidebar').evaluate_script("window.getComputedStyle(this)['width']")
        expect(new_sidebar_width).to be < sidebar_width

        10.times do
          handle.native.send_keys :arrow_right
        end

        newest_sidebar_width = find('div.sidebar').evaluate_script("window.getComputedStyle(this)['width']")
        expect(newest_sidebar_width).to be > sidebar_width
      end

      it 'should not duplicate ids' do
        # Collection Overview
        expect(page).to be_axe_clean.checking_only :'duplicate-id'

        # Collection Organization
        click_link 'Collection Organization'
        expect(page).to be_axe_clean.checking_only :'duplicate-id'

        # Container Inventory
        click_link 'Container Inventory'
        expect(page).to be_axe_clean.checking_only :'duplicate-id'
      end

      it "marks visual lists as such" do
        visit "/repositories/5/resources/22"
        page.has_css? "div#tree-container"
        within "div#tree-container" do
          expect(page).to have_xpath("div[@role='list']")
          expect(page).to have_xpath("div[@role='list']/div[@role='listitem'][@id='resource_22']")
          first(".expandme-icon").click
          expect(page).to have_xpath("div[@role='list']/div[@role='list']/div[@role='list']/div[@role='listitem'][@id='archival_object_1856']")
        end
      end
    end
  end
end
