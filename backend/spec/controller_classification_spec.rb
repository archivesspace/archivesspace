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
    expect(term.title).to eq("classification A")

    tree = JSONModel(:classification_tree).find(nil,
                                                :classification_id => classification.id)

    expect(tree['children'].count).to eq(1)
    expect(tree['children'].first['title']).to eq(term.title)
    expect(tree['children'].first['record_uri']).to eq(term.uri)

    second_term = create_classification_term(classification,
                                             :title => "child of the last term",
                                             :identifier => "another",
                                             :parent => {'ref' => term.uri})

    tree = JSONModel(:classification_tree).find(nil, :classification_id => classification.id)

    expect(tree['children'][0]['children'][0]['title']).to eq(second_term.title)
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
    }.not_to raise_error

    expect { JSONModel(:classification_term).find(term1.id) }.to raise_error(RecordNotFound)
    expect { JSONModel(:classification_term).find(term2.id) }.to raise_error(RecordNotFound)
  end


  it "lets you reorder classification terms" do
    classification = create(:json_classification)

    term_1 = create(:json_classification_term, :classification => {:ref => classification.uri}, :title=> "TERM1", :position => 0)
    create(:json_classification_term, :classification => {:ref => classification.uri}, :title=> "TERM2", :position => 1)

    tree = JSONModel(:classification_tree).find(nil, :classification_id => classification.id)

    expect(tree.children[0]["title"]).to eq("TERM1")
    expect(tree.children[1]["title"]).to eq("TERM2")

    term_1 = JSONModel(:classification_term).find(term_1.id)
    term_1.position = 1
    term_1.save

    tree = JSONModel(:classification_tree).find(nil, :classification_id => classification.id)

    expect(tree.children[0]["title"]).to eq("TERM2")
    expect(tree.children[1]["title"]).to eq("TERM1")
  end

end
