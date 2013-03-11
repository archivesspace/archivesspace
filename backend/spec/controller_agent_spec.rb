require 'spec_helper'

describe 'Generic agent controller' do

  it "lets you list all agents of any type" do
    
    i = 0
    
    start = JSONModel.all('/agents', :agent_type).length
    
    [:agent_person, :agent_family, :agent_software, :agent_corporate_entity].each do |a_type|

      i = i+1
      create("json_#{a_type.to_s}".to_sym)
    end

    JSONModel.all('/agents', :agent_type).length.should eq(start + i)

  end
end
