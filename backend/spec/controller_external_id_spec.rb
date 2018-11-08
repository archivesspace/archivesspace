require 'spec_helper'

describe "External ID controller" do

  it "can return an object by its external id" do
    opts = {:title => "A boring old title",
      :external_ids => [{"external_id" => "my_magic_id", "source" => "this test"}]}
    acc = create(:json_accession, opts)
    expect(JSONModel(:accession).find(acc.id).title).to eq(opts[:title])

    Solr.stub(:search) { {"total_hits" => 1, "results" => [ {"uri" => acc.uri} ] } }

    get '/by-external-id', params = { "eid" => "my_magic_id"}
    expect(last_response.status).to eq(303)
    expect(last_response.header['Location']).to eq(acc.uri)
  end


  it "can return a list of objects that have an external id" do
    opts = {:title => "A boring old title",
      :external_ids => [{"external_id" => "my_magic_id", "source" => "this test"}]}
    acc = create(:json_accession, opts)
    expect(JSONModel(:accession).find(acc.id).title).to eq(opts[:title])

    ao = create(:json_archival_object, opts)
    expect(JSONModel(:archival_object).find(ao.id).title).to eq(opts[:title])


    Solr.stub(:search) { {"total_hits" => 2,
                          "results" => [ {"uri" => acc.uri}, {"uri" => ao.uri} ] } }

    get '/by-external-id', params = { "eid" => "my_magic_id"}
    expect(last_response.status).to eq(300)
    resp_body = JSON(last_response.body)
    expect(resp_body.length).to eq(2)
    expect(resp_body[0]).to eq(acc.uri)
    expect(resp_body[1]).to eq(ao.uri)
  end


  it "returns a 404 if a requested external id is not in use" do
    Solr.stub(:search) { {"total_hits" => 0, "results" => [] } }

    get '/by-external-id', params = { "eid" => "my_magic_id"}
    expect(last_response.status).to eq(404)
  end

end
