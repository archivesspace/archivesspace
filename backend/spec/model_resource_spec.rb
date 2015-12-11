require 'spec_helper'

describe 'Resource model' do

  it "allows resources to be created" do
    opts = {:title => generate(:generic_title)}
    
    resource = create_resource(opts)

    Resource[resource[:id]].title.should eq(opts[:title])
  end


  it "prevents duplicate IDs " do
    opts = {:id_0 => generate(:alphanumstr)}
    
    create_resource(opts)

    expect { create_resource(opts) }.to raise_error(Sequel::ValidationFailed)
  end


  it "reports an error if id_0 has no value" do
    opts = {:id_0 => nil}
    
    expect { create_resource(opts) }.to raise_error(JSONModel::ValidationException)
  end


  it "doesn't enforce ID uniqueness between repositories" do
    repo1 = make_test_repo("REPO1")
    repo2 = make_test_repo("REPO2")

    expect {
      [repo1, repo2].each do |repo_id|
        Resource.create_from_json(build(:json_resource,
                                         {
                                           :id_0 => "1234",
                                           :id_1 => "5678",
                                           :id_2 => "9876",
                                           :id_3 => "5432"
                                         }),
                                   :repo_id => repo_id)
      end
    }.to_not raise_error
  end


  it "allows resources to be created with a date" do
    opts = {:dates => [build(:json_date)]}
    
    resource = create_resource(opts)

    Resource[resource[:id]].date.length.should eq(1)
    Resource[resource[:id]].date[0].begin.should eq(opts[:dates][0]['begin'])
  end


  it "throws an exception if extents is nil" do
    expect { create_resource({:extents => nil}) }.to raise_error(JSONModel::ValidationException)
  end


  it "throws an exception if extents is empty" do
    expect { create_resource({:extents => []}) }.to raise_error(JSONModel::ValidationException)
  end


  it "blows up if you don't specify which repository you're querying" do
    resource = create_resource

    expect {
      RequestContext.put(:repo_id, nil)
      Resource.to_jsonmodel(resource[:id])
    }.to raise_error(RuntimeError)
  end


  it "can be created with an instance" do
    opts = {:instances => [build(:json_instance)]}
    resource = create_resource(opts)
    Resource[resource[:id]].instance.length.should eq(1)
    Resource[resource[:id]].instance[0].instance_type.should eq(opts[:instances][0]['instance_type'])
    Resource.to_jsonmodel(resource[:id])['instances'][0]["container"]["type_1"].should eq(opts[:instances][0]["container"]["type_1"])
  end


  it "throws an error when no language is provided" do
    opts = {:language => nil}

    expect { create_resource(opts) }.to raise_error(JSONModel::ValidationException)
  end


  it "throws an error if 'level' is 'otherlevel' and 'other level' isn't provided" do
    opts = {:level => "otherlevel", :other_level => nil}

    expect { create_resource(opts) }.to raise_error(JSONModel::ValidationException)
  end


  it "allows long titles" do
    expect {
      res = create(:resource, {:repo_id => $repo_id, :title => 200.times.map { 'moo'}.join})
    }.to_not raise_error
  end


  it "ensures that ead_ids are unique" do
    create_resource(:ead_id => "hello")

    expect {
      create_resource(:ead_id => "hello")
    }.to raise_error(Sequel::ValidationFailed)
  end


  it "can be linked to a classification" do
    classification = build(:json_classification,
                           :title => "top-level classification",
                           :identifier => "abcdef",
                           :description => "A classification")

    classification = Classification.create_from_json(classification)
    resource = create_resource(:classifications =>[   {'ref' => classification.uri} ])

    resource.related_records(:classification).first.title.should eq("top-level classification")
  end

  # See https://gist.github.com/anarchivist/7477913
  it "can update records that have external ids" do
    opts = {
      :id_0 => "test",
      :id_1 => "4444",
      :ead_id => "test000",
      :finding_aid_title => "Test",
      :finding_aid_subtitle => "SubTest"
    }
    
    json = build(:json_resource, opts)

    json[:external_ids] = 
      [{
         :source => "Archivists Toolkit Database::RESOURCE",
         :external_id => "1"
       }]

    resource = Resource.create_from_json(json, :repo_id => $repo_id)

    json[:lock_version] = 0
    
    expect { resource.update_from_json(json) }.to_not raise_error
  end
end
