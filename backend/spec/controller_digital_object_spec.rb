require 'spec_helper'

describe 'Digital Objects controller' do

  before(:each) do
    create(:repo)
  end


  def create_digital_object(extra_values = {})
    digital_object = JSONModel(:digital_object).from_hash({"title" => "a digital object",
                                                          "digital_object_id" => "abc123",
                                                          "extents" => [{
                                                                          "portion" => "whole",
                                                                          "number" => "5 or so",
                                                                          "extent_type" => "reels"
                                                                        }]}.merge(extra_values))
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

    $moo = true
    tree = JSONModel(:digital_object_tree).find(nil, :digital_object_id => digital_object.id)
    $moo = false

    tree.to_hash.should eq({
                             "jsonmodel_type" => "digital_object_tree",
                             "digital_object_component" => docs[0].uri,
                             "title" => "digital object component: earth",
                             "children" => [
                                            {
                                              "jsonmodel_type" => "digital_object_tree",
                                              "digital_object_component" => docs[1].uri,
                                              "title" => "digital object component: australia",
                                              "children" => [
                                                             {
                                                               "jsonmodel_type" => "digital_object_tree",
                                                               "digital_object_component" => docs[2].uri,
                                                               "title" => "digital object component: canberra",
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
      "children" => [
                     {
                       "jsonmodel_type" => "digital_object_tree",
                       "digital_object_component" => docs[1].uri,
                       "title" => "digital object component: australia",
                       "children" => [
                                      {
                                        "jsonmodel_type" => "digital_object_tree",
                                        "digital_object_component" => docs[0].uri,
                                        "title" => "digital object component: earth",
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

  it "lets you create a digital object and link an agent" do
    agent = JSONModel(:agent_person).
      from_hash("agent_type" => "agent_person",
                "names" => [{
                              "rules" => "local",
                              "primary_name" => "Magus Magoo",
                              "sort_name" => "Magoo, Mr M",
                              "direct_order" => "standard"
                            }])

    agent.save

    id = create_digital_object({
      "linked_agents" => [{
        "ref" => agent.uri,
        "role" => "creator"
      }]
    })

    obj = JSONModel(:digital_object).find(id, "resolve[]" => "ref")
    obj["linked_agents"].length.should eq(1)
    obj["linked_agents"][0]["role"].should eq("creator")
    obj["linked_agents"][0]["resolved"]["ref"]["names"][0]["sort_name"].should eq("Magoo, Mr M")
  end

end
