require 'spec_helper'

describe 'Digital Objects controller' do

  def create_digital_object
    digital_object = JSONModel(:digital_object).from_hash("title" => "a digital object",
                                                          "digital_object_id" => "abc123",
                                                          "extents" => [{
                                                                          "portion" => "whole",
                                                                          "number" => "5 or so",
                                                                          "extent_type" => "reels"
                                                                        }])
    digital_object.save
  end


  it "lets you create a digital object and get it back" do
    id = create_digital_object

    JSONModel(:digital_object).find(id).title.should eq("a digital object")
  end


  it "lets you update a digital object" do
    id = create_digital_object

    digital_object = JSONModel(:digital_object).find(id)

    digital_object.title = "an updated digital object"
    digital_object.save

    JSONModel(:digital_object).find(id).title.should eq("an updated digital object")
  end


  it "lets you query the record tree of related digital object components" do

    digital_object = create(:json_digital_object)
    id = digital_object.id

    docs = []
    ["earth", "australia", "canberra"].each do |name|
      doc = create(:json_digital_object_component, {:title => "digital object component: #{name}"})
      if not docs.empty?
        doc.parent = {:ref => docs.last.uri}
      end

      doc.digital_object = {:ref => digital_object.uri}

      doc.save
      docs << doc
    end

    tree = JSONModel(:digital_object_tree).find(nil, :digital_object_id => digital_object.id).to_hash

    tree['children'][0]['record_uri'].should eq(docs[0].uri)
    tree['children'][0]['children'][0]['record_uri'].should eq(docs[1].uri)
  end


  it "allows a digital object to have multiple direct children" do
    digital_object = create(:json_digital_object)

    doc1 = build(:json_digital_object_component)
    doc2 = build(:json_digital_object_component)

    doc1.digital_object = {:ref => digital_object.uri}
    doc2.digital_object = {:ref => digital_object.uri}

    doc1.save
    doc2.save

    tree = JSONModel(:digital_object_tree).find(nil, :digital_object_id => digital_object.id)
    tree.children.length.should eq(2)
  end

end
