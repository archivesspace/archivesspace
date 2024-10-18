require 'spec_helper.rb'
require 'rails_helper.rb'

describe 'Favicons', js: true do
  let(:png) { 'link[rel="icon"][type="image/png"][href="/favicon-AS.png"]' }
  let(:svg) { 'link[rel="icon"][type="image/svg+xml"][href="/favicon-AS.svg"]' }

  it 'are present by default as png and svg' do
    visit '/'
    expect(page).to have_css(png, visible: false)
    expect(page).to have_css(svg, visible: false)
    visit '/favicon-AS.png'
    visit '/favicon-AS.svg'
  end

  it 'are not present when configured as such' do
    allow(AppConfig).to receive(:[]).and_call_original
    allow(AppConfig).to receive(:[]).with(:pui_show_favicon) { false }
    visit '/'
    expect(page).to_not have_css(png, visible: false)
    expect(page).to_not have_css(svg, visible: false)
  end
end
