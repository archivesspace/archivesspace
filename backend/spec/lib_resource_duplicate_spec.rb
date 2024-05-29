require "spec_helper"
require_relative "../app/lib/resource/duplicate"

describe "Resource Duplicate" do
  let(:now) { Time.now.to_i }
  let(:agent_1) { create(:json_agent_person) }
  let(:agent_2) { create(:json_agent_software_full_subrec) }
  let(:agent_3) { create(:json_agent_family_full_subrec) }
  let(:agent_4) { create(:json_agent_corporate_entity_full_subrec) }

  let(:subject_1) do
    subject = create(:json_subject,
      :metadata_rights_declarations => [
        build(:json_metadata_rights_declaration),
        build(:json_metadata_rights_declaration),
        build(:json_metadata_rights_declaration)
      ],
      :external_documents => [
        build(:json_external_document),
        build(:json_external_document),
        build(:json_external_document)
      ]
    )
  end

  let(:accession_1) { create(:json_accession) }
  let(:accession_2) { create(:json_accession) }

  let(:digital_object_1) { create(:json_digital_object) }
  let(:digital_object_2) { create(:json_digital_object) }

  let(:classification_1) do
    create(:json_classification,
      :title => "Classification Title 1 #{now}",
      :identifier => "Classification identifies 1 #{now}",
      :description => "Classification Description 1 #{now}",
      :creator => { 'ref' => agent_1.uri }
    )
  end

  let(:top_container) { create_top_container() }

  let(:resource) do
    create_resource(
      title: "Resource Title #{now}",
      publish: true,
      ead_id: "Resource EAD ID #{now}",
      :lang_materials => [
        build(:json_lang_material),
        build(:json_lang_material_with_note),
        build(:json_lang_material)
      ],
      :extents => [
        build(:json_extent),
        build(:json_extent),
        build(:json_extent)
      ],
      :dates => [
        build(:json_date),
        build(:json_date_single)
      ],
      :notes => [
        build(:json_note_multipart),
        build(:json_note_bibliography)
      ],
      :external_documents => [
        build(:json_external_document),
        build(:json_external_document),
        build(:json_external_document)
      ],
      :rights_statements => [
        build(
          :json_rights_statement,
          :linked_agents => [
            'ref' => agent_4.uri,
          ],
          :external_documents => [
            build(:json_rights_statement_external_document, :identifier_type => 'trove')
          ]
        ),
        build(:json_rights_statement),
        build(:json_rights_statement)
      ],
      :metadata_rights_declarations => [
        build(:json_metadata_rights_declaration),
        build(:json_metadata_rights_declaration),
        build(:json_metadata_rights_declaration)
      ],
      :instances => [
        build(
          :json_instance,
          :sub_container => build(:json_sub_container, :top_container => { :ref => top_container.uri })
        ),
        build(
          :json_instance_digital,
          :digital_object => { :ref => digital_object_1.uri }
        )
      ],
      :deaccessions => [
        build(:json_deaccession,
          :extents => [
            build(:json_extent),
            build(:json_extent),
            build(:json_extent)
          ]
        )
      ],
      :collection_management => build(:json_collection_management),
      :user_defined => {
        :boolean_1 => generate(:boolean_or_nil),
        :boolean_2 => generate(:boolean_or_nil),
        :boolean_3 => generate(:boolean_or_nil),
        :integer_1 => generate(:number),
        :integer_2 => generate(:number),
        :integer_3 => generate(:number),
        :real_1 => generate(:number),
        :real_2 => generate(:number),
        :real_3 => generate(:number),
        :string_1 => 'string 1',
        :string_2 => 'string 2',
        :string_3 => 'string 3',
        :text_1 => 'text 1',
        :text_2 => 'text 2',
        :text_3 => 'text 3',
        :text_4 => 'text 4',
        :text_5 => 'text 5',
        :date_1 => generate(:yyyy_mm_dd),
        :date_2 => generate(:yyyy_mm_dd),
        :date_3 => generate(:yyyy_mm_dd),
        :enum_1 => generate(:user_defined_enum_1),
        :enum_2 => generate(:user_defined_enum_2),
        :enum_3 => generate(:user_defined_enum_3),
        :enum_4 => generate(:user_defined_enum_4)
      },
      :linked_agents => [
        {
          'ref' => agent_1.uri,
          'role' => 'creator'
        }
      ],
      :subjects => [
        { 'ref' => subject_1.uri }
      ],
      :related_accessions => [
        { 'ref' => accession_1.uri }
      ],
      :classifications => [
        { 'ref' => classification_1.uri }
      ]
    )
  end

  let(:archival_object_parent_1) do
    create_archival_object({
      :title => "Archival Object Parent 1 #{now}",
      :resource => { :ref => resource.uri },
      :ref_id => "archival_object_parent_1_#{now}",
      :lang_materials => [build(:json_lang_material_with_note)],
      :dates => [],
      :extents => [
        build(:json_extent)
      ],
      :subjects => [],
      :notes => [
        build(:json_note_multipart)
        # build(:json_note_definedlist)
      ],
      :external_documents => [],
      :rights_statements => [],
      :instances => [
        build(
          :json_instance_digital,
          :digital_object => { :ref => digital_object_2.uri }
        )
      ],
      :linked_agents => [
        {
          'ref' => agent_1.uri,
          'role' => 'creator'
        },
        {
          'ref' => agent_1.uri,
          'role' => 'source'
        },
        {
          'ref' => agent_2.uri,
          'role' => 'creator'
        }
      ],
      :subjects => [
        { 'ref' => subject_1.uri }
      ],
      :accession_links => [
        { 'ref' => accession_1.uri },
        { 'ref' => accession_2.uri }
      ]
    })
  end

  let(:archival_object_parent_2) do
    create_archival_object({
      :title => "Archival Object Parent 2 #{now}",
      :resource => { :ref => resource.uri },
      :ref_id => "archival_object_parent_2_#{now}",
      :lang_materials => [
        build(:json_lang_material),
        build(:json_lang_material_with_note)
      ],
      :dates => [
        build(:json_date),
        build(:json_date_single)
      ],
      :notes => [
        build(:json_note_multipart),
        build(:json_note_multipart)
      ],
      :instances => [
        build(:json_instance, :sub_container => build(:json_sub_container, :top_container => { :ref => top_container.uri }))
      ],
      :linked_agents => [
        {
          'ref' => agent_1.uri,
          'role' => 'creator'
        },
        {
          'ref' => agent_2.uri,
          'role' => 'subject'
        }
      ]
    })
  end

  let(:archival_object_child_1) do
    create_archival_object({
      :title => "Archival Object Child 1 #{now}",
      :resource => { :ref => resource.uri },
      :parent => { 'ref' => archival_object_parent_1.uri },
      :ref_id => "archival_object_child_1_#{now}",
      :lang_materials => [
        build(:json_lang_material),
        build(:json_lang_material_with_note)
      ],
      :dates => [
        build(:json_date),
        build(:json_date_single)
      ],
      :notes => [
        build(:json_note_multipart),
        build(:json_note_multipart)
      ],
      :external_documents => [
        build(:json_external_document)
      ],
      :instances => [
        build(:json_instance, :sub_container => build(:json_sub_container, :top_container => { :ref => top_container.uri }))
      ]
    })
  end

  let(:archival_object_sub_child_1) do
    create_archival_object({
      :title => "Archival Object Sub Child 1 #{now}",
      :resource => { :ref => resource.uri },
      :parent => { 'ref' => archival_object_child_1.uri },
      :ref_id => "archival_object_sub_child_1_#{now}",
      :instances => [
        build(:json_instance, :sub_container => build(:json_sub_container, :top_container => { :ref => top_container.uri }))
      ]
    })
  end

  let(:archival_object_sub_sub_child_1) do
    create_archival_object({
      :title => "Archival Object Sub Sub Child 1 #{now}",
      :resource => { :ref => resource.uri },
      :parent => { 'ref' => archival_object_sub_child_1.uri },
      :ref_id => "archival_object_sub_sub_child_1_#{now}",
      notes: [
        build(:json_note_multipart)
      ],
      accession_links: [
        { 'ref' => accession_1.uri },
        { 'ref' => accession_2.uri }
      ],
      :instances => [
        build(:json_instance, :sub_container => build(:json_sub_container, :top_container => { :ref => top_container.uri }))
      ]
    })
  end

  let(:archival_object_sub_sub_child_2) do
    create_archival_object({
      :title => "Archival Object Sub Sub Child 2 #{now}",
      :resource => { :ref => resource.uri },
      :parent => { 'ref' => archival_object_sub_child_1.uri },
      :ref_id => "archival_object_sub_sub_child_2_#{now}",
      :instances => [
        build(:json_instance, :sub_container => build(:json_sub_container, :top_container => { :ref => top_container.uri }))
      ]
    })
  end

  let(:archival_object_sub_sub_sub_child_1) do
    create_archival_object({
      :title => "Archival Object Sub Sub Sub Child 1 #{now}",
      :resource => { :ref => resource.uri },
      :parent => { 'ref' => archival_object_sub_sub_child_1.uri },
      :ref_id => "archival_object_sub_sub_sub_child_1_#{now}",
      :instances => [
        build(:json_instance, :sub_container => build(:json_sub_container, :top_container => { :ref => top_container.uri }))
      ]
    })
  end

  subject { ::Lib::Resource::Duplicate.new(resource.id) }

  it 'does not create any records if at least one record is invalid', :disable_database_transaction do
    reload_resource = ::Resource.where(id: resource.id).first
    resource = reload_resource

     # Load source archival objects before duplication process
    archival_object_parent_1_json_model = ::ArchivalObject.to_jsonmodel(archival_object_parent_1)
    archival_object_parent_2_json_model = ::ArchivalObject.to_jsonmodel(archival_object_parent_2)
    archival_object_child_1_json_model = ::ArchivalObject.to_jsonmodel(archival_object_child_1)
    archival_object_sub_child_1_json_model = ::ArchivalObject.to_jsonmodel(archival_object_sub_child_1)
    archival_object_sub_sub_child_1_json_model = ::ArchivalObject.to_jsonmodel(archival_object_sub_sub_child_1)
    archival_object_sub_sub_child_2_json_model = ::ArchivalObject.to_jsonmodel(archival_object_sub_sub_child_2)
    archival_object_sub_sub_sub_child_1_json_model = ::ArchivalObject.to_jsonmodel(archival_object_sub_sub_sub_child_1)

    original_total_records_count = total_records_count
    resource_graph_before = object_graph_to_hash(resource.object_graph)

    # Ensure archival_object_parent_1 has no dates to force invalidation directly in the database, by setting title to NULL
    expect(archival_object_parent_1_json_model[:dates]).to eq []

    # Make archival object invalid, by directly updating it on the database to bypass model validation.
    DB.open do |db|
      db.execute("UPDATE archival_object SET title=NULL WHERE id = #{archival_object_parent_1.id}")
    end

    expect(subject.duplicate).to eq false
    expect(subject.errors.length).to eq 1
    # NOTE: This is not the actual error that is going to be raised when the system runs.
    #       JSONModel::ValidationException is raised only on the specs, because it uses the client JSONModel
    expect(subject.errors[0][:error]).to eq "last_error #<JSONModel::ValidationException: #<:ValidationException: {:errors=>{\"dates\"=>[\"one or more required (or enter a Title)\"], \"title\"=>[\"must not be an empty string (or enter a Date)\"]}}>>."

    after_duplicate_failed_total_records_count = total_records_count
    resource_graph_after = object_graph_to_hash(resource.object_graph)
    expect(original_total_records_count).to eq after_duplicate_failed_total_records_count
    expect(resource_graph_after).to eq resource_graph_before
  end

  it 'does not create any records if the first resource identifier field is greater than 50 characters' do
    resource_json_model = ::Resource.to_jsonmodel(resource)
    resource_json_model.id_0 = 'A'*50
    resource_json_model.save

    reload_resource = ::Resource.where(id: resource.id).first
    resource = reload_resource

    # Keep track of created records
    original_total_records_count = total_records_count
    resource_graph_before = object_graph_to_hash(resource.object_graph)

    # Duplicate the Resource
    expect(subject.duplicate).to eq false
    expect(subject.errors.length).to eq 1
    expect(subject.errors).to eq [{ :error => "Failed to duplicate resource from resource with id #{resource.id}; Validation error id_0 Max length is 50 characters." }]

    after_duplicate_failed_total_records_count = total_records_count
    resource_graph_after = object_graph_to_hash(resource.object_graph)
    expect(original_total_records_count).to eq after_duplicate_failed_total_records_count
    expect(resource_graph_after).to eq resource_graph_before
  end

  it 'successfully duplicates a resource when it does not have archival objects' do
    # For some reason id_0 is missing from the original resource. We have to reload the object in order to be present.
    reload_resource = ::Resource.where(id: resource.id).first
    resource = reload_resource

    expect(resource.children.count).to eq 0

    # Keep track of created records
    original_total_records_count = total_records_count
    resource_graph_before = object_graph_to_hash(resource.object_graph)

    # Duplicate the Resource
    expect(subject.duplicate).to eq true
    expect(subject.errors).to eq []

    # Ensure related records are only linked to the new resource/archival objects and thay are not duplicated.
    after_duplicate_records_count = total_records_count
    expect(original_total_records_count[:subjects]).to eq after_duplicate_records_count[:subjects]
    expect(original_total_records_count[:classifications]).to eq after_duplicate_records_count[:classifications]
    expect(original_total_records_count[:accessions]).to eq after_duplicate_records_count[:accessions]
    expect(original_total_records_count[:agent_persons]).to eq after_duplicate_records_count[:agent_persons]
    expect(original_total_records_count[:agent_families]).to eq after_duplicate_records_count[:agent_families]
    expect(original_total_records_count[:agent_corporate_entities]).to eq after_duplicate_records_count[:agent_corporate_entities]
    expect(original_total_records_count[:digital_objects]).to eq after_duplicate_records_count[:digital_objects]

    # Ensure the resource graph for source resource is exactly the same after duplication.
    resource_graph_after = object_graph_to_hash(resource.object_graph)
    expect(resource_graph_after).to eq resource_graph_before

    # Load duplicated resource and convert it to json model
    find_resource_duplicated = ::Resource.where(id: subject.resource.id).to_a
    expect(find_resource_duplicated.length).to eq 1
    resource_duplicated = find_resource_duplicated[0]
    resource_duplicated_json_model = ::Resource.to_jsonmodel(resource_duplicated)

    # Convert source resource to json model
    resource_json_model = ::Resource.to_jsonmodel(resource)

    resource_duplicated_graph = object_graph_to_hash(resource_duplicated.object_graph)
    resource_graph_before.each do |model, ids|
      expect(resource_duplicated_graph[model].length).to eq ids.length
      # Expect ids to be different
      expect(ids & resource_duplicated_graph[model]).to eq []
    end
  end

  it 'successfully duplicates a resource with all its archival objects' do
    # For some reason id_0 is missing from the original resource. We have to reload the object in order to be present.
    reload_resource = ::Resource.where(id: resource.id).first
    resource = reload_resource

     # Load source archival objects before duplication process
    archival_object_parent_1_json_model = ::ArchivalObject.to_jsonmodel(archival_object_parent_1)
    archival_object_parent_2_json_model = ::ArchivalObject.to_jsonmodel(archival_object_parent_2)
    archival_object_child_1_json_model = ::ArchivalObject.to_jsonmodel(archival_object_child_1)
    archival_object_sub_child_1_json_model = ::ArchivalObject.to_jsonmodel(archival_object_sub_child_1)
    archival_object_sub_sub_child_1_json_model = ::ArchivalObject.to_jsonmodel(archival_object_sub_sub_child_1)
    archival_object_sub_sub_child_2_json_model = ::ArchivalObject.to_jsonmodel(archival_object_sub_sub_child_2)
    archival_object_sub_sub_sub_child_1_json_model = ::ArchivalObject.to_jsonmodel(archival_object_sub_sub_sub_child_1)

    # Keep track of created records
    original_total_records_count = total_records_count
    resource_graph_before = object_graph_to_hash(resource.object_graph)

    # Duplicate the Resource
    expect(subject.duplicate).to eq true
    expect(subject.errors).to eq []

    # Ensure related records are only linked to the new resource/archival objects and thay are not duplicated.
    after_duplicate_records_count = total_records_count
    expect(original_total_records_count[:subjects]).to eq after_duplicate_records_count[:subjects]
    expect(original_total_records_count[:classifications]).to eq after_duplicate_records_count[:classifications]
    expect(original_total_records_count[:accessions]).to eq after_duplicate_records_count[:accessions]
    expect(original_total_records_count[:agent_persons]).to eq after_duplicate_records_count[:agent_persons]
    expect(original_total_records_count[:agent_families]).to eq after_duplicate_records_count[:agent_families]
    expect(original_total_records_count[:agent_corporate_entities]).to eq after_duplicate_records_count[:agent_corporate_entities]
    expect(original_total_records_count[:digital_objects]).to eq after_duplicate_records_count[:digital_objects]

    # Ensure the resource graph for source resource is exactly the same after duplication.
    resource_graph_after = object_graph_to_hash(resource.object_graph)
    expect(resource_graph_after).to eq resource_graph_before

    # Load duplicated resource and convert it to json model
    find_resource_duplicated = ::Resource.where(id: subject.resource.id).to_a
    expect(find_resource_duplicated.length).to eq 1
    resource_duplicated = find_resource_duplicated[0]
    resource_duplicated_json_model = ::Resource.to_jsonmodel(resource_duplicated)

    # Convert source resource to json model
    resource_json_model = ::Resource.to_jsonmodel(resource)

    resource_duplicated_graph = object_graph_to_hash(resource_duplicated.object_graph)
    resource_graph_before.each do |model, ids|
      expect(resource_duplicated_graph[model].length).to eq ids.length
      # Expect ids to be different
      expect(ids & resource_duplicated_graph[model]).to eq []
    end

    # Ensure the duplicated resource is not published
    expect(resource_json_model.publish).to eq true
    expect(resource_duplicated_json_model.publish).to eq false

    # Check resource and related records
    resource_source_values = resource.values
    resource_duplicated_values = resource_duplicated.values
    expect(resource_duplicated_values[:id_0]).to eq "[Duplicated] #{resource_source_values[:id_0]}"
    expect(resource_duplicated_values[:title]).to eq "[Duplicated] #{resource_source_values[:title]}"
    expect(resource_duplicated_values[:ead_id]).to eq "[Duplicated] #{resource_source_values[:ead_id]}"
    expect(resource_duplicated_values).to include(resource_to_match(resource))
    expect_resource_records_to_match(resource_duplicated_json_model, resource_json_model)

    # Check parent archival objects
    duplicated_parent_archival_objects = resource_duplicated.children.to_a
    expect(duplicated_parent_archival_objects.count).to eq 2

    # Check archival object parent 1
    expect(duplicated_parent_archival_objects[0].parent_id).to eq nil
    expect(duplicated_parent_archival_objects[0].ref_id).to_not eq archival_object_parent_1.ref_id
    expect(duplicated_parent_archival_objects[0]).to have_attributes(archival_object_to_match(archival_object_parent_1))
    duplicated_archival_object_parent_1_json_model = ::ArchivalObject.to_jsonmodel(duplicated_parent_archival_objects[0])
    expect_archival_object_records_to_match(
      duplicated_archival_object_parent_1_json_model,
      archival_object_parent_1_json_model
    )

    # Check archival object parent 2
    expect(duplicated_parent_archival_objects[1].parent_id).to eq nil
    expect(duplicated_parent_archival_objects[1].ref_id).to_not eq archival_object_parent_2.ref_id
    expect(duplicated_parent_archival_objects[1]).to have_attributes(archival_object_to_match(archival_object_parent_2))
    duplicated_archival_object_parent_2_json_model = ::ArchivalObject.to_jsonmodel(duplicated_parent_archival_objects[1])
    expect_archival_object_records_to_match(
      duplicated_archival_object_parent_2_json_model,
      archival_object_parent_2_json_model
    )

    # Check children of parent archival objects
    duplicated_children_archival_objects = duplicated_parent_archival_objects[0].children.to_a
    expect(duplicated_children_archival_objects.count).to eq 1
    expect(duplicated_parent_archival_objects[1].children.to_a.length).to eq 0

    # Check children archival object 1
    expect(duplicated_children_archival_objects[0].parent_id).to eq duplicated_parent_archival_objects[0].id
    expect(duplicated_children_archival_objects[0].ref_id).to_not eq archival_object_child_1.ref_id
    expect(duplicated_children_archival_objects[0]).to have_attributes(archival_object_to_match(archival_object_child_1))
    duplicated_archival_object_child_1_json_model = ::ArchivalObject.to_jsonmodel(duplicated_children_archival_objects[0])
    expect_archival_object_records_to_match(
      duplicated_archival_object_child_1_json_model,
      archival_object_child_1_json_model
    )

    # Check sub children of children archival objects
    duplicated_sub_children_archival_objects = duplicated_children_archival_objects[0].children.to_a
    expect(duplicated_sub_children_archival_objects.count).to eq 1

    # Check sub children archival object 1
    expect(duplicated_sub_children_archival_objects[0].parent_id).to eq duplicated_children_archival_objects[0].id
    expect(duplicated_sub_children_archival_objects[0].ref_id).to_not eq archival_object_sub_child_1.ref_id
    expect(duplicated_sub_children_archival_objects[0]).to have_attributes(archival_object_to_match(archival_object_sub_child_1))
    duplicated_archival_object_sub_child_1_json_model = ::ArchivalObject.to_jsonmodel(duplicated_sub_children_archival_objects[0])
    expect_archival_object_records_to_match(
      duplicated_archival_object_sub_child_1_json_model,
      archival_object_sub_child_1_json_model
    )

    # Check sub sub children of children archival objects
    duplicated_sub_sub_children_archival_objects = duplicated_sub_children_archival_objects[0].children.to_a
    expect(duplicated_sub_sub_children_archival_objects.count).to eq 2

    # Check sub sub children archival object 1
    expect(duplicated_sub_sub_children_archival_objects[0].parent_id).to eq duplicated_sub_children_archival_objects[0].id
    expect(duplicated_sub_sub_children_archival_objects[0].ref_id).to_not eq archival_object_sub_sub_child_1.ref_id
    expect(duplicated_sub_sub_children_archival_objects[0]).to have_attributes(archival_object_to_match(archival_object_sub_sub_child_1))
    duplicated_archival_object_sub_sub_child_1_json_model = ::ArchivalObject.to_jsonmodel(duplicated_sub_sub_children_archival_objects[0])
    expect_archival_object_records_to_match(
      duplicated_archival_object_sub_sub_child_1_json_model,
      archival_object_sub_sub_child_1_json_model
    )

    # Check sub sub children archival object 2
    expect(duplicated_sub_sub_children_archival_objects[1].parent_id).to eq duplicated_sub_children_archival_objects[0].id
    expect(duplicated_sub_sub_children_archival_objects[1].ref_id).to_not eq archival_object_sub_sub_child_2.ref_id
    expect(duplicated_sub_sub_children_archival_objects[1]).to have_attributes(archival_object_to_match(archival_object_sub_sub_child_2))
    duplicated_archival_object_sub_sub_child_2_json_model = ::ArchivalObject.to_jsonmodel(duplicated_sub_sub_children_archival_objects[1])
    expect_archival_object_records_to_match(
      duplicated_archival_object_sub_sub_child_2_json_model,
      archival_object_sub_sub_child_2_json_model
    )

    # Check sub sub sub children of children archival objects
    duplicated_sub_sub_sub_children_archival_objects = duplicated_sub_sub_children_archival_objects[0].children.to_a
    expect(duplicated_sub_sub_sub_children_archival_objects.count).to eq 1

    # Check sub sub sub children archival object 1
    expect(duplicated_sub_sub_sub_children_archival_objects[0].parent_id).to eq duplicated_sub_sub_children_archival_objects[0].id
    expect(duplicated_sub_sub_sub_children_archival_objects[0].ref_id).to_not eq archival_object_sub_sub_sub_child_1.ref_id
    expect(duplicated_sub_sub_sub_children_archival_objects[0]).to have_attributes(archival_object_to_match(archival_object_sub_sub_sub_child_1))
    duplicated_archival_object_sub_sub_sub_child_1_json_model = ::ArchivalObject.to_jsonmodel(duplicated_sub_sub_sub_children_archival_objects[0])
    expect_archival_object_records_to_match(
      duplicated_archival_object_sub_sub_sub_child_1_json_model,
      archival_object_sub_sub_sub_child_1_json_model
    )

    # Last child on the tree must have no children
    expect(duplicated_sub_sub_sub_children_archival_objects[0].children.count).to eq 0

    # Delete orignal resource
    resource.delete
    deleted_resource = Resource.where(id: resource.id).to_a
    expect(deleted_resource.count).to eq 0

    # Ensure total records are the same as before duplicate
    after_delete_total_records_count = total_records_count
    expect(original_total_records_count).to eq after_delete_total_records_count
  end

  # Test results from localhost:
  #
  # 10000 records with depth 100:
  # archival records created in ~> 299.238291 seconds
  # resource duplicated in      ~> 476.362015 seconds
  #
  # 100000 records with depth 100:
  # archival records created in ~> 3149.1919 seconds ~> 52.4865 minutes
  # resource duplicated in      ~> 4314.7708 seconds ~> 71.9128 minutes
  it 'successfully duplicates a resource with all its archival objects for a big amount of data' do
    NUMBER_OF_ARCHIVAL_OBJECTS = 100
    MAX_TREE_DEPTH_LEVEL = 10

    parent = nil
    previous_archival_object_parent = nil
    nested_counter = 1

    for x in 1..NUMBER_OF_ARCHIVAL_OBJECTS do
      if nested_counter > 0 && nested_counter < MAX_TREE_DEPTH_LEVEL
        if previous_archival_object_parent != nil
          parent = { 'ref' => previous_archival_object_parent.uri }

          nested_counter = nested_counter + 1
        end
      else
        nested_counter = 1
        parent = nil
      end

      archival_object_parent = create_archival_object({
        :title => "Archival Object #{x} #{now}",
        :resource => { :ref => resource.uri },
        :parent => parent,
        :ref_id => "ref_id_#{x}_#{now}_#{SecureRandom.uuid}",
        :lang_materials => [],
        :dates => [],
        :extents => [],
        :linked_agents => [],
        :subjects => [],
        :notes => [],
        :external_documents => [],
        :rights_statements => [],
        :instances => []
      })

      previous_archival_object_parent = archival_object_parent
    end

    resource_graph_before = object_graph_to_hash(resource.object_graph)

    expect(subject.duplicate).to eq true
    expect(subject.errors).to eq []

    # Ensure original resource is not affected after process
    resource_graph_after = object_graph_to_hash(resource.object_graph)
    expect(resource_graph_after).to eq resource_graph_before

    resource_duplicated_graph = object_graph_to_hash(subject.resource.object_graph)
    resource_graph_before.each do |model, ids|
      expect(resource_duplicated_graph[model].length).to eq ids.length
      # Expect ids to be different
      expect(ids & resource_duplicated_graph[model]).to eq []
    end
  end

  # Helper methods

  def object_graph_to_hash(graph)
    result_hash = {}

    graph.models.each do |model|
      result_hash[model] = graph.ids_for(model)
    end

    result_hash
  end

  def total_records_count
    {
      resources: ::Resource.count,
      resource_spawned_relationship: Relationships::ResourceSpawned.count,
      resource_linked_agent_relationships: Relationships::ResourceLinkedAgents.count,
      subjects_relationships: Relationships::ResourceSubject.count,
      agent_relationships: Relationships::ResourceLinkedAgents.count,
      resource_classification_relationships: Relationships::ResourceClassification.count,
      archival_objects: ArchivalObject.count,
      archival_object_relationships: Relationships::ArchivalObjectSubject.count,
      archival_object_subject_relationships: Relationships::ArchivalObjectSubject.count,
      archival_object_linked_agents_relationships: Relationships::ArchivalObjectLinkedAgents.count,
      archival_object_accession_component_links_relationships: Relationships::ArchivalObjectAccessionComponentLinks.count,
      archival_object_sub_container_top_container_link_relationships: Relationships::SubContainerTopContainerLink.count,
      subjects: Subject.count,
      agent_persons: AgentPerson.count,
      agent_families: AgentFamily.count,
      agent_corporate_entities: AgentCorporateEntity.count,
      classifications: Classification.count,
      accessions: Accession.count,
      digital_objects: DigitalObject.count,
      lang_materials: LangMaterial.count,
      notes: Note.count,
      extents: Extent.count,
      dates: ASDate.count,
      external_documents: ExternalDocument.count,
      rights_statements: RightsStatement.count,
      metadata_rights_declarations: MetadataRightsDeclaration.count,
      instances: Instance.count,
      deaccessions: Deaccession.count,
      collection_management: CollectionManagement.count,
      user_defined: UserDefined.count,
      revision_statements: RevisionStatement.count,
      language_and_script: LanguageAndScript.count,
      sub_containers: SubContainer.count,
      external_ids: ExternalId.count
    }
  end

  def expect_resource_records_to_match(resource_duplicated, resource_source)
    # Languages
    expect(resource_duplicated.lang_materials.count).to eq resource_source.lang_materials.count
    for x in 0..(resource_duplicated.lang_materials.count - 1) do
      expect(resource_duplicated.lang_materials[x]).to include(language_to_match(resource_source.lang_materials[x]))
      expect(resource_duplicated.lang_materials[x]['language_and_script']).to include(language_script_to_match(resource_source.lang_materials[x]['language_and_script']))
    end

    # Extents
    expect(resource_duplicated.extents.count).to eq resource_source.extents.count
    for x in 0..(resource_duplicated.extents.count - 1) do
      expect(resource_duplicated.extents[x]).to include(extent_to_match(resource_source.extents[x]))
    end

    # Dates
    expect(resource_duplicated.dates.count).to eq resource_source.dates.count
    for x in 0..(resource_duplicated.dates.count - 1) do
      expect(resource_duplicated.dates[x]).to include(date_to_match(resource_source.dates[x]))
    end

    # Notes
    expect(resource_duplicated.notes.count).to eq resource_source.notes.count
    for x in 0..(resource_duplicated.notes.count - 1) do
      expect(resource_duplicated.notes[x]).to include(note_to_match(resource_source.notes[x]))
    end

    # Check resource linked agents
    expect(resource_duplicated.linked_agents.count).to eq resource_source.linked_agents.count
    for x in 0..(resource_duplicated.linked_agents.count - 1) do
      expect(resource_duplicated.linked_agents[x]['archival_object_id']).to eq nil
      expect(resource_duplicated.linked_agents[x]['resource_id']).to eq resource_duplicated.id
      expect(resource_duplicated.linked_agents[x]).to include(agent_to_match(resource_source.linked_agents[x]))
    end

    # Check resource subjects
    expect(resource_duplicated.subjects.count).to eq resource_source.subjects.count
    for x in 0..(resource_duplicated.subjects.count - 1) do
      expect(resource_duplicated.subjects[x]['archival_object_id']).to eq nil
      expect(resource_duplicated.subjects[x]['resource_id']).to eq resource_duplicated.id
      expect(resource_duplicated.subjects[x]).to include(subject_to_match(resource_source.subjects[x]))
    end

    # Check resource related accessions
    expect(resource_duplicated.related_accessions.count).to eq resource_source.related_accessions.count
    for x in 0..(resource_duplicated.related_accessions.count - 1) do
      expect(resource_duplicated.related_accessions[x]['resource_id']).to eq resource_duplicated.id
      expect(resource_duplicated.related_accessions[x]).to include(accession_to_match(resource_source.related_accessions[x]))
    end

    # Check resource classifications
    expect(resource_duplicated.classifications.count).to eq resource_source.classifications.count
    for x in 0..(resource_duplicated.classifications.count - 1) do
      expect(resource_duplicated.classifications[x]['resource_id']).to eq resource_duplicated.id
      expect(resource_duplicated.classifications[x]).to include(classification_to_match(resource_source.classifications[x]))
    end

    # Check resource instances
    expect(resource_duplicated.instances.count).to eq resource_source.instances.count
    for x in 0..(resource_duplicated.instances.count - 1) do
      expect(resource_duplicated.instances[x]).to include(instance_to_match(resource_source.instances[x]))
    end

    # External Documents
    expect(resource_duplicated.external_documents.count).to eq resource_source.external_documents.count
    for x in 0..(resource_duplicated.external_documents.count - 1) do
      expect(resource_duplicated.external_documents[x]).to include(external_document_to_match(resource_source.external_documents[x]))
    end

    # Rights Statements
    expect(resource_duplicated.rights_statements.count).to eq resource_source.rights_statements.count
    for x in 0..(resource_duplicated.rights_statements.count - 1) do
      expect(resource_duplicated.rights_statements[x]).to include(rights_statement_to_match(resource_source.rights_statements[x]))
    end

    # Metadata Rights Declarations
    expect(resource_duplicated.metadata_rights_declarations.count).to eq resource_source.metadata_rights_declarations.count
    for x in 0..(resource_duplicated.metadata_rights_declarations.count - 1) do
      expect(resource_duplicated.metadata_rights_declarations[x]).to include(metadata_rights_declaration_to_match(resource_source.metadata_rights_declarations[x]))
    end

    # Deaccessions
    expect(resource_duplicated.deaccessions.count).to eq resource_source.deaccessions.count
    for x in 0..(resource_duplicated.deaccessions.count - 1) do
      expect(resource_duplicated.deaccessions[x]).to include(deaccession_to_match(resource_source.deaccessions[x]))
    end

    # Collection Management
    expect(resource_duplicated.collection_management['parent']['ref']).to include resource_duplicated.id.to_s
    expect(resource_duplicated.collection_management['uri']).to_not eq resource_source.collection_management['uri']
    expect(resource_duplicated.collection_management['parent']).to_not eq resource_source.collection_management['parent']
    expect(resource_duplicated.collection_management).to include(collection_management_to_match(resource_source.collection_management))
    expect(resource_duplicated.collection_management['external_ids'].count).to eq resource_source.collection_management['external_ids'].count
    for x in 0..(resource_duplicated.collection_management['external_ids'].count - 1) do
      expect(resource_duplicated.collection_management['external_ids'][x]).to include(collection_management_external_id_to_match(resource_source.collection_management['external_ids'][x]))
    end

    # User Defined
    expect(resource_duplicated.user_defined).to include(user_defined_to_match(resource_source.user_defined))
  end

  def expect_archival_object_records_to_match(archival_object_duplicated, archival_object_source)
    # Check archival object linked agents
    expect(archival_object_duplicated.linked_agents.count).to eq archival_object_source.linked_agents.count
    for x in 0..(archival_object_duplicated.linked_agents.count - 1) do
      expect(archival_object_duplicated.linked_agents[x]['id']).to_not eq archival_object_source.linked_agents[x]['id']
      expect(archival_object_duplicated.linked_agents[x]['resource_id']).to eq nil
      expect(archival_object_duplicated.linked_agents[x]['archival_object_id']).to eq archival_object_duplicated.id
      expect(archival_object_duplicated.linked_agents[x]).to include(agent_to_match(archival_object_source.linked_agents[x]))
    end

    # Check archival object subjects
    expect(archival_object_duplicated.subjects.count).to eq archival_object_source.subjects.count
    for x in 0..(archival_object_duplicated.subjects.count - 1) do
      expect(archival_object_duplicated.subjects[x]['id']).to_not eq archival_object_source.subjects[x]['id']
      expect(archival_object_duplicated.subjects[x]['resource_id']).to eq nil
      expect(archival_object_duplicated.subjects[x]['archival_object_id']).to eq archival_object_duplicated.id
      expect(archival_object_duplicated.subjects[x]).to include(subject_to_match(archival_object_source.subjects[x]))
    end

    # Check acrhival object accession links
    expect(archival_object_duplicated.accession_links.count).to eq archival_object_source.accession_links.count
    for x in 0..(archival_object_duplicated.accession_links.count - 1) do
      expect(archival_object_duplicated.accession_links[x]['id']).to_not eq archival_object_source.accession_links[x]['id']
      expect(archival_object_duplicated.accession_links[x]['resource_id']).to eq nil
      expect(archival_object_duplicated.accession_links[x]['archival_object_id']).to eq archival_object_duplicated.id
      expect(archival_object_duplicated.accession_links[x]).to include(accession_to_match(archival_object_source.accession_links[x]))
    end

    # Languages
    expect(archival_object_duplicated.lang_materials.count).to eq archival_object_source.lang_materials.count
    for x in 0..(archival_object_duplicated.lang_materials.count - 1) do
      expect(archival_object_duplicated.lang_materials[x]).to include(language_to_match(archival_object_source.lang_materials[x]))
      expect(archival_object_duplicated.lang_materials[x]['language_and_script']).to include(language_script_to_match(archival_object_source.lang_materials[x]['language_and_script']))
    end

    # Dates
    expect(archival_object_duplicated.dates.count).to eq archival_object_source.dates.count
    for x in 0..(archival_object_duplicated.dates.count - 1) do
      expect(archival_object_duplicated.dates[x]).to include(date_to_match(archival_object_source.dates[x]))
    end

    # Extents
    expect(archival_object_duplicated.extents.count).to eq archival_object_source.extents.count
    for x in 0..(archival_object_duplicated.extents.count - 1) do
      expect(archival_object_duplicated.extents[x]).to include(extent_to_match(archival_object_source.extents[x]))
    end

    # Notes
    expect(archival_object_duplicated.notes.count).to eq archival_object_source.notes.count
    for x in 0..(archival_object_duplicated.notes.count - 1) do
      expect(archival_object_duplicated.notes[x]).to include(note_to_match(archival_object_source.notes[x]))
    end

    # External Documents
    expect(archival_object_duplicated.external_documents.count).to eq archival_object_source.external_documents.count
    for x in 0..(archival_object_duplicated.external_documents.count - 1) do
      expect(archival_object_duplicated.external_documents[x]).to include(external_document_to_match(archival_object_source.external_documents[x]))
    end

    # Rights Statements
    expect(archival_object_duplicated.rights_statements.count).to eq archival_object_source.rights_statements.count
    for x in 0..(archival_object_duplicated.rights_statements.count - 1) do
      expect(archival_object_duplicated.rights_statements[x]).to include(rights_statement_to_match(archival_object_source.rights_statements[x]))
    end
  end

  def resource_to_match(resource)
    {
      json_schema_version: resource.json_schema_version,
      repo_id: resource.repo_id,
      accession_id: resource.accession_id,
      level_id: resource.level_id,
      other_level: resource.other_level,
      resource_type_id: resource.resource_type_id,
      restrictions: resource.restrictions,
      repository_processing_note: resource.repository_processing_note,
      ead_location: resource.ead_location,
      finding_aid_title: resource.finding_aid_title,
      finding_aid_filing_title: resource.finding_aid_filing_title,
      finding_aid_date: resource.finding_aid_date,
      finding_aid_author: resource.finding_aid_author,
      finding_aid_description_rules_id: resource.finding_aid_description_rules_id,
      finding_aid_language_note: resource.finding_aid_language_note,
      finding_aid_sponsor: resource.finding_aid_sponsor,
      finding_aid_edition_statement: resource.finding_aid_edition_statement,
      finding_aid_series_statement: resource.finding_aid_series_statement,
      finding_aid_status_id: resource.finding_aid_status_id,
      finding_aid_note: resource.finding_aid_note,
      system_generated: resource.system_generated,
      created_by: resource.created_by,
      last_modified_by: resource.last_modified_by,
      suppressed: resource.suppressed,
      finding_aid_subtitle: resource.finding_aid_subtitle,
      finding_aid_sponsor_sha1: resource.finding_aid_sponsor_sha1,
      slug: resource.slug,
      is_slug_auto: resource.is_slug_auto,
      finding_aid_language_id: resource.finding_aid_language_id,
      finding_aid_script_id: resource.finding_aid_script_id,
      is_finding_aid_status_published: resource.is_finding_aid_status_published,
      level: resource.level,
      resource_type: resource.resource_type,
      finding_aid_description_rules: resource.finding_aid_description_rules,
      finding_aid_language: resource.finding_aid_language,
      finding_aid_script: resource.finding_aid_script,
      finding_aid_status: resource.finding_aid_status
    }
  end

  def archival_object_to_match(archival_object)
    {
      title: archival_object.title,
      lock_version: archival_object.lock_version,
      json_schema_version: archival_object.json_schema_version,
      repo_id: archival_object.repo_id,
      position: archival_object.position,
      publish: archival_object.publish,
      component_id: archival_object.component_id,
      level_id: archival_object.level_id,
      other_level: archival_object.other_level,
      system_generated: archival_object.system_generated,
      restrictions_apply: archival_object.restrictions_apply,
      repository_processing_note: archival_object.repository_processing_note,
      created_by: archival_object.created_by,
      last_modified_by: archival_object.last_modified_by,
      suppressed: archival_object.suppressed,
      slug: archival_object.slug,
      is_slug_auto: archival_object.is_slug_auto
    }
  end

  def language_to_match(lang_material)
    {
      'lock_version'=> lang_material['lock_version'],
      'created_by'=> lang_material['created_by'],
      'last_modified_by'=> lang_material['last_modified_by'],
      'jsonmodel_type'=> lang_material['jsonmodel_type'],
      'notes'=> lang_material['notes']
    }
  end

  def extent_to_match(extent)
    {
      'lock_version'=> extent['lock_version'],
      'number'=> extent['number'],
      'physical_details'=> extent['physical_details'],
      'dimensions'=> extent['dimensions'],
      'created_by'=> extent['created_by'],
      'last_modified_by'=> extent['last_modified_by'],
      'portion'=> extent['portion'],
      'extent_type'=> extent['extent_type'],
      'jsonmodel_type'=> extent['jsonmodel_type']
    }
  end

  def date_to_match(date)
    result = {
      'lock_version' => date['lock_version'],
      'expression' => date['expression'],
      'begin' => date['begin'],
      'created_by' => date['created_by'],
      'last_modified_by' => date['last_modified_by'],
      'date_type' => date['date_type'],
      'label' => date['label'],
      'certainty' => date['certainty'],
      'era' => date['era'],
      'calendar' => date['calendar'],
      'jsonmodel_type' => date['jsonmodel_type'],
    }

    result['end'] = date['end'] if date['date_type'] == 'inclusive'

    result
  end

  def note_to_match(note)
    result = {
      'jsonmodel_type' => note['jsonmodel_type'],
      'persistent_id' => note['persistent_id'],
      'publish' => note['publish']
    }

    result['type'] = note['type'] if !note['type'].nil?

    result['subnotes'] = note['subnotes'] if note['jsonmodel_type'] == 'note_multipart'

    if note['jsonmodel_type'] == 'note_bibliography'
      result['content'] = note['content']
      result['items'] = note['items']
    end

    result
  end

  def language_script_to_match(language_script)
    {
      'lock_version'=> language_script['lock_version'],
      'created_by'=> language_script['created_by'],
      'last_modified_by'=> language_script['last_modified_by'],
      'language'=> language_script['language'],
      'script'=> language_script['script'],
      'jsonmodel_type'=> language_script['jsonmodel_type']
    }
  end

  def agent_to_match(linked_agent)
    {
      'agent_person_id' => linked_agent['agent_person_id'],
      'agent_software_id' => linked_agent['agent_software_id'],
      'agent_family_id' => linked_agent['agent_family_id'],
      'agent_corporate_entity_id' => linked_agent['agent_corporate_entity_id'],
      'accession_id' => linked_agent['accession_id'],
      'digital_object_id' => linked_agent['digital_object_id'],
      'digital_object_component_id' => linked_agent['digital_object_component_id'],
      'event_id' => linked_agent['event_id'],
      'aspace_relationship_position' => linked_agent['aspace_relationship_position'],
      'created_by' => linked_agent['created_by'],
      'last_modified_by' => linked_agent['last_modified_by'],
      'role_id' => linked_agent['role_id'],
      'relator_id' => linked_agent['relator_id'],
      'title' => linked_agent['title'],
      'suppressed' => linked_agent['suppressed'],
      'rights_statement_id' => linked_agent['rights_statement_id'],
      'is_primary' => linked_agent['is_primary'],
      'role' => linked_agent['role'],
      'relator' => linked_agent['relator'],
      'terms' => linked_agent['terms'],
      'ref' => linked_agent['ref']
    }
  end

  def subject_to_match(subject)
    {
      'accession_id' => subject['accession_id'],
      'digital_object_id' => subject['digital_object_id'],
      'digital_object_component_id' => subject['digital_object_component_id'],
      'subject_id' => subject['subject_id'],
      'aspace_relationship_position' => subject['aspace_relationship_position'],
      'created_by' => subject['created_by'],
      'last_modified_by' => subject['last_modified_by'],
      'suppressed' => subject['suppressed'],
      'ref' => subject['ref']
    }
  end

  def accession_to_match(accession)
    {
      'accession_id' => accession['accession_id'],
      'aspace_relationship_position' => accession['aspace_relationship_position'],
      'created_by' => accession['created_by'],
      'created_by' => accession['created_by'],
      'last_modified_by' => accession['last_modified_by'],
      'suppressed' => accession['suppressed'],
      'ref' => accession['ref']
    }
  end

  def classification_to_match(classification)
    {
      'accession_id' => classification['accession_id'],
      'classification_id' => classification['classification_id'],
      'classification_term_id' => classification['classification_term_id'],
      'aspace_relationship_position' => classification['aspace_relationship_position'],
      'created_by' => classification['created_by'],
      'last_modified_by' => classification['last_modified_by'],
      'suppressed' => classification['suppressed'],
      'digital_object_id' => classification['digital_object_id'],
      'ref' => classification['ref']
    }
  end

  def instance_to_match(instance)
    {
      'lock_version' => instance['lock_version'],
      'created_by' => instance['created_by'],
      'last_modified_by' => instance['last_modified_by'],
      'instance_type' => instance['instance_type'],
      'jsonmodel_type' => instance['jsonmodel_type'],
      'is_representative' => instance['is_representative']
    }
  end

  def external_document_to_match(external_document)
    {
      'lock_version' => external_document['lock_version'],
      'title' => external_document['title'],
      'location' => external_document['location'],
      'publish' => external_document['publish'],
      'created_by' => external_document['created_by'],
      'last_modified_by' => external_document['last_modified_by'],
      'last_modified_by' => external_document['last_modified_by'],
      'jsonmodel_type' => external_document['jsonmodel_type']
    }
  end

  def rights_statement_to_match(rights_statement)
    {
      'lock_version' => rights_statement['lock_version'],
      'identifier' => rights_statement['identifier'],
      'created_by' => rights_statement['created_by'],
      'last_modified_by' => rights_statement['last_modified_by'],
      'last_modified_by' => rights_statement['last_modified_by'],
      'start_date' => rights_statement['start_date'],
      'rights_type' => rights_statement['rights_type'],
      'status' => rights_statement['status'],
      'jurisdiction' => rights_statement['jurisdiction'],
      'acts' => rights_statement['acts'],
      'linked_agents' => rights_statement['linked_agents'],
      'notes' => rights_statement['notes'],
      'jsonmodel_type' => rights_statement['jsonmodel_type']
    }
  end

  def metadata_rights_declaration_to_match(metadata_rights_declaration)
    {
      'lock_version' => metadata_rights_declaration['lock_version'],
      'descriptive_note' => metadata_rights_declaration['descriptive_note'],
      'file_uri' => metadata_rights_declaration['file_uri'],
      'xlink_title_attribute' => metadata_rights_declaration['xlink_title_attribute'],
      'xlink_role_attribute' => metadata_rights_declaration['xlink_role_attribute'],
      'xlink_arcrole_attribute' => metadata_rights_declaration['xlink_arcrole_attribute'],
      'last_verified_date' => metadata_rights_declaration['last_verified_date'],
      'created_by' => metadata_rights_declaration['created_by'],
      'last_modified_by' => metadata_rights_declaration['last_modified_by'],
      'license' => metadata_rights_declaration['license'],
      'file_version_xlink_actuate_attribute' => metadata_rights_declaration['file_version_xlink_actuate_attribute'],
      'file_version_xlink_show_attribute' => metadata_rights_declaration['file_version_xlink_show_attribute'],
      'jsonmodel_type' => metadata_rights_declaration['jsonmodel_type']
    }
  end

  def deaccession_to_match(deaccession)
    {
      'lock_version' => deaccession['lock_version'],
      'description' => deaccession['description'],
      'notification' => deaccession['notification'],
      'created_by' => deaccession['created_by'],
      'lock_version' => deaccession['lock_version'],
      'scope' => deaccession['scope'],
      'jsonmodel_type' => deaccession['jsonmodel_type'],
      'repository' => deaccession['repository']
    }
  end

  def collection_management_to_match(collection_management)
    result = {
      'lock_version' => collection_management['lock_version'],
      'processing_hours_per_foot_estimate' => collection_management['processing_hours_per_foot_estimate'],
      'processing_total_extent' => collection_management['processing_total_extent'],
      'processing_hours_total' => collection_management['processing_hours_total'],
      'rights_determined' => collection_management['rights_determined'],
      'created_by' => collection_management['created_by'],
      'last_modified_by' => collection_management['last_modified_by'],
      'processing_total_extent_type' => collection_management['processing_total_extent_type'],
      'processing_priority' => collection_management['processing_priority'],
      'processing_status' => collection_management['processing_status'],
      'jsonmodel_type' => collection_management['jsonmodel_type'],
      'repository' => collection_management['repository']
    }

    result['processors'] = collection_management['processors'] if !collection_management['processors'].nil?

    result
  end

  def collection_management_external_id_to_match(external_id)
    {
      'external_id' => external_id['external_id'],
      'source' => external_id['source'],
      'created_by' => external_id['created_by'],
      'last_modified_by' => external_id['last_modified_by'],
      'jsonmodel_type' => external_id['jsonmodel_type']
    }
  end

  def user_defined_to_match(user_defined)
    {
      'lock_version' => user_defined['lock_version'],
      'boolean_1' => user_defined['boolean_1'],
      'boolean_2' => user_defined['boolean_2'],
      'boolean_3' => user_defined['boolean_3'],
      'integer_1' => user_defined['integer_1'],
      'integer_2' => user_defined['integer_2'],
      'integer_3' => user_defined['integer_3'],
      'real_1' => user_defined['real_1'],
      'real_2' => user_defined['real_2'],
      'real_3' => user_defined['real_3'],
      'string_1' => user_defined['string_1'],
      'string_2' => user_defined['string_2'],
      'string_3' => user_defined['string_3'],
      'text_1' => user_defined['text_1'],
      'text_2' => user_defined['text_2'],
      'text_3' => user_defined['text_3'],
      'text_4' => user_defined['text_4'],
      'text_5' => user_defined['text_5'],
      'date_1' => user_defined['date_1'],
      'date_2' => user_defined['date_2'],
      'date_3' => user_defined['date_3'],
      'created_by' => user_defined['created_by'],
      'last_modified_by' => user_defined['last_modified_by'],
      'enum_1' => user_defined['enum_1'],
      'enum_2' => user_defined['enum_2'],
      'enum_3' => user_defined['enum_3'],
      'enum_4' => user_defined['enum_4'],
      'jsonmodel_type' => user_defined['jsonmodel_type'],
      'repository' => user_defined['repository']
    }
  end
end
