# frozen_string_literal: true

require 'rails'
require 'spec_helper'
require 'rails_helper'

describe SearchController, type: :controller do
  before(:all) do
    @repo = create(:repo, repo_code: "search_listing_test_#{Time.now.to_i}")

    set_repo @repo

    50.times { |i|
      create(:accession, title: "Accession #{i}")
    }

    50.times { |i|
      @resource = create(:resource, title: "Resource #{i}")
      3.times { |i|
        create(:archival_object, title: "Archival Object #{i}", resource: { ref: @resource.uri })
      }
    }

    50.times { |i|
      create(:digital_object, title: "Independent DO #{i}")
    }

    run_all_indexers
  end

  xit 'returns search results in under 15 milliseconds' do
    expect {
      get :do_search
    }.to perform_under(15).ms
  end

  it 'returns search results with extra columns correctly' do
    expect(
      get(:do_search, {'extra_columns': [{'title' => 'uri', 'field' => 'uri', 'formatter' => 'stringify', 'sort_options' => {'sortable' => true, 'sort_by' => 'uri'}}]})
    ).to have_http_status(200)
  end

  let(:record) do
    {
      'collection_display_string_stored_u_ssort' => 'Good Papers,Bad Papers,Indifferent papers',
      'collection_display_string_u_sstr' => ['Good Papers', 'Bad Papers, Indifferent Papers'],
      'collection_identifier_stored_u_sstr' => ['COLL 1', 'COLL 2', 'COLL 3'],
      'type_u_ssort' => 'Box'
    }
  end

  it "formats 'stringify' extra columns in records correctly" do
    expect(SearchController::Formatter['stringify', 'type_u_ssort'].call(record)).to eq('Box')
  end

  it "formats 'linked_records_listing' extra columns in records correctly" do
    expect(SearchController::Formatter['linked_records_listing', 'collection_display_string_u_sstr'].call(record)).to eq(<<-HTML)
<ul class="linked-records-listing count-3"><li><span class="collection-identifier">Good Papers</span></li><li><span class="collection-identifier">Bad Papers</span></li><li><span class="collection-identifier">Indifferent Papers</span></li></ul>
HTML
  end

  it "formats 'combined_identifier' extra columns in records correctly" do
    expect(SearchController::Formatter['combined_identifier', 'field_not_actually_used'].call(record)).to eq(<<-HTML)
<ul class="linked-records-listing count-3"><li><span class="collection-identifier">COLL 1</span> <span class="collection-display-string">Good Papers</span></li><li><span class="collection-identifier">COLL 2</span> <span class="collection-display-string"> Bad Papers</span></li><li><span class="collection-identifier">COLL 3</span> <span class="collection-display-string"> Indifferent Papers</span></li></ul>
HTML
  end

end
