require 'spec_helper'

describe 'Delete request controller' do

  def perform_delete(record_uris, current_repo_id = nil)
    uri = "/batch_delete"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")

    body = {:record_uris => record_uris}
    body[:current_repo_id] = current_repo_id if current_repo_id

    JSONModel::HTTP.post_json(url, body)
  end


  it "can delete multiple archival records" do
    record_1 = create(:json_resource)
    record_2 = create(:json_archival_object)
    record_3 = create(:json_accession)
    record_4 = create(:json_digital_object)
    record_5 = create(:json_digital_object_component)


    uri = "/batch_delete"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")

    response = perform_delete([record_1.uri, record_2.uri, record_3.uri, record_4.uri, record_5.uri])
    expect(response.code).to eq('200')

    expect {
      JSONModel(:resource).find(record_1.id)
    }.to raise_error(RecordNotFound)

    expect {
      JSONModel(:archival_object).find(record_2.id)
    }.to raise_error(RecordNotFound)

    expect {
      JSONModel(:accession).find(record_3.id)
    }.to raise_error(RecordNotFound)

    expect {
      JSONModel(:digital_object).find(record_4.id)
    }.to raise_error(RecordNotFound)

    expect {
      JSONModel(:digital_object_component).find(record_5.id)
    }.to raise_error(RecordNotFound)
  end


  it "throws an exception when one of the uris does not exist" do
    a_404_uri = "/idontexist"

    response = perform_delete([a_404_uri])

    expect(response.code).to eq('403')

    response_json = ASUtils.json_parse(response.body)

    expect(response_json["error"]["failures"][0]["uri"]).to eq(a_404_uri)
  end


  describe 'agent cross-repository delete guard' do
    it "forwards current_repo_id, so an agent linked only within the caller's own repository can be bulk-deleted" do
      repo_a = create(:repo)

      RequestContext.put(:repo_id, repo_a.id)
      agent = AgentPerson.create_from_json(build(:json_agent_person))
      create(:json_accession, 'linked_agents' => [{
                                                     'ref' => agent.uri,
                                                     'role' => 'source'
                                                   }])

      response = perform_delete([agent.uri], repo_a.id)

      expect(response.code).to eq('200')

      expect {
        JSONModel(:agent_person).find(agent.id)
      }.to raise_error(RecordNotFound)
    end
  end

end
