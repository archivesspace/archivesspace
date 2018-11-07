require 'spec_helper'
require 'rails_helper'

describe 'Accessibility' do
  before (:each) do
    visit('/')
  end
  context 'Welcome page' do
    it 'should not skip a heading level' do
      expect(page).to have_css('h3') if page.has_css? 'h4'
      expect(page).to have_css('h2') if page.has_css? 'h3'
      expect(page).to have_css('h1') if page.has_css? 'h2'
    end
    # it 'should follow WACG2a and section508' do
    #   expect(page).to be_accessible.according_to :wcag2a, :section508
    # end
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
    # it 'should follow WACG2a and section508' do
    #   expect(page).to be_accessible.according_to :wcag2a, :section508
    # end
    context 'individual repository page' do
      before (:each) do
        first("a[class='record-title']").click
      end
      # it 'should follow WACG2a and section508' do
      #   expect(page).to be_accessible.according_to :wcag2a, :section508
      # end
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
    # it 'should follow WACG2a and section508' do
    #   expect(page).to be_accessible.according_to :wcag2a, :section508
    # end
    context 'individual resource page' do
      it 'should not skip a heading level' do
        expect(page).to have_css('h3') if page.has_css? 'h4'
        expect(page).to have_css('h2') if page.has_css? 'h3'
        expect(page).to have_css('h1') if page.has_css? 'h2'
      end
      # it 'should follow WACG2a and section508' do
      #   first("a[class='record-title']").click
      #   expect(page).to be_accessible.according_to :wcag2a, :section508
      # end
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
    # it 'should follow WACG2a and section508' do
    #   expect(page).to be_accessible.according_to :wcag2a, :section508
    # end
    context 'individual digital materials page' do
      it 'should not skip a heading level' do
        expect(page).to have_css('h3') if page.has_css? 'h4'
        expect(page).to have_css('h2') if page.has_css? 'h3'
        expect(page).to have_css('h1') if page.has_css? 'h2'
      end
      # it 'should follow WACG2a and section508' do
      #   first("a[class='record-title']").click
      #   expect(page).to be_accessible.according_to :wcag2a, :section508
      # end
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
    # it 'should follow WACG2a and section508' do
    #   expect(page).to be_accessible.according_to :wcag2a, :section508
    # end
    context 'individual accession page' do
      it 'should not skip a heading level' do
        expect(page).to have_css('h3') if page.has_css? 'h4'
        expect(page).to have_css('h2') if page.has_css? 'h3'
        expect(page).to have_css('h1') if page.has_css? 'h2'
      end
      # it 'should follow WACG2a and section508' do
      #   first("a[class='record-title']").click
      #   expect(page).to be_accessible.according_to :wcag2a, :section508
      # end
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
    # it 'should follow WACG2a and section508' do
    #   expect(page).to be_accessible.according_to :wcag2a, :section508
    # end
    context 'individual subject page' do
      it 'should not skip a heading level' do
        expect(page).to have_css('h3') if page.has_css? 'h4'
        expect(page).to have_css('h2') if page.has_css? 'h3'
        expect(page).to have_css('h1') if page.has_css? 'h2'
      end
      # it 'should follow WACG2a and section508' do
      #   first("a[class='record-title']").click
      #   expect(page).to be_accessible.according_to :wcag2a, :section508
      # end
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
    # it 'should follow WACG2a and section508' do
    #   expect(page).to be_accessible.according_to :wcag2a, :section508
    # end
    context 'individual name page' do
      it 'should not skip a heading level' do
        expect(page).to have_css('h3') if page.has_css? 'h4'
        expect(page).to have_css('h2') if page.has_css? 'h3'
        expect(page).to have_css('h1') if page.has_css? 'h2'
      end
      # it 'should follow WACG2a and section508' do
      #   first("a[class='record-title']").click
      #   expect(page).to be_accessible.according_to :wcag2a, :section508
      # end
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
    # it 'should follow WACG2a and section508' do
    #   expect(page).to be_accessible.according_to :wcag2a, :section508
    # end
    context 'individual record group page' do
      it 'should not skip a heading level' do
        expect(page).to have_css('h3') if page.has_css? 'h4'
        expect(page).to have_css('h2') if page.has_css? 'h3'
        expect(page).to have_css('h1') if page.has_css? 'h2'
      end
      # it 'should follow WACG2a and section508' do
      #   first("a[class='record-title']").click
      #   expect(page).to be_accessible.according_to :wcag2a, :section508
      # end
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
    # it 'should follow WACG2a and section508' do
    #   expect(page).to be_accessible.according_to :wcag2a, :section508
    # end
  end
end
