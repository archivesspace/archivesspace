require 'spec_helper'

describe 'Classification models' do

  it "Allows a classification to be created" do
    creator = create(:json_agent_person)
    classification = build(:json_classification,
                           :title => "top-level classification",
                           :identifier => "abcdef",
                           :description => "A classification",
                           :creator => {'ref' => creator.uri})

    Classification.create_from_json(classification)
  end

end
