require 'spec_helper'
require_relative 'container_spec_helper'
require_relative 'factories'

describe 'Record transfers' do

  before(:each) do
    @target_repo = create(:unselected_repo, {:repo_code => "TARGET_REPO_#{Time.now.to_i}"})
  end


  it "allows an accession to be transferred from one repository to another" do

    # Picked rights statement here because it's a nested record with its own
    # repo_id column (since the column is needed for a uniqueness check)
    acc_id = create(:json_accession,
                    :rights_statements => [build(:json_rights_statement)]).id

    Accession[acc_id].transfer_to_repository(@target_repo)

    RequestContext.open(:repo_id => @target_repo.id) do
      json = Accession.to_jsonmodel(acc_id)

      expect(JSONModel.parse_reference(json['uri'])[:repository]).to eq(@target_repo.uri)
    end

  end


  it "preserves relationships with global records (like subjects)" do
    subject = create(:json_subject)

    acc_id = create(:json_accession,
                    :subjects => [{'ref' => subject.uri}]).id

    Accession[acc_id].transfer_to_repository(@target_repo)

    RequestContext.open(:repo_id => @target_repo.id) do
      json = Accession.to_jsonmodel(acc_id)

      expect(json['subjects'][0]['ref']).to eq(subject.uri)
    end
  end


  it "discards relationships with records from the original repository" do
    resource = create(:json_resource)

    acc_id = create(:json_accession,
                    :related_resources => [{'ref' => resource.uri}]).id

    Accession[acc_id].transfer_to_repository(@target_repo)

    RequestContext.open(:repo_id => @target_repo.id) do
      json = Accession.to_jsonmodel(acc_id)

      expect(json['related_resources']).to eq([])
    end
  end


  it "marks its old URI as deleted" do
    acc_id = create(:json_accession).id

    acc = Accession[acc_id]
    old_uri = acc.uri

    acc.transfer_to_repository(@target_repo)

    expect(Tombstone.filter(:uri => old_uri).count).to eq(1)
  end


  it "undoes deletions when transfers are reversed" do
    allow(RealtimeIndexing).to receive(:record_delete).and_call_original

    acc_id = create(:json_accession).id
    source_repo = Repository[$repo_id]

    old_uri = JSONModel(:accession).uri_for(acc_id, repo_id: source_repo.id)
    new_uri = JSONModel(:accession).uri_for(acc_id, repo_id: @target_repo.id)

    acc = Accession[acc_id]
    acc.transfer_to_repository(@target_repo)
    expect(RealtimeIndexing).to have_received(:record_delete).with(old_uri)
    expect(Tombstone.filter(uri: old_uri).count).to eq(1)
    expect(Tombstone.filter(uri: new_uri).count).to eq(0)

    acc = Accession[acc_id]
    acc.transfer_to_repository(source_repo)
    expect(RealtimeIndexing).to have_received(:record_delete).with(new_uri)
    expect(Tombstone.filter(uri: old_uri).count).to eq(0)
    expect(Tombstone.filter(uri: new_uri).count).to eq(1)

    # transfer_all
    acc2_id = create(:json_accession).id
    Accession.transfer_all(source_repo, @target_repo)
    expect(Tombstone.filter(uri: Regexp.new(source_repo.uri+"/accessions")).count).to eq(2)
    Accession.transfer_all(@target_repo, source_repo)
    expect(Tombstone.filter(uri: Regexp.new(source_repo.uri+"/accessions")).count).to eq(0)
    expect(Tombstone.filter(uri: Regexp.new(@target_repo.uri+"/accessions")).count).to eq(2)
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
      expect(JSONModel.parse_reference(Event.to_jsonmodel(event.id).uri)[:repository]).to eq(@target_repo.uri)
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
    expect(original_event['linked_records'].length).to eq(1)
    expect(original_event['linked_records'][0]['ref']).to eq(unrelated_accession.uri)

    # And there's a parallel event in the target repository that cloned the
    # original event.
    expect(Event.any_repo.all.any? {|e|
      (e.repo_id == @target_repo.id) && (e.outcome_note == "a test outcome note")
    }).to be_truthy
  end


  it "allows a resource to be transferred from one repository to another" do
    resource = create(:json_resource)

    ao1 = create(:json_archival_object,
                 :title => "hello",
                 :dates => [],
                 :resource => {'ref' => resource.uri})

    ao2 = create(:json_archival_object,
                 :title => "world",
                 :dates => [],
                 :resource => {'ref' => resource.uri},
                 :parent => {'ref' => ao1.uri})


    Resource[resource.id].transfer_to_repository(@target_repo)

    RequestContext.open(:repo_id => @target_repo.id) do
      tree = Resource[resource.id].tree

      expect(tree['children'][0]['title']).to eq('hello')
      expect(tree['children'][0]['children'][0]['title']).to eq('world')
    end
  end

  it "transfers top containers too if they're only referenced by the record being transferred" do
    box1 = create(:json_top_container, :barcode => "box1_barcode")
    box2 = create(:json_top_container, :barcode => "box2_barcode")

    resource = create(:json_resource)
    ao1 = create(:json_archival_object,
                 :title => "hello",
                 :instances => [build_instance(box1), build_instance(box2)],
                 :resource => {'ref' => resource.uri})

    ao2 = create(:json_archival_object,
                 :title => "world",
                 :resource => {'ref' => resource.uri},
                 :parent => {'ref' => ao1.uri})

    Resource[resource.id].transfer_to_repository(@target_repo)

    RequestContext.open(:repo_id => @target_repo.id) do
      instances = ArchivalObject.to_jsonmodel(ao1.id)["instances"]
      expect(instances.length).to eq(2)

      moved_box1 = TopContainer.this_repo[:barcode => 'box1_barcode']
      moved_box2 = TopContainer.this_repo[:barcode => 'box2_barcode']

      # They have indeed moved
      expect(moved_box1.repo_id).to eq(@target_repo.id)
      expect(moved_box2.repo_id).to eq(@target_repo.id)

      # And they have the same ID as the original box
      expect(moved_box1.id).to eq(box1.id)
      expect(moved_box2.id).to eq(box2.id)

      expect(instances.map {|instance| instance['sub_container']['top_container']['ref']}).to include(moved_box1.uri)
      expect(instances.map {|instance| instance['sub_container']['top_container']['ref']}).to include(moved_box2.uri)
    end
  end

  it "raises error if transfering a record that shares a top container with another record" do
    box1 = create(:json_top_container, :barcode => "box1_barcode")
    box2 = create(:json_top_container, :barcode => "box2_barcode")

    accession = create(:json_accession, {
                   "instances" => [build_instance(box1), build_instance(box2)]
                 })

    unrelated_resource = create(:json_resource, {
                                  "instances" => [build_instance(box1), build_instance(box2)]
                                })


    resource = create(:json_resource)
    ao1 = create(:json_archival_object,
                 :title => "hello",
                 :instances => [build_instance(box1), build_instance(box2)],
                 :resource => {'ref' => resource.uri})

    ao2 = create(:json_archival_object,
                 :title => "world",
                 :resource => {'ref' => resource.uri},
                 :parent => {'ref' => ao1.uri})

    expect { Resource[resource.id].transfer_to_repository(@target_repo) }.to raise_error { |e|
      expect(e).to be_a(TransferConstraintError)
      expect(e.conflicts.length).to eq(2)
      expect(e.conflicts[box1.uri][0][:message]).to eq('TOP_CONTAINER_IN_USE')
      expect(e.conflicts[box2.uri][0][:message]).to eq('TOP_CONTAINER_IN_USE')
    }
  end

  it "won't transfer any top containers if one if in use by another record" do
    box1 = create(:json_top_container)
    box2 = create(:json_top_container)
    box1_repo_id = TopContainer[box1.id][:repo_id]
    box2_repo_id = TopContainer[box2.id][:repo_id]
    accession1 = create(:json_accession, {
                          "instances" => [build_instance(box1), build_instance(box2)]
                        })
    accession2 = create(:json_accession, {
                          "instances" => [build_instance(box2)]
                        })

    expect { Accession[accession1.id].transfer_to_repository(@target_repo) }.to raise_error TransferConstraintError
    expect(TopContainer[box1.id][:repo_id]).to eq box1_repo_id
    expect(TopContainer[box2.id][:repo_id]).to eq box2_repo_id
  end

  it "moves linked digital objects as a part of a transfer" do
    digital_object = create(:json_digital_object)
    do_instance = build(:json_instance_digital,
                        :digital_object => {:ref => digital_object.uri})

    resource = create(:json_resource,
                      :instances => [do_instance])
    ao = create(:json_archival_object,
                :title => "hello again",
                :instances => [do_instance],
                :resource => {'ref' => resource.uri})

    # We won't assert on this, but let's just ensure that instances sharing a
    # digital object doesn't cause a problem.
    create(:json_archival_object,
           :title => "and another",
           :instances => [do_instance],
           :resource => {'ref' => resource.uri})

    Resource[resource.id].transfer_to_repository(@target_repo)

    RequestContext.open(:repo_id => @target_repo.id) do
      moved_digital_object = DigitalObject.this_repo[digital_object.id]

      instances = ArchivalObject.to_jsonmodel(ao.id)["instances"]
      expect(instances.length).to eq(1)

      expect(instances[0]['digital_object']['ref']).to eq moved_digital_object.uri
    end
  end

  it "will not transfer digital objects linked to a repository-scoped parent" do
    digital_object = create(:json_digital_object)
    do_instance = build(:json_instance_digital,
                        :digital_object => {:ref => digital_object.uri})

    resource = create(:json_resource)

    ao = create(:json_archival_object,
                :title => "hello again",
                :instances => [do_instance],
                :resource => {'ref' => resource.uri})

    begin
      DigitalObject[digital_object.id].transfer_to_repository(@target_repo)
    rescue TransferConstraintError
      error = $!
    end

    expect(error).not_to be_nil
    expect(error.conflicts[ao.uri][0][:message]).to eq('DIGITAL_OBJECT_HAS_LINK')

  end

  it "detects when a digital object can't be moved as a part of a transfer" do
    digital_object = create(:json_digital_object)
    do_instance = build(:json_instance_digital,
                        :instance_type => 'digital_object',
                        :digital_object => {:ref => digital_object.uri})


    resource = create(:json_resource,
                      :instances => [do_instance])

    ao = create(:json_archival_object,
                :title => "hello again",
                :instances => [do_instance],
                :resource => {'ref' => resource.uri})

    unrelated_accession = create(:json_accession,
                                 :instances => [do_instance])

    error = nil

    begin
      Resource[resource.id].transfer_to_repository(@target_repo)
    rescue TransferConstraintError
      error = $!
    end

    expect(error).not_to be_nil
    expect(error.conflicts[unrelated_accession.uri][0][:message]).to eq('DIGITAL_OBJECT_IN_USE')
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

      expect(tree['children'][0]['title']).to eq('hello')
      expect(tree['children'][0]['children'][0]['title']).to eq('world')
    end
  end

  it "copes when top containers are linked in multiple places within a tree" do
    box = create(:json_top_container, :barcode => "box_barcode")

    resource = create(:json_resource)
    ao1 = create(:json_archival_object,
                 :title => "hello",
                 :instances => [build_instance(box)],
                 :resource => {'ref' => resource.uri})

    ao2 = create(:json_archival_object,
                 :title => "world",
                 :instances => [build_instance(box)],
                 :resource => {'ref' => resource.uri},
                 :parent => {'ref' => ao1.uri})

    # Would previously raise NotFoundException: TopContainer not found
    expect {
      Resource[resource.id].transfer_to_repository(@target_repo)
    }.not_to raise_error
  end

  it "reports an error if a barcode conflict would stop a top container from being transferred" do
    box = create(:json_top_container, :barcode => "unique_barcode")

    resource = create(:json_resource, "title" => "transferred resource")
    ao1 = create(:json_archival_object,
                 :title => "hello",
                 :instances => [build_instance(box)],
                 :resource => {'ref' => resource.uri})

    ao2 = create(:json_archival_object,
                 :title => "world",
                 :resource => {'ref' => resource.uri},
                 :parent => {'ref' => ao1.uri})


    JSONModel.with_repository(@target_repo.id) do
      # The same barcode!
      create(:json_top_container, :barcode => "unique_barcode")
    end

    expect {
      Resource[resource.id].transfer_to_repository(@target_repo)
    }.to raise_error (TransferConstraintError)
  end

  describe 'Assessment transfers' do

    let (:resource) { create(:json_resource, "title" => "transferred resource") }
    let (:accession) { create(:json_accession, "title" => "non-transferred accession") }
    let (:surveyor) { create(:json_agent_person) }
    let (:repository_attributes) {
      {
        'definitions' => [
          {
            'label' => 'A Test Rating',
            'type' => 'rating',
          },
          {
            'label' => 'A Test Format',
            'type' => 'format',
          },
          {
            'label' => 'A Test Conservation Issue',
            'type' => 'conservation_issue',
          }
        ]
      }
    }

    it "transfers an assessment along with its single linked record" do
      assessment = Assessment.create_from_json(build(:json_assessment, {
                                                       'records' => [{'ref' => resource.uri}],
                                                       'surveyed_by' => [{'ref' => surveyor.uri}],
                                                     }))

      Resource[resource.id].transfer_to_repository(@target_repo)

      # This record is gone from the original repository
      expect(Assessment.any_repo.filter(:id => assessment.id, :repo_id => $repo_id).count).to eq(0)

      # But is now present in the new one
      RequestContext.open(:repo_id => @target_repo.id) do
        expect { Assessment[assessment.id] }.not_to raise_error
      end
    end

    def get_test_attribute(definitions, label, attribute_type)
      result = definitions.definitions.find {|d|
        d[:label] == label && d[:type] == attribute_type
      }

      unless result
        raise "Couldn't find matching attribute for '#{label}' and type '#{attribute_type}'"
      end


      {'definition_id' => result[:id], 'value' => '3', 'note' => 'test note'}
    end


    def define_test_attributes(*repo_ids)
      # Define some repository-specific attributes in both our source and target
      # repositories.  They'll have different IDs in the database, but we'll be
      # clever and match them up by label.
      repo_ids.each do |repo_id|
        JSONModel.with_repository(repo_id) do
          RequestContext.open(:repo_id => repo_id) do
            JSONModel(:assessment_attribute_definitions)
              .from_hash(repository_attributes)
              .save
          end
        end
      end
    end

    def ensure_test_attributes_are_present(assessment_json)
      expect(assessment_json.formats.find {|a|
        a['label'] == 'A Test Format' &&
          a['value'] == '3' &&
          a['note'] == 'test note' }).not_to be_nil

      expect(assessment_json.conservation_issues.find {|a|
        a['label'] == 'A Test Conservation Issue' &&
          a['value'] == '3' &&
          a['note'] == 'test note' }).not_to be_nil

      expect(assessment_json.ratings.find {|a|
        a['label'] == 'A Test Rating' &&
          a['value'] == '3' &&
          a['note'] == 'test note' }).not_to be_nil
    end

    it "attempts to preserve repository-specific attributes when transferring an assessment" do
      define_test_attributes($repo_id, @target_repo.id)
      source_repo_definitions = AssessmentAttributeDefinitions.get($repo_id)

      assessment = Assessment.create_from_json(build(:json_assessment, {
                                                       'records' => [{'ref' => resource.uri}],
                                                       'surveyed_by' => [{'ref' => surveyor.uri}],
                                                       'formats' => [get_test_attribute(source_repo_definitions, 'A Test Format', 'format')],
                                                       'conservation_issues' => [get_test_attribute(source_repo_definitions, 'A Test Conservation Issue', 'conservation_issue')],
                                                       'ratings' => [get_test_attribute(source_repo_definitions, 'A Test Rating', 'rating')],
                                                     }))


      # Transfer our resource with its connected assessment
      Resource[resource.id].transfer_to_repository(@target_repo)

      # And verify that the repo-specific attributes made it over
      RequestContext.open(:repo_id => @target_repo.id) do
        assessment_json = Assessment.to_jsonmodel(assessment.id)
        ensure_test_attributes_are_present(assessment_json)
      end
    end


    it "clones an assessment in the target repository when only a subset of its linked records are transferred" do
      assessment = Assessment.create_from_json(build(:json_assessment, {
                                                       'records' => [{'ref' => resource.uri},
                                                                     {'ref' => accession.uri}],
                                                       'surveyed_by' => [{'ref' => surveyor.uri}],
                                                     }))

      Resource[resource.id].transfer_to_repository(@target_repo)

      # This record is still present in the original repository
      expect(Assessment.any_repo.filter(:id => assessment.id, :repo_id => $repo_id).count).to eq(1)

      # But the target repository also contains an assessment that links to our transferred record
      RequestContext.open(:repo_id => @target_repo.id) do
        new_assessment = Assessment.find_relationship(:assessment).who_participates_with(Resource[resource.id]).first
        expect(new_assessment).not_to be_nil
      end
    end

    it "attempts to preserve repository-specific attributes when cloning an assessment" do
      define_test_attributes($repo_id, @target_repo.id)
      source_repo_definitions = AssessmentAttributeDefinitions.get($repo_id)

      assessment = Assessment.create_from_json(build(:json_assessment, {
                                                       'records' => [{'ref' => resource.uri},
                                                                     {'ref' => accession.uri}],
                                                       'surveyed_by' => [{'ref' => surveyor.uri}],
                                                       'formats' => [get_test_attribute(source_repo_definitions, 'A Test Format', 'format')],
                                                       'conservation_issues' => [get_test_attribute(source_repo_definitions, 'A Test Conservation Issue', 'conservation_issue')],
                                                       'ratings' => [get_test_attribute(source_repo_definitions, 'A Test Rating', 'rating')],
                                                     }))

      # Force the test to run without client mode so readonly properties are
      # dropped when from_hash is called.  Exposes the bug that this commit
      # fixes by forcing the unit test to fail the way production did!
      allow(JSONModel).to receive(:client_mode?) { false }

      Resource[resource.id].transfer_to_repository(@target_repo)

      # But the target repository also contains an assessment that links to our transferred record
      RequestContext.open(:repo_id => @target_repo.id) do
        new_assessment = Assessment.find_relationship(:assessment).who_participates_with(Resource[resource.id]).first

        assessment_json = Assessment.to_jsonmodel(new_assessment.id)
        ensure_test_attributes_are_present(assessment_json)
      end
    end
  end

end
