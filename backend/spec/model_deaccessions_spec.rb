require 'spec_helper'

describe 'Deaccessions model' do

  it "Supports creating a new deaccession record" do
    deaccession = Deaccession.create_from_json(JSONModel(:deaccession).
                                               from_hash({
                                                           "scope" => "part",
                                                           "description" => "A description of this deaccession",
                                                           "date" => JSONModel(:date).from_hash("date_type" => "single",
                                                                                                "label" => "deaccession",
                                                                                                "begin" => "2012-05-14",
                                                                                                "end" => "2012-05-14"),
                                                         }))

    expect(Deaccession[deaccession[:id]].description).to eq("A description of this deaccession")
    expect(Deaccession[deaccession[:id]].scope).to eq("part")
    expect(Deaccession[deaccession[:id]].notification).to eq(0)
    expect(Deaccession[deaccession[:id]].date.begin).to eq("2012-05-14")
  end

end
