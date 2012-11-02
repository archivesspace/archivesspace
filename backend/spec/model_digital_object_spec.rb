require 'spec_helper'

describe 'Digital object model' do

  it "Allows digital objects to be created" do
    
    json = build(:json_digital_object)
    
    digital_object = DigitalObject.create_from_json(json, :repo_id => $repo_id)

    DigitalObject[digital_object[:id]].title.should eq(json.title)
  end


  it "Prevents duplicate IDs " do
  
    json1 = build(:json_digital_object, :digital_object_id => '123')
    
    json2 = build(:json_digital_object, :digital_object_id => '123')

    expect { DigitalObject.create_from_json(json1, :repo_id => $repo_id) }.to_not raise_error
    expect { DigitalObject.create_from_json(json2, :repo_id => $repo_id) }.to raise_error
  end



end
