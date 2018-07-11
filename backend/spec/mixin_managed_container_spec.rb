require 'spec_helper'
require_relative 'factories'

describe 'Managed Container mixin' do

  it "can create an Accession with a Sub Container" do
    top_container = build(:json_top_container, {})

    top_container_id = TopContainer.create_from_json(top_container, :repo_id => $repo_id).id
    top_container_uri = JSONModel(:top_container).uri_for(top_container_id)

    sub_container = build(:json_sub_container, {
      "top_container" => {
        "ref" => top_container_uri
      }
    })

    accession = create_accession({
      "instances" => [build(:json_instance, {
        "instance_type" => "accession",
        "sub_container" => sub_container
      })]
    })

    instances = Accession.to_jsonmodel(accession.id).instances
    instances.length.should eq(1)
    instances[0]["sub_container"].should_not be_nil
    instances[0]["sub_container"]["top_container"].should_not be_nil
    instances[0]["sub_container"]["top_container"]["ref"].should eq(top_container_uri)
  end


  it "requires a top record to be specified" do
    expect {
      create_accession({
                         "instances" => [build(:json_instance, {
                           "instance_type" => "accession",
                           "sub_container" => build(:json_sub_container, :top_container => nil)
                         })]
                       })
    }.to raise_error(JSONModel::ValidationException)
  end


  it "requires a indicator 2 if type 2 is provided" do
    expect {
      create_accession({
                         "instances" => [build(:json_instance, {
                           "instance_type" => "accession",
                           "sub_container" => build(:json_sub_container, {
                            "top_container" => {
                              "ref" => create(:json_top_container).uri
                            },
                            "indicator_2" => nil,
                            "indicator_3" => nil,
                            "type_3" => nil
                           })
                         })]
                       })
    }.to raise_error(JSONModel::ValidationException)
  end


  it "requires a type 2 if indicator 2 is provided" do
    expect {
      create_accession({
                         "instances" => [build(:json_instance, {
                           "instance_type" => "accession",
                           "sub_container" => build(:json_sub_container, {
                             "top_container" => {
                               "ref" => create(:json_top_container).uri
                             },
                             "type_2" => nil,
                             "indicator_3" => nil,
                             "type_3" => nil
                           })
                         })]
                       })
    }.to raise_error(JSONModel::ValidationException)
  end


  it "requires a indicator 3 if type 3 is provided" do
    expect {
      create_accession({
                         "instances" => [build(:json_instance, {
                           "instance_type" => "accession",
                           "sub_container" => build(:json_sub_container, {
                             "top_container" => {
                               "ref" => create(:json_top_container).uri
                             },
                             "indicator_3" => nil
                           })
                         })]
                       })
    }.to raise_error(JSONModel::ValidationException)
  end


  it "requires a type 3 if indicator 3 is provided" do
    expect {
      create_accession({
                         "instances" => [build(:json_instance, {
                           "instance_type" => "accession",
                           "sub_container" => build(:json_sub_container, {
                             "top_container" => {
                               "ref" => create(:json_top_container).uri
                             },
                             "type_3" => nil
                           })
                         })]
                       })
    }.to raise_error(JSONModel::ValidationException)
  end

  it "requires a container 2 if container 3 is provided" do
    expect {
      create_accession({
                         "instances" => [build(:json_instance, {
                           "instance_type" => "accession",
                           "sub_container" => build(:json_sub_container, {
                             "top_container" => {
                               "ref" => create(:json_top_container).uri
                             },
                             "indicator_2" => nil,
                             "type_2" => nil,
                           })
                         })]
                       })
    }.to raise_error(JSONModel::ValidationException)
  end

end
