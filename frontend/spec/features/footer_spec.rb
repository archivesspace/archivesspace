require 'spec_helper.rb'
require 'rails_helper.rb'

describe 'Footer', js: true do
  let(:feedback_link) { '#aspaceFeedbackLink' }
  let(:archivesspace_home) { 'footer a[href="http://archivesspace.org"]' }

  it 'always shows the ArchivesSpace home link' do
    visit '/'
    expect(page).to have_css(archivesspace_home)
  end

  context 'when feedback_url is configured empty' do
    before do
      allow(AppConfig).to receive(:[]).and_call_original
      allow(AppConfig).to receive(:[]).with(:feedback_url) { '' }
    end

    it 'does not show the feedback link' do
      visit '/'
      expect(page).to have_css(archivesspace_home)
      expect(page).to_not have_css(feedback_link)
    end
  end

  context 'when feedback_url is set' do
    before do
      allow(AppConfig).to receive(:[]).and_call_original
      allow(AppConfig).to receive(:[]).with(:feedback_url) { 'https://archivesspace.org/contact' }
    end

    it 'shows the feedback link' do
      visit '/'
      expect(page).to have_css(archivesspace_home)
      expect(page).to have_css("#{feedback_link}[href='https://archivesspace.org/contact']")
    end
  end
end
