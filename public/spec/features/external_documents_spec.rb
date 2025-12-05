require 'spec_helper'
require 'rails_helper'

describe 'External Documents', js: true do
  describe 'subject with external documents' do
    before do
      @subject = create(:subject, {
        publish: true,
        external_documents: [{
          title: "External Reference",
          location: "https://example.com",
          publish: true
        }]
      })

      run_indexers
    end

    it 'opens external document links in new tab with icon' do
      visit @subject.uri

      link = find('a[href="https://example.com"]')

      expect(link['target']).to eq('_blank')
      expect(link['rel']).to eq('noopener noreferrer')

      expect(link).to have_css('i.fa.fa-external-link')
    end
  end
end
