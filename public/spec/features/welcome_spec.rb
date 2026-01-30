require 'spec_helper'
require 'rails_helper'

describe 'Welcome page', js: true do
  before (:each) do
    visit('/')
    page.has_text? "Welcome to ArchivesSpace"
  end

  it "does not skip heading levels" do
    expect(page).to be_axe_clean.checking_only :'heading-order'
  end

  it "sets alt text correctly for main logo" do
    expect(page).to have_xpath("//img[@class='logo' and @alt='ArchivesSpace - a community served by Lyrasis.']")
  end

  it "has skip links that pass color contrast" do
    visit "/"
    page.has_css? 'div.skipnav'

    # Show the skiplink by giving it focus
    body = find "body"
    body.send_keys :tab

    expect(page).to be_axe_clean.checking_only :'color-contrast'
  end

  it 'has a skip link anchor' do
    expect(page).to have_css('#maincontent[tabindex="-1"]', visible: :hidden)
  end
end
