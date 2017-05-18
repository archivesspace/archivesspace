require 'spec_helper'

describe 'Implied publication' do

  it "an agent record is published if linked to a published record" do
    agent = create_agent_person
    agent2 = create_agent_person

    5.times do |i|
      create(:json_resource,
             :publish => (i == 2),
             :linked_agents => [{
                                  'ref' => agent.uri,
                                  'role' => 'source'
                                },
                                {
                                  'ref' => agent2.uri,
                                  'role' => 'source'
                                }])
    end

    jsons = AgentPerson.sequel_to_jsonmodel([AgentPerson[agent.id], AgentPerson[agent2.id]])

    jsons.all? {|json| json['is_linked_to_published_record']}.should be(true)
  end

  it "a subject record is published if linked to a published record" do
    subject = create(:json_subject)
    subject2 = create(:json_subject)

    5.times do |i|
      create(:json_resource,
             :publish => (i == 2),
             :subjects => [{
                             'ref' => subject.uri,
                           },
                           {
                             'ref' => subject2.uri,
                           }])
    end

    jsons = Subject.sequel_to_jsonmodel([Subject[subject.id], Subject[subject2.id]])

    jsons.all? {|json| json['is_linked_to_published_record']}.should be(true)
  end


  it "an agent record is not published if linked to a suppressed record" do
    agent = create_agent_person
    resource = create_resource(:linked_agents => [{
                                 'ref' => agent.uri,
                                 'role' => 'source'
                               }],
                               :publish => true)

    resource.set_suppressed(true)

    json = AgentPerson.sequel_to_jsonmodel([AgentPerson[agent.id]])[0]

    json['is_linked_to_published_record'].should be(false)
  end


  it "an agent record is not published if linked to a published record with an unpublished ancestor" do
    agent = create_agent_person
    resource = create_resource(:publish => false)
    series = create(:json_archival_object,
                    :resource => {:ref => resource.uri},
                    :publish => true)
    item = create(:json_archival_object,
                  :resource => {:ref => resource.uri},
                  :parent => {:ref => series.uri},
                  :linked_agents => [{
                                       'ref' => agent.uri,
                                       'role' => 'source'
                                     }],
                  :publish => true)

    json = AgentPerson.sequel_to_jsonmodel([AgentPerson[agent.id]])[0]

    json['is_linked_to_published_record'].should be(false)
  end


  it "an agent record is not published if linked to a published record with an suppressed ancestor" do
    agent = create_agent_person
    resource = create_resource(:publish => true)
    series = create(:json_archival_object,
                    :resource => {:ref => resource.uri},
                    :publish => true)
    item = create(:json_archival_object,
                  :resource => {:ref => resource.uri},
                  :parent => {:ref => series.uri},
                  :linked_agents => [{
                                       'ref' => agent.uri,
                                       'role' => 'source'
                                     }],
                  :publish => true)

    series.set_suppressed(true)

    json = AgentPerson.sequel_to_jsonmodel([AgentPerson[agent.id]])[0]

    json['is_linked_to_published_record'].should be(false)
  end


  it "an agent record is published if linked to a published record even when linked to a suppressed record" do
    agent = create_agent_person

    resource1 = create_resource(:publish => true)
    series1 = create(:json_archival_object,
                    :resource => {:ref => resource1.uri},
                    :publish => true)
    item1 = create(:json_archival_object,
                  :resource => {:ref => resource1.uri},
                  :parent => {:ref => series1.uri},
                  :linked_agents => [{
                                       'ref' => agent.uri,
                                       'role' => 'source'
                                     }],
                  :publish => true)

    resource2 = create_resource(:publish => true)
    series2 = create(:json_archival_object,
                    :resource => {:ref => resource2.uri},
                    :publish => true)
    item2 = create(:json_archival_object,
                  :resource => {:ref => resource2.uri},
                  :parent => {:ref => series2.uri},
                  :linked_agents => [{
                                       'ref' => agent.uri,
                                       'role' => 'source'
                                     }],
                  :publish => true)


    series1.set_suppressed(true)

    json = AgentPerson.sequel_to_jsonmodel([AgentPerson[agent.id]])[0]

    json['is_linked_to_published_record'].should be(true)
  end

  it "an top container record is unpublished if linked to a unpublished record and a suppressed record" do
    top_container = build(:json_top_container, {})

    top_container_id = TopContainer.create_from_json(top_container, :repo_id => $repo_id).id
    top_container_uri = JSONModel(:top_container).uri_for(top_container_id)

    sub_container = build(:json_sub_container, {
      "top_container" => {
        "ref" => top_container_uri
      }
    })

    resource1 = create_resource(:publish => true)
    series1 = create(:json_archival_object,
                     :resource => {:ref => resource1.uri},
                     :publish => true)
    item1 = create(:json_archival_object,
                   :resource => {:ref => resource1.uri},
                   :parent => {:ref => series1.uri},
                   :instances => [
                     build(:json_instance, {
                       "instance_type" => "audio",
                       "sub_container" => sub_container
                     })],
                   :publish => true)

    resource2 = create_resource(:publish => false)
    series2 = create(:json_archival_object,
                     :resource => {:ref => resource2.uri},
                     :publish => true)
    item2 = create(:json_archival_object,
                   :resource => {:ref => resource2.uri},
                   :parent => {:ref => series2.uri},
                   :instances => [
                     build(:json_instance, {
                       "instance_type" => "audio",
                       "sub_container" => sub_container
                     })],
                   :publish => true)


    series1.set_suppressed(true)

    json = TopContainer.sequel_to_jsonmodel([TopContainer[top_container_id]])[0]

    json['is_linked_to_published_record'].should be(false)
  end


  it "an top container record is published if linked to a published record even when linked to a suppressed record" do
    top_container = build(:json_top_container, {})

    top_container_id = TopContainer.create_from_json(top_container, :repo_id => $repo_id).id
    top_container_uri = JSONModel(:top_container).uri_for(top_container_id)

    sub_container = build(:json_sub_container, {
      "top_container" => {
        "ref" => top_container_uri
      }
    })

    resource1 = create_resource(:publish => true)
    series1 = create(:json_archival_object,
                     :resource => {:ref => resource1.uri},
                     :publish => true)
    item1 = create(:json_archival_object,
                   :resource => {:ref => resource1.uri},
                   :parent => {:ref => series1.uri},
                   :instances => [
                     build(:json_instance, {
                       "instance_type" => "audio",
                       "sub_container" => sub_container
                     })],
                   :publish => true)

    resource2 = create_resource(:publish => true)
    series2 = create(:json_archival_object,
                     :resource => {:ref => resource2.uri},
                     :publish => true)
    item2 = create(:json_archival_object,
                   :resource => {:ref => resource2.uri},
                   :parent => {:ref => series2.uri},
                   :instances => [
                     build(:json_instance, {
                       "instance_type" => "audio",
                       "sub_container" => sub_container
                     })],
                   :publish => true)


    series1.set_suppressed(true)

    json = TopContainer.sequel_to_jsonmodel([TopContainer[top_container_id]])[0]

    json['is_linked_to_published_record'].should be(true)
  end

end
