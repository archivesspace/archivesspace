require 'spec_helper'

describe 'Touch Records mixin' do
  it 'can update resource system_mtime value when related ao created' do
    resource = create_resource({title: generate(:generic_title)})
    resource_mt = resource.system_mtime
    ArchivesSpaceService.wait(:long)
    obj = create_archival_object({'resource' => { 'ref' => resource.uri }})
    resource.refresh

    expect(resource.system_mtime).to be > resource_mt
    expect(resource.system_mtime).to be >= obj.system_mtime
  end

  it 'can update resource system_mtime value when related ao updated' do
    resource = create_resource({title: generate(:generic_title)})
    obj = create_archival_object({'resource' => { 'ref' => resource.uri }})
    obj_mt = obj.system_mtime
    ArchivesSpaceService.wait(:long)
    obj.update_from_json(ArchivalObject.to_jsonmodel(obj.id))
    resource.refresh && obj.refresh

    expect(obj.system_mtime).to be > obj_mt
    expect(resource.system_mtime).to be >= obj.system_mtime
  end

  it 'can update resource system_mtime value when related ao deleted' do
    resource = create_resource({title: generate(:generic_title)})
    resource_mt = resource.system_mtime
    ArchivesSpaceService.wait(:long)
    obj = create_archival_object({'resource' => { 'ref' => resource.uri }})
    obj_mt = obj.system_mtime
    obj.delete
    resource.refresh

    expect(resource.system_mtime).to be > resource_mt
    expect(resource.system_mtime).to be >= obj_mt
  end

  it 'works the same for digital objects and components' do
    digital_object = create_digital_object({title: generate(:generic_title)})
    doc = create_digital_object_component({ 'digital_object' => { 'ref' => digital_object.uri }})
    doc_mt = doc.system_mtime
    ArchivesSpaceService.wait(:long)
    doc.update_from_json(DigitalObjectComponent.to_jsonmodel(doc.id))
    digital_object.refresh && doc.refresh

    expect(doc.system_mtime).to be > doc_mt
    expect(digital_object.system_mtime).to be >= doc.system_mtime
  end

  it "updates the system_mtime for linked subjects when agents are updated" do
    agent_person = create(:json_agent_person_full_subrec)
    [AgentFunction, AgentOccupation, AgentPlace, AgentTopic].each do |type|
      # Gotta get the subrecord to get the subject id
      subrecord = type.find(agent_person.id).first
      subj_id = AgentManager.linked_subjects(subrecord.id, :subject_agent_subrecord, type.to_s.underscore).first
      original_mtime = Subject[subj_id].refresh.system_mtime

      ArchivesSpaceService.wait(:long)
      AgentPerson[agent_person.id].update_from_json(AgentPerson.to_jsonmodel(agent_person.id))

      expect(Subject[subj_id].refresh.system_mtime).to be > original_mtime
      expect(Subject[subj_id].system_mtime.to_i).to be >= agent_person.system_mtime.to_i
    end
  end

  it "updates the system_mtime for linked subject places when agents are updated" do
    agent_person = create(:json_agent_person_full_subrec)
    [AgentFunction, AgentOccupation, AgentResource, AgentTopic].each do |type|
      # Gotta get the subrecord to get the subject id
      subrecord = type.find(agent_person.id).first
      subj_id = AgentManager.linked_subjects(subrecord.id, :subject_agent_subrecord_place, type.to_s.underscore).first
      original_mtime = Subject[subj_id].refresh.system_mtime

      ArchivesSpaceService.wait(:long)
      AgentPerson[agent_person.id].update_from_json(AgentPerson.to_jsonmodel(agent_person.id))

      expect(Subject[subj_id].refresh.system_mtime).to be > original_mtime
      expect(Subject[subj_id].system_mtime.to_i).to be >= agent_person.system_mtime.to_i
    end
  end

end
