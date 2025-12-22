require 'spec_helper'
require 'rails_helper'

describe 'External Documents', js: true do
  before(:all) do
    @resource_with_uri = create(:resource_with_external_document, {
      publish: true,
      external_documents: [build(:external_document, {
        title: "External Reference",
        location: "https://example.com"
      })]
    })

    @resource_with_text = create(:resource_with_external_document, {
      publish: true,
      external_documents: [build(:external_document, {
        title: "Reference Guide",
        location: "See the reference guide for more information"
      })]
    })

    run_indexers
  end

  describe 'resource with external document URI' do
    it 'opens external document links in new tab with icon' do
      visit @resource_with_uri.uri

      aggregate_failures 'checking external document link' do
        within '#ext_doc_list' do
          link = find('a[href="https://example.com"]')

          expect(link['target']).to eq('_blank')
          expect(link['rel']).to eq('noopener noreferrer')

          expect(link).to have_css('i.fa.fa-external-link')
        end
      end
    end
  end

  describe 'resource with external document text' do
    it 'displays plain text without link attributes or icon' do
      visit @resource_with_text.uri

      aggregate_failures 'checking plain text display without link attributes' do
        within '#ext_doc_list' do
          expect(page).to have_content("Reference Guide")
          expect(page).not_to have_css('a')

          expect(page).not_to have_css('i.fa.fa-external-link')
        end
      end
    end
  end
end
