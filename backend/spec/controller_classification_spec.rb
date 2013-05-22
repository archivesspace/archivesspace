require 'spec_helper'

describe 'Classification controllers' do

  let(:creator) { create(:json_agent_person) }
  let(:classification) { create_classification }


  def create_classification
    create(:json_classification,
           :title => "top-level classification",
           :identifier => "abcdef",
           :description => "A classification",
           :creator => {'ref' => creator.uri})
  end


  def create_classification_term(parent, properties = {})
    create(:json_classification_term,
           {
             :title => "classification A",
             :identifier => "class-a",
             :description => "classification A",
             :classification => {'ref' => parent.uri}
           }.merge(properties))
  end


  it "allows a tree of classification_terms to be created" do
    term = create_classification_term(classification)
    term.title.should eq("classification A")

    tree = JSONModel(:classification_tree).find(nil,
                                                :classification_id => classification.id)

    tree['children'].count.should eq(1)
    tree['children'].first['title'].should eq(term.title)
    tree['children'].first['record_uri'].should eq(term.uri)

    second_term = create_classification_term(classification,
                                             :title => "child of the last term",
                                             :identifier => "another",
                                             :parent => {'ref' => term.uri})

    tree = JSONModel(:classification_tree).find(nil, :classification_id => classification.id)

    tree['children'][0]['children'][0]['title'].should eq(second_term.title)
  end


  it "can delete a classification tree" do
    term1 = create_classification_term(classification,
                                       :title => "same titles",
                                       :identifier => "same IDs")

    term2 = create_classification_term(classification,
                                       :title => "same titles",
                                       :identifier => "same IDs",
                                       :parent => {'ref' => term1.uri})

    expect {
      classification.delete
    }.to_not raise_error

    expect { JSONModel(:classification_term).find(term1.id) }.to raise_error(RecordNotFound)
    expect { JSONModel(:classification_term).find(term2.id) }.to raise_error(RecordNotFound)
  end

end
