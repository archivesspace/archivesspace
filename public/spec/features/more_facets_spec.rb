require 'spec_helper'
require 'rails_helper'

describe 'More Facets', js: true do
  before(:each) do
    visit '/repositories/resources'
  end

  it 'are shown when a facet type has more than 5 facets' do
    expect(page).to have_selector('#language-facet .more-facets')
    expect(page).to_not have_selector('#subject-facet .more-facets')
  end

  it 'are shown/hidden on click' do
    more_btn = find('#language-facet .more-facets__more')
    more_facets = find('#language-facet .more-facets__facets', visible: false)
    less_btn = find('#language-facet .more-facets__less', visible: false)

    more_btn.click

    expect(more_btn).to_not be_visible
    expect(more_facets).to be_visible
    expect(less_btn).to be_visible

    less_btn.click

    expect(more_btn).to be_visible
    expect(more_facets).to_not be_visible
    expect(less_btn).to_not be_visible
  end
end
