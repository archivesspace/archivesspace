require 'spec_helper'

describe 'Record transfers' do

  before(:each) do
    @target_repo = create(:unselected_repo, {:repo_code => "TARGET_REPO"})
  end


  it "allows an accession to be transferred from one repository to another" do

    # Picked rights statement here because it's a nested record with its own
    # repo_id column (since the column is needed for a uniqueness check)
    acc_id = create(:json_accession,
                    :rights_statements => [build(:json_rights_statement)]).id

    Accession[acc_id].transfer_to_repository(@target_repo)

    RequestContext.open(:repo_id => @target_repo.id) do
      json = Accession.to_jsonmodel(acc_id)

      JSONModel.parse_reference(json['uri'])[:repository].should eq(@target_repo.uri)
    end

  end


  it "preserves relationships with global records (like subjects)" do
    subject = create(:json_subject)

    acc_id = create(:json_accession,
                    :subjects => [{'ref' => subject.uri}]).id

    Accession[acc_id].transfer_to_repository(@target_repo)

    RequestContext.open(:repo_id => @target_repo.id) do
      json = Accession.to_jsonmodel(acc_id)

      json['subjects'][0]['ref'].should eq(subject.uri)
    end
  end


  it "discards relationships with records from the original repository" do
    resource = create(:json_resource)

    acc_id = create(:json_accession,
                    :related_resources => [{'ref' => resource.uri}]).id

    Accession[acc_id].transfer_to_repository(@target_repo)

    RequestContext.open(:repo_id => @target_repo.id) do
      json = Accession.to_jsonmodel(acc_id)

      json['related_resources'].should eq([])
    end
  end


  it "marks its old URI as deleted" do
    acc_id = create(:json_accession).id

    acc = Accession[acc_id]
    old_uri = acc.uri

    acc.transfer_to_repository(@target_repo)

    Tombstone.filter(:uri => old_uri).count.should eq(1)
  end


  it "creates an event to record the transfer" do
    acc_id = create(:json_accession).id

    acc = Accession[acc_id]
    acc.transfer_to_repository(@target_repo)

    Event.any_repo.all.any? {|e|
      json = Event.to_jsonmodel(e)
      json.linked_records.any? {|l| l['ref'] == acc.uri}
    }
  end


  it "transfers events too (when the event only links to the record being transferred)" do
    acc_id = create(:json_accession).id
    person = create(:json_agent_person)

    acc = Accession[acc_id]

    event = create(:json_event,
           :linked_agents => [{'ref' => person.uri, 'role' => 'transmitter'}],
           :linked_records => [{'ref' => acc.uri, 'role' => 'transfer'}])

    acc.transfer_to_repository(@target_repo)

    RequestContext.open(:repo_id => @target_repo.id) do
      JSONModel.parse_reference(Event.to_jsonmodel(event.id).uri)[:repository].should eq(@target_repo.uri)
    end
  end


  it "clones events that reference other records besides the one being transferred" do
    unrelated_accession = create(:json_accession)
    acc_id = create(:json_accession).id
    person = create(:json_agent_person)

    acc = Accession[acc_id]

    event = create(:json_event,
                   :outcome_note => "a test outcome note",
                   :linked_agents => [{'ref' => person.uri, 'role' => 'transmitter'}],
                   :linked_records => [{'ref' => acc.uri, 'role' => 'transfer'},
                                       {'ref' => unrelated_accession.uri, 'role' => 'transfer'}])

    acc.transfer_to_repository(@target_repo)

    # The original event now has a single linked record
    original_event = Event.to_jsonmodel(event.id)
    original_event['linked_records'].length.should eq(1)
    original_event['linked_records'][0]['ref'].should eq(unrelated_accession.uri)

    # And there's a parallel event in the target repository that cloned the
    # original event.
    Event.any_repo.all.any? {|e|
      (e.repo_id == @target_repo.id) && (e.outcome_note == "a test outcome note")
    }.should be(true)
  end



  it "allows a resource to be transferred from one repository to another" do
    resource = create(:json_resource)

    ao1 = create(:json_archival_object,
                 :title => "hello",
                 :resource => {'ref' => resource.uri})

    ao2 = create(:json_archival_object,
                 :title => "world",
                 :resource => {'ref' => resource.uri},
                 :parent => {'ref' => ao1.uri})


    Resource[resource.id].transfer_to_repository(@target_repo)

    RequestContext.open(:repo_id => @target_repo.id) do
      tree = Resource[resource.id].tree

      tree['children'][0]['title'].should eq('hello')
      tree['children'][0]['children'][0]['title'].should eq('world')
    end
  end


  it "allows a digital object to be transferred from one repository to another" do
    digital_object = create(:json_digital_object)

    doc1 = create(:json_digital_object_component,
                  :title => "hello",
                  :digital_object => {'ref' => digital_object.uri})

    doc2 = create(:json_digital_object_component,
                  :title => "world",
                  :digital_object => {'ref' => digital_object.uri},
                  :parent => {'ref' => doc1.uri})


    DigitalObject[digital_object.id].transfer_to_repository(@target_repo)

    RequestContext.open(:repo_id => @target_repo.id) do
      tree = DigitalObject[digital_object.id].tree

      tree['children'][0]['title'].should eq('hello')
      tree['children'][0]['children'][0]['title'].should eq('world')
    end
  end

end
