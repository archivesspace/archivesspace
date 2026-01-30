# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Skipnav accessibility', js: true do
  it 'has skip links present on pages' do
    visit '/'

    expect(page).to have_css('div.skipnav', visible: false)
    within '.skipnav' do
      expect(page).to have_link('Skip to main content', href: '#maincontent', visible: false)
    end
    expect(page).to have_css('#maincontent', visible: false)
  end
end
