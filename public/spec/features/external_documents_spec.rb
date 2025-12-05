require 'spec_helper'
require 'rails_helper'

describe 'External Documents', js: true do
  describe 'resource with external document URI' do
    before do
      @resource = create(:resource_with_external_document, {
        publish: true,
        external_documents: [build(:external_document, {
          title: "External Reference",
          location: "https://example.com"
        })]
      })

      run_indexers
    end

    it 'opens external document links in new tab with icon' do
      visit @resource.uri

      aggregate_failures 'checking external document link' do
        link = find('a[href="https://example.com"]')

        expect(link['target']).to eq('_blank')
        expect(link['rel']).to eq('noopener noreferrer')

        expect(link).to have_css('i.fa.fa-external-link')
      end
    end
  end

  describe 'resource with external document text' do
    before do
      @resource = create(:resource_with_external_document, {
        publish: true,
        external_documents: [build(:external_document, {
          title: "Reference Guide",
          location: "See the reference guide for more information"
        })]
      })

      run_indexers
    end

    it 'displays plain text without link attributes or icon' do
      visit @resource.uri

      aggregate_failures 'checking plain text display without link attributes' do
        list_item = find('.external_docs li', text: "Reference Guide")

        expect(list_item).to have_content("Reference Guide")
        expect(list_item).not_to have_css('a')

        # Plain text should NOT have external link icon
        within '.external_docs' do
          expect(page).not_to have_css('i.fa.fa-external-link')
        end
      end
    end
  end
end
