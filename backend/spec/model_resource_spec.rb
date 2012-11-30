require 'spec_helper'

describe 'Resource model' do

  def create_resource(opts = {})
    Resource.create_from_json(build(:json_resource, opts), :repo_id => $repo_id)
  end


  it "Allows resources to be created" do
    
    opts = {:title => generate(:generic_title)}
    
    resource = create_resource(opts)

    Resource[resource[:id]].title.should eq(opts[:title])
  end


  it "Prevents duplicate IDs " do
    
    opts = {:id_0 => generate(:alphanumstr)}
    
    create_resource(opts)

    expect { create_resource(opts) }.to raise_error
  end


  it "Allows resources to be created with a date" do
    
    opts = {:dates => [build(:json_date).to_hash]}
    
    resource = create_resource(opts)

    Resource[resource[:id]].date.length.should eq(1)
    Resource[resource[:id]].date[0].begin.should eq(opts[:dates][0]['begin'])
  end


  it "Throws an exception if extents is nil" do
    
    expect { create_resource({:extents => nil}) }.to raise_error    
  end


  it "Throws an exception if extents is empty" do
    
    expect { create_resource({:extents => []}) }.to raise_error
  end


  it "blows up if you don't specify which repository you're querying" do
    resource = create_resource

    expect {
      RequestContext.put(:repo_id, nil)
      Resource.to_jsonmodel(resource[:id], :resource)
    }.to raise_error
  end


  it "can be created with an instance" do
    
    opts = {:instances => [build(:json_instance).to_hash]}
    
    resource = create_resource(opts)

    Resource[resource[:id]].instance.length.should eq(1)
    Resource[resource[:id]].instance[0].instance_type.should eq(opts[:instances][0]['instance_type'])
    Resource[resource[:id]].instance[0].container.first.type_1.should eq(opts[:instances][0]['container']['type_1'])
  end


  it "throws an error when no language is provided" do

    opts = {:language => nil}

    expect { create_resource(opts) }.to raise_error
  end


end
