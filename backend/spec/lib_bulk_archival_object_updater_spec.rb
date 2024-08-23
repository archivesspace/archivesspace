require_relative 'spec_helper'
require_relative "../app/lib/bulk_archival_object_updater"

require 'rubyXL/convenience_methods/cell'

describe 'Bulk Archival Object Updater' do
  let(:uuid) { SecureRandom.uuid }

  let(:min_subrecords) { 4 }
  let(:extra_subrecords) { 3 }
  let(:min_notes) { 2 }
  let(:selected_columns) do
    [
      'level',
      'component_id',
      'ref_id',
      'repository_processing_note',
      'publish',
      'date',
      'extent',
      'instance',
      'digital_object',
      'related_accession',
      'langmaterial',
      'note_abstract',
      'note_accruals',
      'note_bioghist',
      'note_accessrestrict',
      'note_dimensions',
      'note_altformavail',
      'note_odd',
      'note_phystech',
      'note_physdesc',
      'note_processinfo',
      'note_relatedmaterial',
      'note_scopecontent',
      'note_separatedmaterial'
    ]
  end

  let(:dates) { [build(:json_date)] }
  let(:accession) { create(:json_accession, title: "Accession Title #{uuid}") }
  let(:notes) { [build(:json_note_singlepart), build(:json_note_multipart)] }
  let(:extents) { [build(:json_extent, {:portion => generate(:portion)})] }
  let(:lang_materials) { [build(:json_lang_material_with_note)] }
  let(:location) { create(:json_location, :temporary => generate(:temporary_location_type)) }
  let(:top_container) do
    create(:json_top_container,
      :container_locations => [
        {
          'ref' => location.uri,
          'status' => 'current',
          'start_date' => generate(:yyyy_mm_dd),
          'end_date' => generate(:yyyy_mm_dd)
        }
      ]
    )
  end

  let(:digital_object) { create(:json_digital_object) }

  let(:instances) do
    [
      build(:json_instance_digital, :digital_object => { :ref => digital_object.uri }),
      build(:json_instance, :sub_container => build(:json_sub_container, :top_container => { :ref => top_container.uri }))
    ]
  end

  let(:resource) do
    create(:json_resource,
      :title => "Resource Title #{uuid}",
      :extents => extents,
      :dates => dates,
      :notes => notes,
      :lang_materials => lang_materials
    )
  end

  let(:archival_object_1) do
    create(:json_archival_object,
      :title => "Archival Object Title 1 #{uuid}",
      :resource => {
        :ref => resource.uri
      },
      :dates => dates,
      :notes => notes,
      :instances => instances,
      :accession_links => [{'ref' => accession.uri}],
      :subjects => [],
      :linked_agents => [],
      :rights_statements => [],
      :external_documents => [],
      :extents => [],
      :lang_materials => []
    )
  end

  let(:archival_object_2) do
    create(:json_archival_object,
      :title => "Archival Object Title 2 #{uuid}",
      :resource => {
        :ref => resource.uri
      },
      :dates => dates,
      :notes => notes,
      :instances => instances,
      :accession_links => [],
      :subjects => [],
      :linked_agents => [],
      :rights_statements => [],
      :external_documents => [],
      :extents => [],
      :lang_materials => []
    )
  end

  let(:resource_repository_id) do
    resource.repository['ref'].split('/').pop
  end

  let(:spreadsheet_builder) do
    SpreadsheetBuilder.new(
      resource.uri,
      [
        archival_object_1.uri,
        archival_object_2.uri
      ],
      min_subrecords,
      extra_subrecords,
      min_notes,
      selected_columns
    )
  end

  let(:excel_filename) { File.join(Dir.tmpdir, 'bulk_archival_object_updater', spreadsheet_builder.build_filename) }

  let(:excel_file) do
    stream = spreadsheet_builder.to_stream
    File.open(excel_filename, "w") do |file|
      file.write(stream)
    end

    RubyXL::Parser.parse(excel_filename)
  end

  let(:sheet) { excel_file['Updates'] }

  # NOTE: We are using the second row to get column names here,
  #       that follow a path format like `extents/2/physical_details`.
  #       Using the translated column names from the first row causes
  #       the specs to fail, as it seems that the SpreadsheetBuilder is buggy,
  #       and is missing some translations sometimes.
  let(:column_names) do
    sheet[1].cells.map(&:value)
  end

  let(:parameters) do
    {
      create_missing_top_containers: false
    }
  end

  let(:bulk_archival_object_updater) do
    BulkArchivalObjectUpdater.new(excel_filename, parameters)
  end

  before(:each) do
    if !File.directory?(File.join(Dir.tmpdir, 'bulk_archival_object_updater'))
      Dir.mkdir(File.join(Dir.tmpdir, 'bulk_archival_object_updater'))
    end

    # Delete all excel files that contain `bulk_update.resource` in their filename, from the tmp folder.
    excel_files = Dir.glob(File.join(Dir.tmpdir, 'bulk_archival_object_updater', '*.xlsx'))
    excel_files.each do |filename|
      File.delete(filename) if filename.include?('bulk_update.resource')
    end
  end

  after(:each) do
    # Delete all excel files that contain `bulk_update.resource` in their filename, from the tmp folder.
    excel_files = Dir.glob(File.join(Dir.tmpdir, 'bulk_archival_object_updater', '*.xlsx'))
    excel_files.each do |filename|
      File.delete(filename) if filename.include?('bulk_update.resource')
    end
  end

  context 'default config parameters' do
    context 'when there are no user provided parameters' do
      let(:parameters) do
        {}
      end

      it 'ensures that the app config has default values and can be successfully read from bulk updater' do
        bulk_archival_object_updater_apply_deletes = AppConfig[:bulk_archival_object_updater_apply_deletes]
        bulk_archival_object_updater_create_missing_top_containers = AppConfig[:bulk_archival_object_updater_create_missing_top_containers]
        expect(bulk_archival_object_updater_apply_deletes).to eq false
        expect(bulk_archival_object_updater_create_missing_top_containers).to eq false

        expect(bulk_archival_object_updater.apply_deletes?).to eq bulk_archival_object_updater_apply_deletes
        expect(bulk_archival_object_updater.create_missing_top_containers?).to eq bulk_archival_object_updater_create_missing_top_containers
      end
    end

    context 'when provided provided create_missing_top_containers is true' do
      let(:parameters) do
        {
          create_missing_top_containers: true
        }
      end

      it 'ensures that the app config has default values and can be overriden from the provided parameters' do
        bulk_archival_object_updater_apply_deletes = AppConfig[:bulk_archival_object_updater_apply_deletes]
        bulk_archival_object_updater_create_missing_top_containers = AppConfig[:bulk_archival_object_updater_create_missing_top_containers]
        expect(bulk_archival_object_updater_apply_deletes).to eq false
        expect(bulk_archival_object_updater_create_missing_top_containers).to eq false

        expect(bulk_archival_object_updater.apply_deletes?).to eq bulk_archival_object_updater_apply_deletes
        expect(bulk_archival_object_updater.create_missing_top_containers?).to eq true
      end
    end
  end

  context 'when the bulk updater successfully updates the provided archival objects' do
    it 'successfully runs the bulk updater with no errors' do
      expect(column_names.length).to eq 177

      total_records_count_before = total_records_count

      # Ensure the excel has only one digital object
      column_index = column_names.find_index('digital_object/0/digital_object_id')
      expect(sheet[2][column_index]).to be_a RubyXL::Cell
      column_index = column_names.find_index('digital_object/1/digital_object_id')
      expect(sheet[2][column_index]).to eq nil

      # Ensure the excel has only one instance
      column_index = column_names.find_index('instances/0/instance_type')
      expect(sheet[2][column_index]).to be_a RubyXL::Cell
      column_index = column_names.find_index('instances/1/instance_type')
      expect(sheet[2][column_index]).to eq nil

      expect(archival_object_1.instances.length).to eq 2
      expect(archival_object_2.instances.length).to eq 2

      # Change the title of achival objects in the downloaded excel.
      title_index = column_names.find_index('title')
      sheet[2][title_index].change_contents('Updated Archival Object Title 1')
      sheet[3][title_index].change_contents('Updated Archival Object Title 2')

      # Instance to create
      record_number = 1
      update_empty_sheet_columns(row: 2, columns_to_update: {
        "instances/#{record_number}/instance_type" => 'Books [books]',
        "instances/#{record_number}/top_container_type" => 'Box [box]',
        "instances/#{record_number}/top_container_indicator" => top_container.indicator,
        "instances/#{record_number}/top_container_barcode" => top_container.barcode,
        "instances/#{record_number}/sub_container_type_2" => 'Folder [folder]',
        "instances/#{record_number}/sub_container_indicator_2" => "Child Indicator #{uuid}",
        "instances/#{record_number}/sub_container_barcode_2" => "Child Container Barcode #{uuid}",
        "instances/#{record_number}/sub_container_type_3" => 'Box [box]',
        "instances/#{record_number}/sub_container_indicator_3" => "Grandchild Indicator #{uuid}"
      })

      # Digital object to create
      record_number = 1
      update_empty_sheet_columns(row: 2, columns_to_update: {
        "digital_object/#{record_number}/digital_object_id" => "Digital Object #{record_number} - Identifier #{uuid}",
        "digital_object/#{record_number}/digital_object_title" => 'Digital Object #{record_number} - Title',
        "digital_object/#{record_number}/digital_object_publish" => 'true',
        "digital_object/#{record_number}/file_version_file_uri" => "Digital Object #{record_number} - File URI #{uuid}",
        "digital_object/#{record_number}/file_version_caption" => "Digital Object #{record_number} - File Caption #{uuid}",
        "digital_object/#{record_number}/file_version_publish" => "true"
      })

      # Save excel file after updates
      excel_file.write(excel_filename)

      updated_records = bulk_archival_object_updater.run

      expect(bulk_archival_object_updater.errors).to eq []

      # Find created digital object id
      expect(updated_records.key?(:updated_uris)).to eq true
      expect(updated_records[:updated_uris].length).to eq 3
      find_digital_object_uris = updated_records[:updated_uris].select do |uri|
        uri.include?('digital_objects')
      end
      expect(find_digital_object_uris.length).to eq 1
      created_digital_object_id = find_digital_object_uris[0].split('/').pop

      expect(updated_records).to eq(
        {
          :updated_uris=>[
            "/repositories/#{resource_repository_id}/digital_objects/#{created_digital_object_id}",
            "/repositories/#{resource_repository_id}/archival_objects/#{archival_object_1.id}",
            "/repositories/#{resource_repository_id}/archival_objects/#{archival_object_2.id}"
          ]
        }
      )

      reload_archival_object_1 = ::ArchivalObject.where(id: archival_object_1.id).first
      reload_archival_object_2 = ::ArchivalObject.where(id: archival_object_2.id).first
      expect(reload_archival_object_1.title).to eq 'Updated Archival Object Title 1'
      expect(reload_archival_object_2.title).to eq 'Updated Archival Object Title 2'

      reload_archival_object_1_json_model = ::ArchivalObject.to_jsonmodel(reload_archival_object_1)
      reload_archival_object_2_json_model = ::ArchivalObject.to_jsonmodel(reload_archival_object_2)
      expect(reload_archival_object_1_json_model.instances.length).to eq 4
      expect(reload_archival_object_2_json_model.instances.length).to eq 2

      expect(bulk_archival_object_updater.create_missing_top_containers?).to eq false

      total_records_count_after = total_records_count

      top_container_count_before = total_records_count_before.delete(:top_containers)
      top_container_count_after = total_records_count_after.delete(:top_containers)

      digital_object_count_before = total_records_count_before.delete(:digital_objects)
      digital_object_count_after = total_records_count_after.delete(:digital_objects)

      instance_count_before = total_records_count_before.delete(:instances)
      instance_count_after = total_records_count_after.delete(:instances)

      top_container_relationships_count_before = total_records_count_before.delete(:archival_object_sub_container_top_container_link_relationships)
      top_container_relationships_count_after = total_records_count_after.delete(:archival_object_sub_container_top_container_link_relationships)

      sub_container_count_before = total_records_count_before.delete(:sub_containers)
      sub_container_count_after = total_records_count_after.delete(:sub_containers)

      expect(top_container_count_after).to eq top_container_count_before

      expect(digital_object_count_after).to eq digital_object_count_before + 1
      expect(instance_count_after).to eq instance_count_before + 2
      expect(top_container_relationships_count_after).to eq top_container_relationships_count_before + 1
      expect(sub_container_count_after).to eq sub_container_count_before + 1

      expect(total_records_count_before).to eq total_records_count_after
    end
  end

  context 'when the bulk updater does not update the provided archival objects' do
    context 'because the provided top container does not exist and create_missing_top_containers is set to false', :disable_database_transaction do
      it 'does not update any of the archival objects and sets container errors' do
        expect(column_names.length).to eq 177
        total_records_count_before = total_records_count
        expect(bulk_archival_object_updater.create_missing_top_containers?).to eq false

        instance_count_before = Instance.count
        digital_object_count_before = DigitalObject.count
        top_container_count_before = TopContainer.count
        top_container_relationships_count_before = Relationships::SubContainerTopContainerLink.count

        # Change the title of achival objects in the downloaded excel.
        title_index = column_names.find_index('title')
        sheet[2][title_index].change_contents('Updated Archival Object Title 1')
        sheet[3][title_index].change_contents('Updated Archival Object Title 2')

        record_number = 1
        update_empty_sheet_columns(row: 2, columns_to_update: {
          "instances/#{record_number}/instance_type" => 'Books [books]',
          "instances/#{record_number}/top_container_type" => 'Box [box]',
          "instances/#{record_number}/top_container_indicator" => "Container to be created #{uuid} Indicator",
          "instances/#{record_number}/top_container_barcode" => "Container to be created #{uuid} Barcode",
          "instances/#{record_number}/sub_container_type_2" => 'Folder [folder]',
          "instances/#{record_number}/sub_container_indicator_2" => "Child Indicator #{uuid}",
          "instances/#{record_number}/sub_container_barcode_2" => "Child Container Barcode #{uuid}",
          "instances/#{record_number}/sub_container_type_3" => 'Box [box]',
          "instances/#{record_number}/sub_container_indicator_3" => "Grandchild Indicator #{uuid}"
        })

        # Save excel file after updates
        excel_file.write(excel_filename)

        updated_records = {}

        expect do
          updated_records = bulk_archival_object_updater.run
        end.to raise_error BulkArchivalObjectUpdater::BulkUpdateFailed do |bulk_update_failed|
          expect(bulk_update_failed.errors.length).to eq 2

          expect(bulk_update_failed.errors[0]).to eq({
            :sheet => "Updates",
            :column=>"instances/1/top_container_indicator",
            :row => 3,
            :errors=> [
              "Top container not found attached within resource: #<BulkArchivalObjectUpdater::TopContainerCandidate {:top_container_type=>\"box\", :top_container_indicator=>\"Container to be created #{uuid} Indicator\", :top_container_barcode=>\"Container to be created #{uuid} Barcode\"}>\nSet 'create_missing_top_containers' to true inside AppConfig, to create Top Containers that do not exist.\nThe following top containers are attached within this resource:\n[#<BulkArchivalObjectUpdater::TopContainerCandidate {:top_container_type=>\"box\", :top_container_indicator=>\"#{top_container.indicator}\", :top_container_barcode=>\"#{top_container.barcode}\"}>, \"/repositories/#{resource_repository_id}/top_containers/#{top_container.id}\"]\n"
            ]
          })

          expect(bulk_update_failed.errors[1]).to eq({
            :sheet => "Updates",
            :json_property => "instances/2/sub_container/top_container",
            :row => 3,
            :errors => ["Property is required but was missing"]
          })
        end

        expect(updated_records).to eq({})

        # Ensure archival object titles were not updated.
        reload_archival_object_1 = ::ArchivalObject.where(id: archival_object_1.id).first
        reload_archival_object_2 = ::ArchivalObject.where(id: archival_object_2.id).first
        expect(reload_archival_object_1.title).to eq "Archival Object Title 1 #{uuid}"
        expect(reload_archival_object_2.title).to eq "Archival Object Title 2 #{uuid}"

        total_records_count_after = total_records_count
        expect(total_records_count_before).to eq total_records_count_after
      end
    end

    context 'because the accession id provided does not belong to an existing accession' do
      it 'does not update any of the archival objects and sets an accession not found error' do
        expect(column_names.length).to eq 177
        total_records_count_before = total_records_count

        # column_index = column_names.find_index('related_accessions/0/id_0')
        column_index = column_names.find_index('related_accessions/0/id_0')
        expect(sheet[2][column_index]).to be_a RubyXL::Cell
        sheet[2][column_index].change_contents(nil)

        # Save excel file after updates
        excel_file.write(excel_filename)

        updated_records = {}

        expect do
          updated_records = bulk_archival_object_updater.run
        end.to raise_error BulkArchivalObjectUpdater::BulkUpdateFailed do |bulk_update_failed|
          expect(bulk_update_failed.errors.length).to eq 1
          expect(bulk_update_failed.errors).to eq([
            {
              :sheet=>"Updates",
              :column=>"related_accessions/0/id_0",
              :row=>3,
              :errors => ["Accession not found for identifier: #<BulkArchivalObjectUpdater::AccessionCandidate {:id_0=>nil, :id_1=>\"#{accession.id_1}\", :id_2=>\"#{accession.id_2}\", :id_3=>\"#{accession.id_3}\"}>"]
            }
          ])
        end

        expect(updated_records).to eq({})

        # Ensure archival object titles were not updated.
        reload_archival_object_1 = ::ArchivalObject.where(id: archival_object_1.id).first
        reload_archival_object_2 = ::ArchivalObject.where(id: archival_object_2.id).first
        expect(reload_archival_object_1.title).to eq "Archival Object Title 1 #{uuid}"
        expect(reload_archival_object_2.title).to eq "Archival Object Title 2 #{uuid}"

        total_records_count_after = total_records_count
        expect(total_records_count_before).to eq total_records_count_after
      end
    end

    context 'because the accession is deleted from the excel and the bulk_archival_object_updater_apply_deletes in config is set to false' do
      it 'does not update any of the archival objects and sets a Deleting an accession is disabled error' do
        expect(column_names.length).to eq 177
        total_records_count_before = total_records_count

        # Delete accession from excel by making the four part id null.
        column_index = column_names.find_index('related_accessions/0/id_0')
        expect(sheet[2][column_index]).to be_a RubyXL::Cell
        sheet[2][column_index].change_contents(nil)
        column_index = column_names.find_index('related_accessions/0/id_1')
        expect(sheet[2][column_index]).to be_a RubyXL::Cell
        sheet[2][column_index].change_contents(nil)
        column_index = column_names.find_index('related_accessions/0/id_2')
        expect(sheet[2][column_index]).to be_a RubyXL::Cell
        sheet[2][column_index].change_contents(nil)
        column_index = column_names.find_index('related_accessions/0/id_3')
        expect(sheet[2][column_index]).to be_a RubyXL::Cell
        sheet[2][column_index].change_contents(nil)

        # Save excel file after updates
        excel_file.write(excel_filename)

        updated_records = {}

        expect do
          updated_records = bulk_archival_object_updater.run
        end.to raise_error BulkArchivalObjectUpdater::BulkUpdateFailed do |bulk_update_failed|
          expect(bulk_update_failed.errors.length).to eq 1
          expect(bulk_update_failed.errors).to eq([
            {
              :sheet => "Updates",
              :column => "related_accessions/0",
              :row => 3,
              :errors => ["Deleting a related accession is disabled. Use AppConfig[:bulk_archival_object_updater_apply_deletes] = true to enable."]
            }
          ])
        end

        expect(updated_records).to eq({})

        # Ensure archival object titles were not updated.
        reload_archival_object_1 = ::ArchivalObject.where(id: archival_object_1.id).first
        reload_archival_object_2 = ::ArchivalObject.where(id: archival_object_2.id).first
        expect(reload_archival_object_1.title).to eq "Archival Object Title 1 #{uuid}"
        expect(reload_archival_object_2.title).to eq "Archival Object Title 2 #{uuid}"

        total_records_count_after = total_records_count
        expect(total_records_count_before).to eq total_records_count_after
      end
    end

    context 'because at least one archival object belongs to a different resource', :disable_database_transaction do
      let(:another_resource) do
        create(:json_resource,
          :title => "Another Resource Title #{uuid}",
          :extents => extents,
          :dates => dates,
          :notes => notes,
          :lang_materials => lang_materials
        )
      end

      let!(:archival_object_from_another_resource) do
        create(:json_archival_object,
          :title => "Archival Object Title Belongs to Another Resource #{uuid}",
          :resource => {
            :ref => another_resource.uri
          }
        )
      end

      it 'does not update any of the archival objects and sets archival objects must belong to the same resource error', :disable_database_transaction do
        expect(column_names.length).to eq 177
        total_records_count_before = total_records_count

        # Change the title of achival objects in the downloaded excel.
        sheet[2][2].change_contents('Updated Archival Object Title 1')
        sheet[3][2].change_contents('Updated Archival Object Title 2')

        # Change the id of the first archival object to another one that belongs to another resource
        sheet[2][0].change_contents(archival_object_from_another_resource.id)

        # Save excel file after updates
        excel_file.write(excel_filename)

        updated_records = {}

        expect do
          updated_records = bulk_archival_object_updater.run
        end.to raise_error BulkArchivalObjectUpdater::BulkUpdateFailed do |bulk_update_failed|
          expect(bulk_update_failed.errors).to eq [
            {
              :sheet => "Updates",
              :row => "N/A",
              :column => "id",
              :errors => [ "Archival Objects must all belong to the same resource." ]
            }
          ]
        end

        expect(updated_records).to eq({})

        # Ensure archival object titles were not updated.
        reload_archival_object_1 = ::ArchivalObject.where(id: archival_object_1.id).first
        reload_archival_object_2 = ::ArchivalObject.where(id: archival_object_2.id).first
        reload_archival_object_from_another_resource = ::ArchivalObject.where(id: archival_object_from_another_resource.id).first
        expect(reload_archival_object_1.title).to eq "Archival Object Title 1 #{uuid}"
        expect(reload_archival_object_2.title).to eq "Archival Object Title 2 #{uuid}"
        expect(reload_archival_object_from_another_resource.title).to eq "Archival Object Title Belongs to Another Resource #{uuid}"

        total_records_count_after = total_records_count
        expect(total_records_count_before).to eq total_records_count_after
      end
    end
  end

  def update_empty_sheet_columns(row:, columns_to_update:)
    columns_to_update.each do |column, value|
      column_index = column_names.find_index(column)

      sheet.add_cell(row, column_index, value)
    end
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
      external_ids: ExternalId.count,
      top_containers: ::TopContainer.count
    }
  end
end
