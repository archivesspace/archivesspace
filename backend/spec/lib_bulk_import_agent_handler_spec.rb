require "spec_helper"
require_relative "../app/lib/bulk_import/agent_handler"
require_relative "../app/model/mixins/dynamic_enums"
require_relative "../app/model/enumeration"

describe "Agent Handler" do
  # define some agents by type
  let(:person_agent) {
    build(:json_agent_person,
          :names => [build(:json_name_person)],
          :agent_contacts => [build(:json_agent_contact)],
          :external_documents => [build(:json_external_document)],
          :notes => [build(:json_note_bioghist)])
  }
  test_opts = { :names => [
    {
      "rules" => "local",
      "family_name" => "Magoo Family",
      "sort_name" => "Family Magoo",
    },
  ] }

  let(:family_agent) {
    build(:json_agent_family, test_opts)
  }
  test_opts1 = { :names => [
    {
      "rules" => "local",
      "primary_name" => "Magus Magoo Inc",
      "sort_name" => "Magus Magoo Inc",
    },
  ] }
  let(:corp_agent) {
    build(:json_agent_corporate_entity, test_opts1)
  }

  before(:each) do
    current_user = User.find(:username => "admin")
    @ah = AgentHandler.new(current_user)
    @agents = @ah.instance_variable_get(:@agents)
    @report = BulkImportReport.new
    @report.new_row(1)
  end

  def build_return_key(type, id, header, relator, role)
    agent = @ah.build(type, id, header, relator, role)
    { agent: agent,
      key: @ah.key_for(agent) }
  end

  it "should build an agents hash and return a key" do
    res = build_return_key("people", nil, "Smith, John", "aut", nil)
    expect(res[:key]).to eq("person_Smith, John")
    expect(res[:agent][:role]).to eq("creator")
  end

  it "should build an agent entry  with the 'id_but_no_name' value as true " do
    agent = @ah.build("people", 20, nil, "aut", nil)
    expect(agent[:id_but_no_name]).to eq(true)
  end

  it "should create an person agent using 'create_agent', then retrieve it with 'get_or_create'" do
    res = build_return_key("people", nil, "Smith, John", "aut", nil)
    created = @ah.create_agent(res[:agent])
    id = created[:id]
    a = nil
    expect {
      a = AgentPerson.get_or_die(id)
    }.not_to raise_error
    expect(a[:id]).to eq(id)
    a1 = @ah.get_or_create("people", id, nil, "aut", "source", @report)
    newid = a1["ref"].split("/")[3]
    expect(newid).to eq(id.to_s)
    a.delete
  end

  it "should find a person agent from its ID " do
    agent_1 = AgentPerson.create_from_json(person_agent)
    a1 = @ah.get_or_create("people", agent_1[:id], nil, "aut", "source", @report)
    newid = a1["ref"].split("/")[3]
    expect(newid).to eq(agent_1[:id].to_s)
    agent_1.delete
  end
  it "should find a family from its ID" do
    agent_2 = AgentFamily.create_from_json(family_agent)
    a1 = @ah.get_or_create("family", agent_2[:id], nil, "aut", "source", @report)
    newid = a1["ref"].split("/")[3]
    expect(newid).to eq(agent_2[:id].to_s)
  end
  it "should find a corporation from its ID" do
    agent_3 = AgentCorporateEntity.create_from_json(corp_agent)
    a1 = @ah.get_or_create("corporate_entity", agent_3[:id], nil, "aut", nil, @report)
    newid = a1["ref"].split("/")[3]
    expect(newid).to eq(agent_3[:id].to_s)
  end
end
