require 'spec_helper'

describe Search do

  let(:repo) {
    create(:repo)
  }

  let(:aq_notes) {
    build(:json_advanced_query,
          query: build(:json_field_query,
                       field: 'notes',
                       value: 'foobar',
                       literal: false,
                       comparator: 'contains',
                       negated: false))
  }

  let(:params) {
    {
      aq: aq_notes,
      "q.op": "AND",
      page: 1,
      page_size: 1
    }
  }

  it "can build a url for solr to search the notes field" do
    allow(Solr).to receive(:search) { |solr_query|
      solr_url = solr_query.to_solr_url
      params = URI.decode_www_form(solr_url.query)
      expect(params.find {|param| param.first == 'q'}[1]).to eq "notes:(foobar)"
      expect(params.find {|param| param.first == 'qf'}[1]).to match /fullrecord$/
    }

    Search.search(params, repo.id)
  end

  it "can build a url for solr to search the notes field while protecting unpublished data from the public user" do
    allow(Solr).to receive(:search) { |solr_query|
      solr_url = solr_query.to_solr_url
      params = URI.decode_www_form(solr_url.query)
      expect(params.find {|param| param.first == 'q'}[1]).to eq "notes_published:(foobar)"
      expect(params.find {|param| param.first == 'qf'}[1]).to match /fullrecord_published/
    }
    as_test_user(User.PUBLIC_USERNAME) do
      Search.search(params, repo.id)
    end
  end
end
