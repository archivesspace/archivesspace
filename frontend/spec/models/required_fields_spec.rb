require 'rails'
require 'spec_helper'
require 'rails_helper'

describe "RequiredFields model" do

  let(:json_record) {
    JSONModel(:required_fields).from_hash({
                                            record_type: 'agent_person',
                                            required: {
                                              "agent_record_controls": [
                                                                         {
                                                                           "jsonmodel_type": "agent_record_control"
                                                                         }
                                                                       ],
                                            }
                                          })
  }

  it "gives an empty RequiredFields object for any lookup that does not exist" do
    expect(RequiredFields.get("agent_person").values).to be_empty
  end

  it "can create, persist, and retrieve a required_fields definition with a key and blob" do
    session = User.login('admin', 'admin')
    Thread.current[:backend_session] = session['session']
    required = RequiredFields.new(json_record)
    required.save
    required = RequiredFields.get("agent_person")
    expect(required.values).to eq({"agent_record_controls"=>[{"jsonmodel_type" => "agent_record_control"}]})
  end
end
