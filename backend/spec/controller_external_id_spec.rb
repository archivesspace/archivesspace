require 'spec_helper'

describe "External ID controller" do

  it "can return an object by its external id" do
    opts = {:title => "A boring old title",
      :external_ids => [{"external_id" => "my_magic_id", "source" => "this test"}]}
    acc = create(:json_accession, opts)
    JSONModel(:accession).find(acc.id).title.should eq(opts[:title])

    Solr.stub(:search) { {"total_hits" => 1, "results" => [ {"uri" => acc.uri} ] } }

    get '/by-external-id', params = { "eid" => "my_magic_id"}
    last_response.status.should eq(303)
    last_response.header['Location'].should eq(acc.uri)  
  end

  
  it "can return a list of objects that have an external id" do
    opts = {:title => "A boring old title",
      :external_ids => [{"external_id" => "my_magic_id", "source" => "this test"}]}
    acc = create(:json_accession, opts)
    JSONModel(:accession).find(acc.id).title.should eq(opts[:title])

    ao = create(:json_archival_object, opts)
    JSONModel(:archival_object).find(ao.id).title.should eq(opts[:title])


    Solr.stub(:search) { {"total_hits" => 2,
                          "results" => [ {"uri" => acc.uri}, {"uri" => ao.uri} ] } }

    get '/by-external-id', params = { "eid" => "my_magic_id"}
    last_response.status.should eq(300)
    resp_body = JSON(last_response.body)
    resp_body.length.should eq(2)
    resp_body[0].should eq(acc.uri)
    resp_body[1].should eq(ao.uri)
  end
  

  it "returns a 404 if a requested external id is not in use" do
    Solr.stub(:search) { {"total_hits" => 0, "results" => [] } }

    get '/by-external-id', params = { "eid" => "my_magic_id"}
    last_response.status.should eq(404)
  end

end
