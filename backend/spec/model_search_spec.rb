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
      fields: ["notes"],
      page: 1,
      page_size: 1
    }
  }

  let(:params_csv) {
    {
      aq: aq_notes,
      "q.op": "AND",
      fields: ["notes"],
      page: 1,
      page_size: 1,
      dt: "csv"
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

  context "when AppConfig[:limit_csv_fields] = false" do

    before do
      AppConfig[:limit_csv_fields] = false
    end

    it "includes fl for json data type query" do
      allow(Solr).to receive(:search) { |solr_query|
        solr_url = solr_query.to_solr_url
        params = URI.decode_www_form(solr_url.query)
        expect(params.find {|param| param.first == 'q'}[1]).to eq "notes:(foobar)"
        expect(params.find {|param| param.first == 'qf'}[1]).to match /fullrecord$/
        expect(params.find {|param| param.first == 'fl'}[1]).to eq "notes"
      }
      Search.search(params, repo.id)
    end

    it "excludes fl for csv data type query" do
      allow(Solr).to receive(:search) { |solr_query|
        solr_url = solr_query.to_solr_url
        params = URI.decode_www_form(solr_url.query)
        expect(params.find {|param| param.first == 'q'}[1]).to eq "notes:(foobar)"
        expect(params.find {|param| param.first == 'qf'}[1]).to match /fullrecord$/
        expect(params.find {|param| param.first == 'fl'}).to be_nil
      }
      Search.search(params_csv, repo.id)
    end
  end

  context "when AppConfig[:limit_csv_fields] = true" do

    before do
      AppConfig[:limit_csv_fields] = true
    end

    it "includes fl for json data type query" do
      allow(Solr).to receive(:search) { |solr_query|
        solr_url = solr_query.to_solr_url
        params = URI.decode_www_form(solr_url.query)
        expect(params.find {|param| param.first == 'q'}[1]).to eq "notes:(foobar)"
        expect(params.find {|param| param.first == 'qf'}[1]).to match /fullrecord$/
        expect(params.find {|param| param.first == 'fl'}[1]).to eq "notes"
      }
      Search.search(params, repo.id)
    end

    it "include fl for csv data type query" do
      allow(Solr).to receive(:search) { |solr_query|
        solr_url = solr_query.to_solr_url
        params = URI.decode_www_form(solr_url.query)
        expect(params.find {|param| param.first == 'q'}[1]).to eq "notes:(foobar)"
        expect(params.find {|param| param.first == 'qf'}[1]).to match /fullrecord$/
        expect(params.find {|param| param.first == 'fl'}[1]).to eq "notes"
      }
      Search.search(params_csv, repo.id)
    end
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
