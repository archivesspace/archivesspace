require 'spec_helper'


describe 'Component Add Children controllers' do

  let(:resource) {   create(:json_resource) }
  let(:ao) { create(:json_archival_object, :resource => {:ref => resource.uri}) }



  def perform_delete(record_uris)
    uri = "/batch_delete"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
    JSONModel::HTTP.post_json(url, {:record_uris => record_uris})
  end

  def get_ao_tree(id)
    get "#{$repo}/archival_objects/#{id}/children"
    last_response.should be_ok
    JSON(last_response.body)
  end

  it "allows you to post multiple children and not mix up the order" do
    children = []
    3.times { children << create(:json_archival_object, :resource => {:ref => resource.uri}, :parent => {:ref => ao.uri}).uri  }
    response = JSONModel::HTTP::post_form("#{resource.uri}/accept_children", {"children[]" => children, "position" => 0})
    json_response = ASUtils.json_parse(response.body)
    json_response["status"].should eq("Updated")

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)
    tree.children.length.should eq(4)

    # we've moved the children up a level to be with their original parent. 
    children << ao.uri 
    
    tree.children.each_with_index do |child, i|
      child["record_uri"].should eq children[i]
    end

  end

  it "can keep the order even if the tree has been reworked" do
    children = []
    100.times { children << create(:json_archival_object, :resource => {:ref => resource.uri}, :parent => {:ref => ao.uri}).uri  }

    tree = get_ao_tree(ao.id) 
    tree.length.should eq(100)

    # let's delete a chunk
    victims = children.slice!(19..38)
    perform_delete(victims)
    
    tree = get_ao_tree(ao.id) 
    tree.length.should eq(80)
    
    tree.each_with_index do |child, i|
      child["uri"].should eq(children[i])
    end

    #now let's move some things around.
    movers = children.pop(10)
    the_move = JSONModel::HTTP::post_form("#{ao.uri}/accept_children", {"children[]" => movers, "position" => 20})
    the_move.should be_ok 

    # we've delete 20 ( from position 20) and moved 10 from the bottom to
    # postion 20
    new_order = children.slice(0..19) + movers + children.drop(20) 
    # let's check out tree 
    
    tree = get_ao_tree(ao.id) 
    tree.length.should eq(80)
    # check the new order 
    tree.each_with_index do |child, i|
      child["uri"].should eq(new_order[i])
    end

    # one more time, but moving down the tree
    # let's refresh out children list
    children = tree.collect { |n| n["uri"] }

    # take the first 10 and move them
    movers = children.shift(10)
    the_move = JSONModel::HTTP::post_form("#{ao.uri}/accept_children", {"children[]" => movers, "position" => 20})
    the_move.should be_ok 

    new_order = children.slice(0..19) + movers + children.drop(20)
    
    # let's check out tree again 
    tree = get_ao_tree(ao.id) 
    tree.length.should eq(80)
    # check the new order 
    tree.each_with_index do |child, i|
      child["uri"].should eq(new_order[i])
    end

  end


  it "won't let you be your own grandparent" do
    parent = create(:json_archival_object, :resource => {:ref => resource.uri})
    child = create(:json_archival_object,
                   :resource => {:ref => resource.uri},
                   :parent => {:ref => parent.uri})
    grandchild = create(:json_archival_object,
                        :resource => {:ref => resource.uri},
                        :parent => {:ref => child.uri})


    response = JSONModel::HTTP::post_form("#{grandchild.uri}/accept_children", {"children[]" => [parent.uri], "position" => 0})

    response.status.should eq(409)
  end


end
