require 'spec_helper'

describe 'Classification models' do

  let(:creator) { create(:json_agent_person) }

  def create_classification
    classification = build(:json_classification,
                           :title => "top-level classification",
                           :identifier => "abcdef",
                           :description => "A classification",
                           :creator => {'ref' => creator.uri})

    Classification.create_from_json(classification)
  end


  def create_classification_term(parent, properties = {})
    term = build(:json_classification_term,
                 {
                   :title => "classification A",
                   :identifier => "class-a",
                   :description => "classification A",
                   :classification => {'ref' => parent.uri}
                 }.merge(properties))

    ClassificationTerm.create_from_json(term)
  end


  it "Allows a classification to be created" do
    classification = create_classification
    classification.title.should eq("top-level classification")
    Classification.to_jsonmodel(classification)['creator']['ref'].should eq(creator.uri)
  end


  it "Allows a tree of classification_terms to be created" do
    classification = create_classification

    term = create_classification_term(classification)
    term.title.should eq("classification A")

    classification.tree['children'].count.should eq(1)
    classification.tree['children'].first['title'].should eq(term.title)
    classification.tree['children'].first['record_uri'].should eq(term.uri)

    second_term = create_classification_term(classification,
                                             :title => "child of the last term",
                                             :identifier => "another",
                                             :parent => {'ref' => term.uri})

    classification.tree['children'][0]['children'][0]['title'].should eq(second_term.title)
  end

end
