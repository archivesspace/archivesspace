require 'spec_helper'

describe 'Digital Objects controller' do

  it "lets you create a digital object and get it back" do
    id = create_digital_object("title" => "a digital object").id

    expect(JSONModel(:digital_object).find(id).title).to eq("a digital object")
  end


  it "lets you update a digital object" do
    id = create_digital_object.id

    digital_object = JSONModel(:digital_object).find(id)

    digital_object.title = "an updated digital object"
    digital_object.save

    expect(JSONModel(:digital_object).find(id).title).to eq("an updated digital object")
  end


  it "can give a list of digital objects" do
    create(:json_digital_object)
    create(:json_digital_object)
    expect(JSONModel(:digital_object).all(:page => 1)['results'].count).to eq(3)
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

    expect(tree['children'][0]['record_uri']).to eq(docs[0].uri)
    expect(tree['children'][0]['children'][0]['record_uri']).to eq(docs[1].uri)
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
    expect(tree.children.length).to eq(2)
  end


  it "supports saving and loading file versions" do
    version = build(:json_file_version)
    digital_object = create(:json_digital_object,
                            :file_versions => [version])

    created = JSONModel(:digital_object).find(digital_object.id)

    expect(created.file_versions.count).to eq(1)
    expect(created.file_versions[0]['file_uri']).to eq(version.file_uri)
  end


  it "doesn't wipe out linked instances on save" do
    digobj = create(:json_digital_object)

    resource = create(:json_resource,
                      :instances => [build(:json_instance_digital,
                                           :digital_object => {:ref => digobj.uri})])

    digobj = JSONModel(:digital_object).find(digobj.id)
    digobj.title = "updated"
    digobj.save

    expect(JSONModel(:resource).find(resource.id).instances.count).to be(1)
  end


  it "publishes the digital object, subrecords and components when /publish is POSTed" do
    digital_object = create(:json_digital_object, {
      :publish => false,
      :external_documents => [build(:json_external_document, {:publish => false})],
      :file_versions => [build(:json_file_version, {:publish => false})],
      :notes => [build(:json_note_bibliography, {:publish => false})]
    })

    component = create(:json_digital_object_component, {
      :publish => false,
      :digital_object => {:ref => digital_object.uri},
      :external_documents => [build(:json_external_document, {:publish => false})],
      :file_versions => [build(:json_file_version, {:publish => false})],
      :notes => [build(:json_note_bibliography, {:publish => false})]
    })

    url = URI("#{JSONModel::HTTP.backend_url}#{digital_object.uri}/publish")

    request = Net::HTTP::Post.new(url.request_uri)
    response = JSONModel::HTTP.do_http_request(url, request)


    digital_object = JSONModel(:digital_object).find(digital_object.id)
    expect(digital_object.publish).to be_truthy
    expect(digital_object.external_documents[0]["publish"]).to be_truthy
    expect(digital_object.file_versions[0]["publish"]).to be_truthy
    expect(digital_object.notes[0]["publish"]).to be_truthy

    component = JSONModel(:digital_object_component).find(component.id)
    expect(component.publish).to be_truthy
    expect(component.external_documents[0]["publish"]).to be_truthy
    expect(component.file_versions[0]["publish"]).to be_truthy
    expect(component.notes[0]["publish"]).to be_truthy
  end


  it "accepts move of multiple children" do
    digital_object = create(:json_digital_object)
    doc = create(:json_digital_object_component, :digital_object => {:ref => digital_object.uri})

    child_1 = create(:json_digital_object_component, :digital_object => {:ref => digital_object.uri}, :parent => {:ref => doc.uri})
    child_2 = create(:json_digital_object_component, :digital_object => {:ref => digital_object.uri}, :parent => {:ref => doc.uri})

    response = JSONModel::HTTP::post_form("#{digital_object.uri}/accept_children", {"children[]" => [child_1.uri, child_2.uri], "position" => 0})
    json_response = ASUtils.json_parse(response.body)

    expect(json_response["status"]).to eq("Updated")

    tree = JSONModel(:digital_object_tree).find(nil, :digital_object_id => digital_object.id)

    expect(tree.children.length).to eq(3)
    expect(tree.children[0]["title"]).to eq(child_1["title"])
    expect(tree.children[0]["record_uri"]).to eq(child_1.uri)

    expect(tree.children[1]["title"]).to eq(child_2["title"])
    expect(tree.children[1]["record_uri"]).to eq(child_2.uri)

    expect(tree.children[2]["title"]).to eq(doc["title"])
    expect(tree.children[2]["record_uri"]).to eq(doc.uri)
  end


  it "allows posting of array of children" do
    digital_object = create(:json_digital_object)

    doc_1 = build(:json_digital_object_component)
    doc_2 = build(:json_digital_object_component)

    children = JSONModel(:digital_record_children).from_hash({
                                                                "children" => [doc_1, doc_2]
                                                              })

    url = URI("#{JSONModel::HTTP.backend_url}#{digital_object.uri}/children")
    response = JSONModel::HTTP.post_json(url, children.to_json)
    json_response = ASUtils.json_parse(response.body)

    expect(json_response["status"]).to eq("Updated")

    tree = JSONModel(:digital_object_tree).find(nil, :digital_object_id => digital_object.id)
    expect(tree.children.length).to eq(2)

    sorted_by_id = tree.children.sort_by{ |x| x["id"]}

    expect(sorted_by_id[0]["title"]).to eq(doc_1["title"])
    expect(sorted_by_id[1]["title"]).to eq(doc_2["title"])
  end



    it "updates a parent record if a linked digital object is deleted" do
      sacrificial_do = create(:json_digital_object)

      resource = create(:json_resource,
                        :instances => [build(:json_instance_digital,
                                             :digital_object => {:ref => sacrificial_do.uri})])

      archival_object = create(:json_archival_object,
                       :instances => [build(:json_instance_digital,
                                            :digital_object => {:ref => sacrificial_do.uri})])

      sacrificial_do = JSONModel(:digital_object).find(sacrificial_do.id)
      sacrificial_do.linked_instances = [{'ref' => resource.uri}, {'ref' => archival_object.uri}]
      sacrificial_do.save

      expect(sacrificial_do.linked_instances.count).to be(2)

      sacrificial_do.delete

      expect {
        JSONModel(:digital_object).find(sacrificial_do.id)
      }.to raise_error(RecordNotFound)

      resource = JSONModel(:resource).find(resource.id)
      expect(resource).not_to be_nil
      expect(resource.instances.count).to be(0)

      archival_object = JSONModel(:archival_object).find(archival_object.id)
      expect(archival_object).not_to be_nil
      expect(archival_object.instances.count).to be(0)
    end
end
