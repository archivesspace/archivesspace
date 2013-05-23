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


  it "can give a list of digital objects" do
    create(:json_digital_object)
    create(:json_digital_object)
    JSONModel(:digital_object).all(:page => 1)['results'].count.should eq(2)
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


  it "supports saving and loading file versions" do
    version = build(:json_file_version)
    digital_object = create(:json_digital_object,
                            :file_versions => [version])

    created = JSONModel(:digital_object).find(digital_object.id)

    created.file_versions.count.should eq(1)
    created.file_versions[0]['file_uri'].should eq(version.file_uri)
  end


  it "doesn't wipe out linked instances on save" do
    digobj = create(:json_digital_object)

    resource = create(:json_resource,
                      :instances => [build(:json_instance,
                                           :digital_object => {'ref' => digobj.uri})])

    digobj = JSONModel(:digital_object).find(digobj.id)
    digobj.title = "updated"
    digobj.save

    JSONModel(:resource).find(resource.id).instances.count.should be(1)
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
    digital_object.publish.should eq(true)
    digital_object.external_documents[0]["publish"].should eq(true)
    digital_object.file_versions[0]["publish"].should eq(true)
    digital_object.notes[0]["publish"].should eq(true)

    component = JSONModel(:digital_object_component).find(component.id)
    component.publish.should eq(true)
    component.external_documents[0]["publish"].should eq(true)
    component.file_versions[0]["publish"].should eq(true)
    component.notes[0]["publish"].should eq(true)
  end

end
