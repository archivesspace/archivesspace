require 'spec_helper'
require 'rails_helper'

describe 'Facets', js: true do
  before(:each) do
    visit '/repositories/resources'
    expect(page).to have_css('#facets')
  end

  describe 'accessibility' do
    it 'is axe_clean' do
      expect(page).to be_axe_clean.within('#facets')
    end

    it 'includes record counts inside facet links for screen readers' do
      within '#facets' do
        expect(page).to have_css('dd a .record-count')
      end
    end
  end

  context 'More facets' do
    it 'are shown when a facet type has more than 5 facets' do
      expect(page).to have_selector('#language-facet .more-facets__controls')
      expect(page).to_not have_selector('#subject-facet .more-facets__controls')
    end

    it 'are shown/hidden on click with proper focus management' do
      more_btn = find('#language-facet .more-facets__more')
      more_facets = all('#language-facet .more-facets__facets', visible: false)
      less_btn = find('#language-facet .more-facets__less', visible: false)
      first_revealed_link = more_facets.first.find('a', visible: false)

      more_btn.click
      aggregate_failures 'more facets shown' do
        expect(more_btn).to_not be_visible
        more_facets.each { |facet| expect(facet).to be_visible }
        expect(less_btn).to be_visible
        expect(first_revealed_link).to eq(page.active_element)
      end

      less_btn.click
      aggregate_failures 'more facets hidden' do
        expect(more_btn).to be_visible
        more_facets.each { |facet| expect(facet).to_not be_visible }
        expect(less_btn).to_not be_visible
        expect(more_btn).to eq(page.active_element)
      end
    end
  end
end
