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



  it "lets you manipulate the record hierarchy" do

    digital_object = JSONModel(:digital_object).from_hash("title" => "a digital object",
                                                          "digital_object_id" => "abc123",
                                                          "extents" => [{
                                                                          "portion" => "whole",
                                                                          "number" => "5 or so",
                                                                          "extent_type" => "reels"
                                                                        }])
    id = digital_object.save

    docs = []
    ["earth", "australia", "canberra"].each do |name|
      doc = JSONModel(:digital_object_component).from_hash("ref_id" => name,
                                                           "component_id" => "id_for_#{name}",
                                                           "title" => "digital object component: #{name}")
      if not docs.empty?
        doc.parent = docs.last.uri
      end

      doc.digital_object = digital_object.uri
      doc.save
      docs << doc
    end

    tree = JSONModel(:digital_object_tree).find(nil, :digital_object_id => digital_object.id)

    tree.to_hash.should eq({
                             "jsonmodel_type" => "digital_object_tree",
                             "digital_object_component" => docs[0].uri,
                             "title" => "digital object component: earth",
                             "node_type" => "digital_object_component",
                             "children" => [
                                            {
                                              "digital_object_component" => docs[1].uri,
                                              "title" => "digital object component: australia",
                                              "node_type" => "digital_object_component",
                                              "children" => [
                                                             {
                                                               "digital_object_component" => docs[2].uri,
                                                               "title" => "digital object component: canberra",
                                                               "node_type" => "digital_object_component",
                                                               "children" => []
                                                             }
                                                            ]
                                            }
                                           ]
                           })


    # Now turn it on its head
    changed = {
      "jsonmodel_type" => "digital_object_tree",
      "digital_object_component" => docs[2].uri,
      "title" => "digital object component: canberra",
      "node_type" => "digital_object_component",
      "children" => [
                     {
                       "digital_object_component" => docs[1].uri,
                       "title" => "digital object component: australia",
                       "node_type" => "digital_object_component",
                       "children" => [
                                      {
                                        "digital_object_component" => docs[0].uri,
                                        "title" => "digital object component: earth",
                                        "node_type" => "digital_object_component",
                                        "children" => []
                                      }
                                     ]
                     }
                    ]
    }

    JSONModel(:digital_object_tree).from_hash(changed).save(:digital_object_id => digital_object.id)
    changed.delete("uri")

    tree = JSONModel(:digital_object_tree).find(nil, :digital_object_id => digital_object.id)

    tree.to_hash.should eq(changed)
  end


  it "allows a digital object to have multiple direct children" do
    digital_object = create(:json_digital_object)

    ao1 = build(:json_digital_object_component)
    ao2 = build(:json_digital_object_component)

    ao1.digital_object = digital_object.uri
    ao2.digital_object = digital_object.uri

    ao1.save
    ao2.save

    tree = JSONModel(:digital_object_tree).find(nil, :digital_object_id => digital_object.id)
    tree.children.length.should eq(2)
  end

end
