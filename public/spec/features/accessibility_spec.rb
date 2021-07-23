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
      before (:each) do
        within all('.col-sm-12')[1] do
          first("a[class='record-title']").click
        end
      end

      it 'should not skip a heading level' do
        expect(page).to have_css('h3') if page.has_css? 'h4'
        expect(page).to have_css('h2') if page.has_css? 'h3'
        expect(page).to have_css('h1') if page.has_css? 'h2'
      end

      it 'should support resizing sidebar with keyboard' do
        sidebar_width = find('div.sidebar').evaluate_script("window.getComputedStyle(this)['width']")
        handle = find('input.resizable-sidebar-handle')

        5.times do
          handle.native.send_keys :arrow_left
        end

        new_sidebar_width = find('div.sidebar').evaluate_script("window.getComputedStyle(this)['width']")
        expect(new_sidebar_width).to be > sidebar_width

        10.times do
          handle.native.send_keys :arrow_right
        end

        newest_sidebar_width = find('div.sidebar').evaluate_script("window.getComputedStyle(this)['width']")
        expect(newest_sidebar_width).to be < sidebar_width
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
