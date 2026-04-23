require 'spec_helper.rb'
require 'rails_helper.rb'

describe 'Favicons', js: true do
  let(:svg) { 'link[rel="icon"][type="image/svg+xml"][href*="favicon-AS"]' }
  let(:png) { 'link[rel="alternate icon"][type="image/png"][href*="favicon-AS"]' }
  let(:apple) { 'link[rel="apple-touch-icon"][type="image/png"][href*="favicon-AS"]' }

  it 'are present by default as png and svg' do
    visit '/'
    expect(page).to have_css(png, visible: false)
    expect(page).to have_css(svg, visible: false)
    expect(page).to have_css(apple, visible: false)

    png_href = page.find(png, visible: false)[:href]
    svg_href = page.find(svg, visible: false)[:href]
    visit png_href
    visit svg_href
  end

  it 'are not present when configured as such' do
    allow(AppConfig).to receive(:[]).and_call_original
    allow(AppConfig).to receive(:[]).with(:pui_show_favicon) { false }
    visit '/'
    expect(page).to_not have_css(png, visible: false)
    expect(page).to_not have_css(svg, visible: false)
    expect(page).to_not have_css(apple, visible: false)
  end
end
