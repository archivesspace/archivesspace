require 'spec_helper'

describe 'ArchivalObject notes mixin' do

  it "can publish subnotes" do
    subnote = build(:json_note_text, :content => "a text subnote", :publish => false)

    ao = ArchivalObject.create_from_json(build(:json_archival_object,
                                               'notes' => [build(:json_note_multipart,
                                                                 'type' => 'accruals',
                                                                 :subnotes => [subnote])]))

    ao.publish!

    expect(ArchivalObject.to_jsonmodel(ao.id)['notes'][0]['subnotes'][0]['publish']).to be_truthy
  end


  it "can delete a record with notes" do
    subnote = build(:json_note_text, :content => "a text subnote", :publish => false)

    ao = ArchivalObject.create_from_json(build(:json_archival_object,
                                               'notes' => [build(:json_note_multipart,
                                                                 'type' => 'accruals',
                                                                 :subnotes => [subnote])]))

    ao.delete

    expect(ArchivalObject[ao.id]).to be_nil
  end


  it "can unpublish subnotes" do
    subnote = build(:json_note_text, :content => "a text subnote", :publish => true)

    ao = ArchivalObject.create_from_json(build(:json_archival_object,
                                               'notes' => [build(:json_note_multipart,
                                                                 'type' => 'accruals',
                                                                 :subnotes => [subnote])]))

    ao.unpublish!

    expect(ArchivalObject.to_jsonmodel(ao.id)['notes'][0]['subnotes'][0]['publish']).to be_falsey
  end


  describe "applying notes on updates" do

    it "can create and update notes attached to a top-level record" do
      count = Note.all.count
      md_count = SubnoteMetadata.all.count
      ao = ArchivalObject.create_from_json(build(:json_archival_object,
                                                 'notes' => [build(:json_note_multipart)]))
      json = ArchivalObject.to_jsonmodel(ao.id)
      json.notes[0]['subnotes'][0]['content'] = "scooby doo"
      ArchivalObject[ao.id].update_from_json(json)
      json = ArchivalObject.to_jsonmodel(ao.id)
      expect(json.notes.length).to eq(1)
      expect(Note.all.count).to eq(count+1)
      expect(SubnoteMetadata.all.count).to eq(md_count+1)
      expect(json.notes[0]["subnotes"][0]["content"]).to eq("scooby doo")
    end


    it "can create and update notes attached to a lang_material subrecord" do
      count = Note.all.count
      md_count = SubnoteMetadata.all.count
      ao = ArchivalObject.create_from_json(build(:json_archival_object,
                                                 'lang_materials' => [build(:json_lang_material_with_note)]))
      json = ArchivalObject.to_jsonmodel(ao.id)
      json.lang_materials[0]["notes"][0]["content"][0] = "scooby doo"
      ArchivalObject[ao.id].update_from_json(json)
      json = ArchivalObject.to_jsonmodel(ao.id)
      expect(json.lang_materials[0]["notes"][0]["content"][0]).to eq("scooby doo")
      expect(Note.all.count).to eq(count+1)
      expect(SubnoteMetadata.all.count).to eq(md_count)
    end

    it "can create and update notes attached to an agent_contact subrecord" do
      count = Note.all.count
      md_count = SubnoteMetadata.all.count
      obj = AgentPerson.create_from_json(build(:json_agent_person,
                                               'agent_contacts' => [{
                                                                      "name" => "jane dough",
                                                                      "notes" => [build(:json_note_contact_note)]}]))

      json = AgentPerson.to_jsonmodel(obj.id)
      json.agent_contacts[0]["notes"][0]["contact_notes"] = "scooby doo"
      AgentPerson[obj.id].update_from_json(json)
      json = AgentPerson.to_jsonmodel(obj.id)
      expect(json.agent_contacts[0]["notes"][0]["contact_notes"]).to eq("scooby doo")
      expect(Note.all.count).to eq(count+1)
      expect(SubnoteMetadata.all.count).to eq(md_count)
    end

    it "can create and update notes attached to a rights_statement subrecord" do
      count = Note.all.count
      md_count = SubnoteMetadata.all.count
      ao = ArchivalObject.create_from_json(build(:json_archival_object,
                                                 'rights_statements' => [build(:json_rights_statement,
                                                                               'notes' => [build(:json_note_rights_statement)]
                                                                              )]))
      json = ArchivalObject.to_jsonmodel(ao.id)
      json.rights_statements[0]["notes"][0]["content"][0] = "scooby doo"
      ArchivalObject[ao.id].update_from_json(json)
      json = ArchivalObject.to_jsonmodel(ao.id)
      expect(json.rights_statements[0]["notes"][0]["content"][0]).to eq("scooby doo")
      expect(Note.all.count).to eq(count+1)
      expect(SubnoteMetadata.all.count).to eq(md_count)
    end
  end
end
