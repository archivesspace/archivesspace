require 'spec_helper'
require 'rails_helper'

describe 'Help tooltip default placement', js: true do
  it 'should be set to bottom' do
    login_admin
    visit '/resources/new'
    page.should have_css('.global-header a.context-help.has-tooltip.initialised[data-placement="bottom"]')
  end
end
