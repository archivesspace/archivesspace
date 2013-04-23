require 'spec_helper'

describe 'Exports controller' do

  it "lets you export an Agent as EAC, even when it is linked to be records from another repo" do

    accession = create(:json_accession)

    create(:json_event,
           'linked_agents' => [{'ref' => '/agents/software/1', 'role' => 'validator'}],
           'linked_records' => [{'ref' => accession.uri, 'role' => 'source'}])


    get '/archival_contexts/softwares/1.xml'
    last_response.should be_ok
    last_response.body.should match(/<eac-cpf/)
  end

end
