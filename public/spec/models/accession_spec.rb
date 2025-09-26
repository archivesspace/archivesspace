require "spec_helper"

describe Accession, type: :model do

  it "keeps deaccession data if AppConfig[:pui_display_deaccessions] = true" do
    allow(AppConfig).to receive(:[]).with(:pui_display_deaccessions) { true }
    solr_result = { "title" => "Accession",
                    "primary_type" => "accession",
                    "json" => build(:json_accession,
                                    title: "Accession",
                                    deaccessions: [build(:json_deaccession)]).to_hash,
                    "uri"=> "/accessions/99" }
    accession = Accession.new(solr_result)
    expect(accession.deaccessions.first['description']).not_to be_empty
  end

  it "removes deaccession data if AppConfig[:pui_display_deaccessions] = false" do
    allow(AppConfig).to receive(:[]).with(:pui_display_deaccessions) { false }
    solr_result = { "title" => "Accession",
                    "primary_type" => "accession",
                    "json" => build(:json_accession,
                                    title: "Accession",
                                    deaccessions: [build(:json_deaccession)]).to_hash,
                    "uri"=> "/accessions/99" }
    accession = Accession.new(solr_result)
    expect(accession.deaccessions.first['description']).to be_nil
  end
end
