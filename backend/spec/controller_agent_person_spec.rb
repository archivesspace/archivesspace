require 'spec_helper'

describe 'Person agent controller' do

  def create_person
    JSONModel(:agent_person).from_hash(:names => [{
                                                    :authority_id => 'authid',
                                                    :primary_name => 'Magus Magoo'
                                                  }]).save
  end


  it "lets you create a person and get them back" do
    id = create_person
    JSONModel(:agent_person).find(id).names.first['primary_name'].should eq('Magus Magoo')
  end

end
