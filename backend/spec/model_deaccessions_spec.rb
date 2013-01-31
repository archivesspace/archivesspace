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

    Deaccession[deaccession[:id]].description.should eq("A description of this deaccession")
    Deaccession[deaccession[:id]].scope.should eq("part")
    Deaccession[deaccession[:id]].notification.should eq(0)
    Deaccession[deaccession[:id]].date.begin.should eq("2012-05-14")
  end

end
