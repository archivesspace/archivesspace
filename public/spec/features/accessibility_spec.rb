require 'spec_helper'
require 'rails_helper'

describe 'Accessibility', js: true do
  before (:each) do
    visit('/')
  end

  context 'Welcome page' do
    it 'should not skip a heading level' do
      expect(page).to have_css('h3') if page.has_css? 'h4'
      expect(page).to have_css('h2') if page.has_css? 'h3'
      expect(page).to have_css('h1') if page.has_css? 'h2'
    end
  end

  context 'Repositories pages' do
    before (:each) do
      click_link 'Repositories'
    end

    it 'should not skip a heading level' do
      expect(page).to have_css('h3') if page.has_css? 'h4'
      expect(page).to have_css('h2') if page.has_css? 'h3'
      expect(page).to have_css('h1') if page.has_css? 'h2'
    end

    context 'individual repository page' do
      before (:each) do
        first("a[class='record-title']").click
      end

      it 'should not skip a heading level' do
        expect(page).to have_css('h3') if page.has_css? 'h4'
        expect(page).to have_css('h2') if page.has_css? 'h3'
        expect(page).to have_css('h1') if page.has_css? 'h2'
      end
    end
  end

  context 'Resources pages' do
    before (:each) do
      click_link 'Collections'
    end

    it 'should not skip a heading level' do
      expect(page).to have_css('h3') if page.has_css? 'h4'
      expect(page).to have_css('h2') if page.has_css? 'h3'
      expect(page).to have_css('h1') if page.has_css? 'h2'
    end

    context 'individual resource page' do
      it 'should not skip a heading level' do
        expect(page).to have_css('h3') if page.has_css? 'h4'
        expect(page).to have_css('h2') if page.has_css? 'h3'
        expect(page).to have_css('h1') if page.has_css? 'h2'
      end

      it 'should not duplicate ids' do
        # Collection Overview
        expect(page).to be_axe_clean.checking_only :'duplicate-id'

        # Collection Organization
        within all('.col-sm-12')[1] do
          first("a[class='record-title']").click
        end
        click_link 'Collection Organization'
        expect(page).to be_axe_clean.checking_only :'duplicate-id'

        # Container Inventory
        click_link 'Container Inventory'
        expect(page).to be_axe_clean.checking_only :'duplicate-id'
      end
    end
  end

  context 'Digital Materials pages' do
    before (:each) do
      click_link 'Digital Materials'
    end

    it 'should not skip a heading level' do
      expect(page).to have_css('h3') if page.has_css? 'h4'
      expect(page).to have_css('h2') if page.has_css? 'h3'
      expect(page).to have_css('h1') if page.has_css? 'h2'
    end

    context 'individual digital materials page' do
      it 'should not skip a heading level' do
        expect(page).to have_css('h3') if page.has_css? 'h4'
        expect(page).to have_css('h2') if page.has_css? 'h3'
        expect(page).to have_css('h1') if page.has_css? 'h2'
      end
    end
  end

  context 'Accessions pages' do
    before (:each) do
      click_link 'Unprocessed Material'
    end

    it 'should not skip a heading level' do
      expect(page).to have_css('h3') if page.has_css? 'h4'
      expect(page).to have_css('h2') if page.has_css? 'h3'
      expect(page).to have_css('h1') if page.has_css? 'h2'
    end

    context 'individual accession page' do
      it 'should not skip a heading level' do
        expect(page).to have_css('h3') if page.has_css? 'h4'
        expect(page).to have_css('h2') if page.has_css? 'h3'
        expect(page).to have_css('h1') if page.has_css? 'h2'
      end
    end
  end

  context 'Subjects pages' do
    before (:each) do
      click_link 'Subjects'
    end

    it 'should not skip a heading level' do
      expect(page).to have_css('h3') if page.has_css? 'h4'
      expect(page).to have_css('h2') if page.has_css? 'h3'
      expect(page).to have_css('h1') if page.has_css? 'h2'
    end

    context 'individual subject page' do
      it 'should not skip a heading level' do
        expect(page).to have_css('h3') if page.has_css? 'h4'
        expect(page).to have_css('h2') if page.has_css? 'h3'
        expect(page).to have_css('h1') if page.has_css? 'h2'
      end
    end
  end

  context 'Names pages' do
    before (:each) do
      click_link 'Names'
    end

    it 'should not skip a heading level' do
      expect(page).to have_css('h3') if page.has_css? 'h4'
      expect(page).to have_css('h2') if page.has_css? 'h3'
      expect(page).to have_css('h1') if page.has_css? 'h2'
    end

    context 'individual name page' do
      it 'should not skip a heading level' do
        expect(page).to have_css('h3') if page.has_css? 'h4'
        expect(page).to have_css('h2') if page.has_css? 'h3'
        expect(page).to have_css('h1') if page.has_css? 'h2'
      end
    end
  end

  context 'Record Groups pages' do
    before (:each) do
      click_link 'Record Groups'
    end

    it 'should not skip a heading level' do
      expect(page).to have_css('h3') if page.has_css? 'h4'
      expect(page).to have_css('h2') if page.has_css? 'h3'
      expect(page).to have_css('h1') if page.has_css? 'h2'
    end

    context 'individual record group page' do
      it 'should not skip a heading level' do
        expect(page).to have_css('h3') if page.has_css? 'h4'
        expect(page).to have_css('h2') if page.has_css? 'h3'
        expect(page).to have_css('h1') if page.has_css? 'h2'
      end
    end
  end

  context 'Search pages' do
    before (:each) do
      click_link 'Search The Archives'
    end

    it 'should not skip a heading level' do
      expect(page).to have_css('h3') if page.has_css? 'h4'
      expect(page).to have_css('h2') if page.has_css? 'h3'
      expect(page).to have_css('h1') if page.has_css? 'h2'
    end
  end
end

describe "Accessibility 2.0", js: true do

  it "marks visual lists as such", :db => 'accessibility' do
    visit "/repositories/5/resources/22"
    page.has_css? "div#tree-container"
    within "div#tree-container" do
      expect(page).to have_xpath("div[@role='list']")
      expect(page).to have_xpath("div[@role='list']/div[@role='listitem'][@id='resource_22']")
      first(".expandme-icon").click
      expect(page).to have_xpath("div[@role='list']/div[@role='list']/div[@role='list']/div[@role='listitem'][@id='archival_object_1856']")
    end
  end

  it "has visible labels in the main search form", :db => 'accessibility' do
    visit "/"
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

      first('.btn-default').click

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

  it "sets alt text correctly for main logo", :db => 'accessibility' do
    visit "/"
    expect(page).to have_xpath("//img[@class='logo' and @alt='ArchivesSpace - a community served by Lyrasis.']")
  end
end
