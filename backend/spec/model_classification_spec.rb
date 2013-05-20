require 'spec_helper'

describe 'Classification models' do

  it "Allows a classification to be created" do
    creator = create(:json_agent_person)
    classification = build(:json_classification,
                           :title => "top-level classification",
                           :identifier => "abcdef",
                           :description => "A classification",
                           :creator => {'ref' => creator.uri})

    classification = Classification.create_from_json(classification)
    classification.title.should eq("top-level classification")
    Classification.to_jsonmodel(classification)['creator']['ref'].should eq(creator.uri)
  end

end
