require 'spec_helper'
require 'converter_spec_helper'
require 'csv'
require_relative '../app/converters/accession_converter'

describe 'Accession import batch' do
  def import_accession_csv(headers, rows)
    csv_file = get_tempfile_path(CSV.generate do |csv|
      csv << headers
      rows.each { |row| csv << row }
    end)

    import_accession_csv_file(csv_file)
  end

  def import_accession_csv_file(csv_file)
    converter = Converter.for('accession_csv', csv_file, {:import_events => false, :import_subjects => true})
    converter.run

    job = Job.new
    ticker = Ticker.new(job)

    File.open(converter.get_output_path, "r") do |fh|
      StreamingImport.new(fh, ticker).process
    end
  end

  def accession_fixture(filename)
    File.expand_path("examples/#{filename}", __dir__)
  end

  context 'when the provided CSV has accessions with valid date types' do
    let(:csv_file) do
      File.expand_path("../../backend/spec/examples/accession_import_with_valid_date_types.csv", File.dirname(__FILE__))
    end

    it 'successfully imports the accessions' do
      accessions_count_before = ::Accession.count

      converter = Converter.for('accession_csv', csv_file, {:import_events => false, :import_subjects => true})
      expect(converter).to be_a AccessionConverter

      converter.run

      job = Job.new
      ticker = Ticker.new(job)

      File.open(converter.get_output_path, "r") do |fh|
        batch = StreamingImport.new(fh, ticker)
        batch.process
      end

      accessions_count_after = ::Accession.count
      expect(accessions_count_after).to eq accessions_count_before + 5
    end
  end

  context 'when the provided CSV has accessions with invalid date types' do
    let(:csv_file) do
      File.expand_path("../../backend/spec/examples/accession_import_with_invalid_date_types.csv", File.dirname(__FILE__))
    end

    it 'fails to import the accession' do
      accessions_count_before = ::Accession.count

      converter = Converter.for('accession_csv', csv_file, {:import_events => false, :import_subjects => true})
      expect(converter).to be_a AccessionConverter

      expect do
        converter.run
      end.to raise_error do |error|
        expect(error).to be_a AccessionConverterInvalidDateTypeError
        expect(error.message).to eq 'Invalid date type provided: inclusive dates; must be one of: ["bulk", "inclusive", "single"]; Date provided: #<JSONModel(:date) {"jsonmodel_type"=>"date", "uri"=>nil, "label"=>"Creation", "expression"=>"ca. 2006-2008", "begin"=>"2006", "end"=>"2008", "date_type"=>"inclusive dates"}>;'

        accessions_count_after = ::Accession.count
        expect(accessions_count_before).to eq accessions_count_after
      end
    end
  end

  context 'when the CSV contains repeatable Extent groups' do
    it 'imports complete, higher, and noncontiguous groups and ignores a blank group' do
      accession_id = generate(:alphanumstr)
      headers = [
        'accession_title',
        'accession_id_1',
        'extent_1_portion',
        'extent_1_number',
        'extent_1_extent_type',
        'extent_1_container_summary',
        'extent_1_physical_details',
        'extent_1_dimensions',
        'extent_12_portion',
        'extent_12_number',
        'extent_12_extent_type',
        'extent_12_container_summary',
        'extent_12_physical_details',
        'extent_12_dimensions',
        'extent_30_portion',
        'extent_30_number',
        'extent_30_extent_type',
        'extent_30_container_summary',
        'extent_30_physical_details',
        'extent_30_dimensions',
        'user_defined_string_1',
      ]
      rows = [[
        'Repeatable Extents',
        accession_id,
        'whole',
        '12',
        'linear_feet',
        '12 record cartons',
        'Mixed manuscript material',
        '12 x 15 inches',
        'part',
        '240',
        'gigabytes',
        'Two hard drives',
        'Disk images',
        '240 GB',
        '',
        ' ',
        'NULL',
        '',
        ' ',
        nil,
        'native numeric leaf',
      ]]

      expect do
        import_accession_csv(headers, rows)
      end.to change { Accession.count }.by(1)

      accession = Accession.order(Sequel.desc(:id)).first
      json = Accession.to_jsonmodel(accession.id)

      expect(json['id_0']).to eq(accession_id)
      expect(json.extents.length).to eq(2)
      expect(json.extents[0]).to include(
        'portion' => 'whole',
        'number' => '12',
        'extent_type' => 'linear_feet',
        'container_summary' => '12 record cartons',
        'physical_details' => 'Mixed manuscript material',
        'dimensions' => '12 x 15 inches',
      )
      expect(json.extents[1]).to include(
        'portion' => 'part',
        'number' => '240',
        'extent_type' => 'gigabytes',
        'container_summary' => 'Two hard drives',
        'physical_details' => 'Disk images',
        'dimensions' => '240 GB',
      )
      expect(json.user_defined['string_1']).to eq('native numeric leaf')
    end

    it 'rejects a populated Extent without a portion and imports no rows' do
      accession_count = Accession.count
      headers = [
        'accession_title',
        'accession_id_1',
        'extent_1_portion',
        'extent_1_number',
        'extent_1_extent_type',
        'extent_1_physical_details',
      ]
      rows = [
        ['Valid row', generate(:alphanumstr), 'whole', '1', 'linear_feet', nil],
        ['Invalid row', generate(:alphanumstr), nil, '2', 'linear_feet', nil],
      ]

      expect do
        import_accession_csv(headers, rows)
      end.to raise_error(JSONModel::ValidationException)

      expect(Accession.count).to eq(accession_count)
    end
  end

  context 'when the CSV contains repeatable External Document groups' do
    it 'imports complete, higher, and noncontiguous groups with publish values and defaults and ignores a blank group' do
      accession_id = generate(:alphanumstr)
      headers = [
        'accession_title',
        'accession_id_1',
        'external_document_1_title',
        'external_document_1_location',
        'external_document_1_publish',
        'external_document_12_title',
        'external_document_12_location',
        'external_document_12_publish',
        'external_document_30_title',
        'external_document_30_location',
        'external_document_30_publish',
      ]
      rows = [[
        'Repeatable External Documents',
        accession_id,
        'Published document',
        'https://example.org/published',
        '1',
        'Unpublished document',
        'https://example.org/unpublished',
        '0',
        '',
        ' ',
        nil,
      ]]

      expect do
        import_accession_csv(headers, rows)
      end.to change { Accession.count }.by(1)

      accession = Accession.order(Sequel.desc(:id)).first
      json = Accession.to_jsonmodel(accession.id)

      expect(json['id_0']).to eq(accession_id)
      expect(json.external_documents).to contain_exactly(
        include(
          'title' => 'Published document',
          'location' => 'https://example.org/published',
          'publish' => true,
        ),
        include(
          'title' => 'Unpublished document',
          'location' => 'https://example.org/unpublished',
          'publish' => false,
        ),
      )
    end

    it 'uses the publish preference when publish is blank' do
      headers = [
        'accession_title',
        'accession_id_1',
        'external_document_1_title',
        'external_document_1_location',
        'external_document_1_publish',
      ]
      rows = [[
        'Default document publication',
        generate(:alphanumstr),
        'Default document',
        'https://example.org/default',
        nil,
      ]]

      import_accession_csv(headers, rows)

      accession = Accession.order(Sequel.desc(:id)).first
      expect(Accession.to_jsonmodel(accession.id).external_documents.first['publish']).to eq(Preference.defaults['publish'])
    end

    it 'preserves duplicate title and location validation' do
      headers = [
        'accession_title',
        'accession_id_1',
        'external_document_1_title',
        'external_document_1_location',
        'external_document_2_title',
        'external_document_2_location',
      ]
      rows = [[
        'Duplicate documents',
        generate(:alphanumstr),
        'Duplicate document',
        'https://example.org/duplicate',
        'Duplicate document',
        'https://example.org/duplicate',
      ]]

      expect do
        import_accession_csv(headers, rows)
      end.to raise_error(Sequel::ValidationFailed)
    end

    it 'rejects a partial External Document group and imports no rows' do
      accession_count = Accession.count
      headers = [
        'accession_title',
        'accession_id_1',
        'external_document_1_title',
        'external_document_1_location',
        'external_document_2_title',
        'external_document_2_location',
      ]
      rows = [
        ['Valid row', generate(:alphanumstr), 'Complete document', 'https://example.org/complete', nil, nil],
        ['Partial row', generate(:alphanumstr), nil, 'https://example.org/partial', '', ' '],
      ]

      expect do
        import_accession_csv(headers, rows)
      end.to raise_error(JSONModel::ValidationException)

      expect(Accession.count).to eq(accession_count)
    end
  end

  context 'when the CSV creates Agents through hierarchical fields' do
    let(:valid_agents_csv_file) { accession_fixture('accession_import_with_valid_agent_types.csv') }
    let(:invalid_agent_type_csv_file) { accession_fixture('accession_import_with_invalid_agent_type.csv') }

    it 'links higher and noncontiguous Agent groups with independent relationships and ignores blank groups' do
      existing_person = create(:json_agent_person)
      existing_family = create(:json_agent_family)
      accession_id = generate(:alphanumstr)
      headers = [
        'accession_title',
        'accession_id_1',
        'agent_1_record_id',
        'agent_1_role',
        'agent_1_relator',
        'agent_1_agent_type',
        'agent_12_record_id',
        'agent_12_role',
        'agent_12_relator',
        'agent_12_agent_type',
        'agent_30_record_id',
        'agent_30_role',
        'agent_30_relator',
        'agent_30_agent_type',
      ]
      rows = [[
        'Repeatable linked Agents',
        accession_id,
        existing_person.id,
        'source',
        'dnr',
        'agent_person',
        existing_family.id,
        'creator',
        nil,
        'agent_family',
        '',
        ' ',
        'NULL',
        nil,
      ]]

      expect do
        import_accession_csv(headers, rows)
      end.to change { Accession.count }.by(1)

      accession = Accession.to_jsonmodel(Accession.order(Sequel.desc(:id)).first.id)
      expect(accession['id_0']).to eq(accession_id)
      expect(accession.linked_agents).to contain_exactly(
        include('ref' => existing_person.uri, 'role' => 'source', 'relator' => 'dnr'),
        include('ref' => existing_family.uri, 'role' => 'creator'),
      )
    end

    it 'rejects a linked Agent without a type and imports no rows' do
      existing_agent = create(:json_agent_person)
      accession_count = Accession.count
      headers = [
        'accession_title',
        'accession_id_1',
        'agent_1_record_id',
        'agent_1_role',
        'agent_1_agent_type',
      ]
      rows = [
        ['Valid row', generate(:alphanumstr), nil, nil, nil],
        ['Ambiguous Agent type', generate(:alphanumstr), existing_agent.id, 'creator', nil],
      ]

      expect do
        import_accession_csv(headers, rows)
      end.to raise_error(
        AccessionConverterInvalidAgentTypeError,
        /Agent group 1 must include a supported Agent type when linking record ID #{existing_agent.id}/,
      )

      expect(Accession.count).to eq(accession_count)
    end

    it 'creates every supported Agent type through higher and noncontiguous groups' do
      headers = [
        'accession_title',
        'accession_id_1',
        'agent_1_role',
        'agent_1_relator',
        'agent_1_agent_type',
        'agent_1_agent_name_1_primary_name',
        'agent_1_agent_name_1_name_order',
        'agent_12_role',
        'agent_12_agent_type',
        'agent_12_agent_name_1_primary_name',
        'agent_30_role',
        'agent_30_agent_type',
        'agent_30_agent_name_1_primary_name',
      ]
      rows = [[
        'Repeatable created Agents',
        generate(:alphanumstr),
        'source',
        'dnr',
        'agent_person',
        'Created Person',
        'direct',
        'creator',
        'agent_family',
        'Created Family',
        'subject',
        'agent_corporate_entity',
        'Created Corporation',
      ]]

      expect do
        import_accession_csv(headers, rows)
      end.to change { Accession.count }.by(1)

      accession = Accession.to_jsonmodel(Accession.order(Sequel.desc(:id)).first.id)
      expect(accession.linked_agents.length).to eq(3)

      person_link = accession.linked_agents.find {|relationship| relationship['role'] == 'source' }
      expect(person_link).to include('relator' => 'dnr')
      person = JSONModel(:agent_person).find_by_uri(person_link['ref'])
      expect(person.names.first).to include('primary_name' => 'Created Person', 'name_order' => 'direct')

      family_link = accession.linked_agents.find {|relationship| relationship['role'] == 'creator' }
      family = JSONModel(:agent_family).find_by_uri(family_link['ref'])
      expect(family.names.first).to include('family_name' => 'Created Family')

      corporate_link = accession.linked_agents.find {|relationship| relationship['role'] == 'subject' }
      corporate = JSONModel(:agent_corporate_entity).find_by_uri(corporate_link['ref'])
      expect(corporate.names.first).to include('primary_name' => 'Created Corporation')
    end

    it 'applies schema string normalization to linked and created Agent groups' do
      existing_agent = create(:json_agent_person)
      headers = [
        'accession_title',
        'accession_id_1',
        'agent_1_record_id',
        'agent_1_role',
        'agent_1_agent_type',
        'agent_12_role',
        'agent_12_agent_type',
        'agent_12_agent_name_1_primary_name',
        'agent_12_agent_name_1_name_order',
        'agent_12_agent_contact_1_name',
        'agent_12_agent_contact_1_telephone_1_number',
        'agent_12_agent_contact_1_fax_1_number',
        'agent_12_note_1_content',
        'agent_12_note_1_citation',
      ]
      rows = [[
        'Normalized Agents',
        generate(:alphanumstr),
        "  #{existing_agent.id}  ",
        'source',
        'agent_person',
        'creator',
        'agent_person',
        "  Created\nPerson  ",
        'direct',
        '  Created Contact  ',
        '  555-0101  ',
        '  555-0102  ',
        "  First line\nSecond line  ",
        '  Citation  ',
      ]]

      import_accession_csv(headers, rows)

      accession = Accession.to_jsonmodel(Accession.order(Sequel.desc(:id)).first.id)
      expect(accession.linked_agents).to include(include('ref' => existing_agent.uri, 'role' => 'source'))

      created_link = accession.linked_agents.find {|relationship| relationship['role'] == 'creator' }
      created_agent = JSONModel(:agent_person).find_by_uri(created_link['ref'])
      expect(created_agent.names).to contain_exactly(include('primary_name' => "Created\nPerson"))
      expect(created_agent.agent_contacts).to contain_exactly(include('name' => 'Created Contact'))
      expect(created_agent.agent_contacts.first['telephones']).to contain_exactly(
        include('number_type' => 'home', 'number' => '555-0101'),
        include('number_type' => 'fax', 'number' => '555-0102'),
      )
      expect(created_agent.notes).to contain_exactly(include(
        'subnotes' => contain_exactly(
          include('jsonmodel_type' => 'note_text', 'content' => "First line\nSecond line"),
          include('jsonmodel_type' => 'note_citation', 'content' => ['Citation']),
        ),
      ))
    end

    it 'rejects an Agent group with a record ID and new-Agent fields and imports no rows' do
      existing_agent = create(:json_agent_person)
      accession_count = Accession.count
      headers = [
        'accession_title',
        'accession_id_1',
        'agent_1_record_id',
        'agent_1_role',
        'agent_1_agent_type',
        'agent_1_agent_name_1_primary_name',
      ]
      rows = [
        ['Valid row', generate(:alphanumstr), nil, nil, nil, nil],
        [
          'Ambiguous Agent row',
          generate(:alphanumstr),
          existing_agent.id,
          'creator',
          'agent_person',
          'Also create this Agent',
        ],
      ]

      expect do
        import_accession_csv(headers, rows)
      end.to raise_error(AccessionConverterAgentModeConflictError, /Agent group 1/)

      expect(Accession.count).to eq(accession_count)
    end

    it 'rejects a partial Agent group and imports no rows' do
      accession_count = Accession.count
      headers = [
        'accession_title',
        'accession_id_1',
        'agent_1_role',
        'agent_1_agent_type',
        'agent_1_agent_name_1_primary_name',
        'agent_1_agent_name_1_name_order',
      ]
      rows = [
        ['Valid row', generate(:alphanumstr), nil, nil, nil, nil],
        ['Partial Agent row', generate(:alphanumstr), 'creator', 'agent_person', '   ', 'direct'],
      ]

      expect do
        import_accession_csv(headers, rows)
      end.to raise_error(JSONModel::ValidationException)

      expect(Accession.count).to eq(accession_count)
    end

    it 'persists every existing rich field across the supported Agent types' do
      expect do
        import_accession_csv_file(valid_agents_csv_file)
      end.to change { Accession.count }.by(3)

      accessions_by_title = Accession.order(Sequel.desc(:id)).limit(3).to_h do |record|
        accession = Accession.to_jsonmodel(record.id)
        [accession['title'], accession]
      end

      person_link = accessions_by_title.fetch('Person Agent accession').linked_agents.first
      expect(person_link).to include('role' => 'creator', 'relator' => 'dnr')
      person = JSONModel(:agent_person).find_by_uri(person_link['ref'])
      expect(person.names).to contain_exactly(include(
        'authority_id' => 'person-agent-authority',
        'dates' => '1815-1852',
        'fuller_form' => 'Augusta Ada',
        'name_order' => 'direct',
        'number' => 'I',
        'prefix' => 'Countess',
        'title' => 'Countess of Lovelace',
        'primary_name' => 'Lovelace',
        'qualifier' => 'mathematician',
        'rest_of_name' => 'Ada',
        'rules' => 'local',
        'sort_name' => 'Lovelace, Ada, 1815-1852',
        'source' => 'local',
        'suffix' => 'I',
      ))
      expect(person.agent_contacts).to contain_exactly(include(
        'address_1' => '12 Computing Lane',
        'address_2' => 'Suite 3',
        'address_3' => 'Analytical Engine Building',
        'city' => 'London',
        'country' => 'England',
        'email' => 'ada@example.org',
        'name' => 'Ada Contact',
        'post_code' => 'SW1A 1AA',
        'region' => 'Greater London',
        'salutation' => 'ms',
      ))
      expect(person.agent_contacts.first['telephones']).to contain_exactly(
        include('number_type' => 'fax', 'number' => '555-0102'),
        include('number_type' => 'home', 'number' => '555-0101', 'ext' => '42'),
      )
      expect(person.notes.length).to eq(1)
      expect(person.notes.first['subnotes']).to contain_exactly(
        include('jsonmodel_type' => 'note_text', 'content' => 'Pioneer of mechanical computing.'),
        include('jsonmodel_type' => 'note_citation', 'content' => ['Computing archives, page 42.']),
      )

      family_link = accessions_by_title.fetch('Family Agent accession').linked_agents.first
      expect(family_link).to include('role' => 'source')
      family = JSONModel(:agent_family).find_by_uri(family_link['ref'])
      expect(family.names).to contain_exactly(include(
        'authority_id' => 'family-agent-authority',
        'dates' => '1890-2001',
        'prefix' => 'The',
        'family_name' => 'Example family',
        'qualifier' => 'New York',
        'rules' => 'local',
        'source' => 'local',
      ))

      corporate_link = accessions_by_title.fetch('Corporate Agent accession').linked_agents.first
      expect(corporate_link).to include('role' => 'creator')
      corporate = JSONModel(:agent_corporate_entity).find_by_uri(corporate_link['ref'])
      expect(corporate.names).to contain_exactly(include(
        'authority_id' => 'corporate-agent-authority',
        'dates' => '1970-present',
        'number' => '12th',
        'primary_name' => 'Example Corporation',
        'qualifier' => 'Archives Division',
        'rules' => 'local',
        'source' => 'local',
        'subordinate_name_1' => 'Archives Division',
        'subordinate_name_2' => 'Records Office',
      ))
    end

    it 'rejects software Agent creation and imports no rows' do
      accession_count = Accession.count

      expect do
        import_accession_csv_file(invalid_agent_type_csv_file)
      end.to raise_error(AccessionConverterInvalidAgentTypeError, /agent_software/)

      expect(Accession.count).to eq(accession_count)
    end
  end

  context 'when the CSV contains repeatable Subject groups' do
    it 'rejects legacy Subject headers before importing the batch' do
      accession_count = Accession.count
      headers = [
        'accession_title',
        'accession_id_1',
        'subject_source',
        'subject_term',
        'subject_term_type',
      ]
      rows = [[
        'Legacy Subject headers',
        generate(:alphanumstr),
        'local',
        'Ignored subject',
        'topical',
      ]]

      expect do
        import_accession_csv(headers, rows)
      end.to raise_error(ASpaceImport::CSVConvert::CSVSyntaxException)

      expect(Accession.count).to eq(accession_count)
    end

    it 'creates and links higher, noncontiguous groups while ignoring blank groups' do
      existing_subject = create(:json_subject)
      accession_id = generate(:alphanumstr)
      headers = [
        'accession_title',
        'accession_id_1',
        'subject_1_record_id',
        'subject_12_source',
        'subject_12_term',
        'subject_12_term_type',
        'subject_30_record_id',
        'subject_30_source',
        'subject_30_term',
        'subject_30_term_type',
      ]
      rows = [[
        'Repeatable Subjects',
        accession_id,
        existing_subject.id,
        'local',
        'Created subject',
        'topical',
        '',
        ' ',
        nil,
        'NULL',
      ]]

      expect do
        import_accession_csv(headers, rows)
      end.to change { Accession.count }.by(1)

      accession = Accession.to_jsonmodel(Accession.order(Sequel.desc(:id)).first.id)
      expect(accession['id_0']).to eq(accession_id)
      expect(accession.subjects.map {|subject| subject['ref'] }).to include(existing_subject.uri)

      created_subject = JSONModel(:subject).find_by_uri(
        accession.subjects.map {|subject| subject['ref'] }.find {|uri| uri != existing_subject.uri },
      )
      expect(created_subject['source']).to eq('local')
      expect(created_subject['vocabulary']).to eq('/vocabularies/1')
      expect(created_subject['terms']).to contain_exactly(include(
        'term' => 'Created subject',
        'term_type' => 'topical',
        'vocabulary' => '/vocabularies/1',
      ))
    end

    it 'rejects ambiguous groups and leaves the batch unchanged' do
      accession_count = Accession.count
      headers = [
        'accession_title',
        'accession_id_1',
        'subject_1_record_id',
        'subject_1_term',
      ]
      rows = [
        ['Valid row', generate(:alphanumstr), nil, nil],
        ['Ambiguous row', generate(:alphanumstr), '1', 'Also create this'],
      ]

      expect do
        import_accession_csv(headers, rows)
      end.to raise_error(AccessionConverterSubjectModeConflictError)

      expect(Accession.count).to eq(accession_count)
    end

    it 'rejects a partial Subject create group and imports no rows' do
      accession_count = Accession.count
      headers = [
        'accession_title',
        'accession_id_1',
        'subject_1_source',
        'subject_1_term',
        'subject_1_term_type',
      ]
      rows = [
        ['Valid row', generate(:alphanumstr), 'local', 'Complete subject', 'topical'],
        ['Partial row', generate(:alphanumstr), 'local', '   ', 'topical'],
      ]

      expect do
        import_accession_csv(headers, rows)
      end.to raise_error(JSONModel::ValidationException)

      expect(Accession.count).to eq(accession_count)
    end

    it 'rejects a whitespace-only term type and imports no rows' do
      accession_count = Accession.count
      headers = [
        'accession_title',
        'accession_id_1',
        'subject_1_source',
        'subject_1_term',
        'subject_1_term_type',
      ]
      rows = [
        ['Valid row', generate(:alphanumstr), 'local', 'Complete subject', 'topical'],
        ['Partial row', generate(:alphanumstr), 'local', 'Missing term type', '   '],
      ]

      expect do
        import_accession_csv(headers, rows)
      end.to raise_error(JSONModel::ValidationException)

      expect(Accession.count).to eq(accession_count)
    end
  end

  context 'when the CSV contains repeatable Instance groups' do
    it 'creates Top Containers with optional fields and an optional existing Container Profile' do
      container_profile = create(:json_container_profile)
      accession_id = generate(:alphanumstr)
      first_indicator = generate(:alphanumstr)
      second_indicator = generate(:alphanumstr)
      accession_count = Accession.count
      top_container_count = TopContainer.count
      container_profile_count = ContainerProfile.count
      headers = [
        'accession_title',
        'accession_id_1',
        'instance_1_instance_type',
        'instance_1_top_container_1_type',
        'instance_1_top_container_1_indicator',
        'instance_1_top_container_1_barcode',
        'instance_1_top_container_1_container_profile_1_uri',
        'instance_12_instance_type',
        'instance_12_top_container_1_type',
        'instance_12_top_container_1_indicator',
        'instance_12_top_container_1_barcode',
        'instance_12_top_container_1_container_profile_1_uri',
      ]
      rows = [[
        'Created Top Containers',
        accession_id,
        'mixed_materials',
        'box',
        first_indicator,
        'created-barcode',
        container_profile.uri,
        'text',
        '',
        second_indicator,
        '',
        '',
      ]]

      import_accession_csv(headers, rows)

      expect(Accession.count).to eq(accession_count + 1)
      expect(TopContainer.count).to eq(top_container_count + 2)
      expect(ContainerProfile.count).to eq(container_profile_count)

      first_top_container = TopContainer.to_jsonmodel(TopContainer.filter(:indicator => first_indicator).first.id)
      second_top_container = TopContainer.to_jsonmodel(TopContainer.filter(:indicator => second_indicator).first.id)
      expect(first_top_container).to include(
        'type' => 'box',
        'indicator' => first_indicator,
        'barcode' => 'created-barcode',
        'container_profile' => include('ref' => container_profile.uri),
      )
      expect(second_top_container).to include('indicator' => second_indicator)
      expect(second_top_container).not_to have_key('container_profile')

      accession = Accession.to_jsonmodel(Accession.order(Sequel.desc(:id)).first.id)
      expect(accession['id_0']).to eq(accession_id)
      expect(accession.instances).to contain_exactly(
        include(
          'instance_type' => 'mixed_materials',
          'sub_container' => include(
            'top_container' => include('ref' => first_top_container.uri),
          ),
        ),
        include(
          'instance_type' => 'text',
          'sub_container' => include(
            'top_container' => include('ref' => second_top_container.uri),
          ),
        ),
      )
    end

    it 'rejects an existing Top Container URI combined with creation values' do
      top_container = create(:json_top_container)
      container_profile = create(:json_container_profile)
      accession_count = Accession.count
      top_container_count = TopContainer.count
      creation_values = {
        'instance_1_top_container_1_type' => 'box',
        'instance_1_top_container_1_indicator' => generate(:alphanumstr),
        'instance_1_top_container_1_barcode' => generate(:alphanumstr),
        'instance_1_top_container_1_container_profile_1_uri' => container_profile.uri,
      }

      creation_values.each do |header, value|
        headers = [
          'accession_title',
          'accession_id_1',
          'instance_1_instance_type',
          'instance_1_top_container_1_uri',
          header,
          'instance_1_child_indicator',
        ]
        rows = [[
          'Conflicting Top Container modes',
          generate(:alphanumstr),
          'mixed_materials',
          top_container.uri,
          value,
          '2',
        ]]

        expect do
          import_accession_csv(headers, rows)
        end.to raise_error(AccessionConverterTopContainerModeConflictError, /Instance group 1/)
      end

      expect(Accession.count).to eq(accession_count)
      expect(TopContainer.count).to eq(top_container_count)
    end

    it 'rejects a partial Top Container creation and imports no rows' do
      accession_count = Accession.count
      top_container_count = TopContainer.count
      headers = [
        'accession_title',
        'accession_id_1',
        'instance_1_instance_type',
        'instance_1_top_container_1_type',
        'instance_1_top_container_1_indicator',
      ]
      rows = [
        ['Valid row', generate(:alphanumstr), 'mixed_materials', 'box', generate(:alphanumstr)],
        ['Partial row', generate(:alphanumstr), 'mixed_materials', 'box', '   '],
      ]

      expect do
        import_accession_csv(headers, rows)
      end.to raise_error(JSONModel::ValidationException)

      expect(Accession.count).to eq(accession_count)
      expect(TopContainer.count).to eq(top_container_count)
    end

    it 'rejects a canonical URI for a missing Container Profile and imports no rows' do
      container_profile = create(:json_container_profile)
      missing_id = container_profile.uri.split('/').last.to_i + 100_000
      missing_uri = "/container_profiles/#{missing_id}"
      accession_count = Accession.count
      top_container_count = TopContainer.count
      headers = [
        'accession_title',
        'accession_id_1',
        'instance_1_instance_type',
        'instance_1_top_container_1_indicator',
        'instance_1_top_container_1_container_profile_1_uri',
      ]
      rows = [
        ['Valid row', generate(:alphanumstr), 'mixed_materials', generate(:alphanumstr), container_profile.uri],
        ['Missing Container Profile URI row', generate(:alphanumstr), 'mixed_materials', generate(:alphanumstr), missing_uri],
      ]

      expect do
        import_accession_csv(headers, rows)
      end.to raise_error(ReferenceError, /Reference does not exist/)

      expect(Accession.count).to eq(accession_count)
      expect(TopContainer.count).to eq(top_container_count)
    end

    it 'rejects Top Container fields outside the import contract' do
      accession_count = Accession.count
      top_container_count = TopContainer.count
      headers = [
        'accession_title',
        'accession_id_1',
        'instance_1_instance_type',
        'instance_1_top_container_1_indicator',
        'instance_1_top_container_1_ils_holding_id',
        'instance_1_top_container_1_container_location_1_uri',
        'instance_1_top_container_1_import_key',
        'instance_1_top_container_1_container_profile_1_name',
      ]
      rows = [[
        'Excluded Top Container fields',
        generate(:alphanumstr),
        'mixed_materials',
        generate(:alphanumstr),
        'holding-id',
        '/locations/1',
        'shared-key',
        'Create this profile',
      ]]

      expect do
        import_accession_csv(headers, rows)
      end.to raise_error(ASpaceImport::CSVConvert::CSVSyntaxException)

      expect(Accession.count).to eq(accession_count)
      expect(TopContainer.count).to eq(top_container_count)
    end

    it 'links higher and noncontiguous Instances and imports scalar container positions' do
      first_top_container = create(:json_top_container)
      second_top_container = create(:json_top_container)
      accession_id = generate(:alphanumstr)
      headers = [
        'accession_title',
        'accession_id_1',
        'instance_1_instance_type',
        'instance_1_top_container_1_uri',
        'instance_1_child_type',
        'instance_1_child_indicator',
        'instance_1_child_barcode',
        'instance_1_grandchild_type',
        'instance_1_grandchild_indicator',
        'instance_12_instance_type',
        'instance_12_top_container_1_uri',
        'instance_30_instance_type',
        'instance_30_top_container_1_uri',
      ]
      rows = [[
        'Repeatable Instances',
        accession_id,
        'mixed_materials',
        first_top_container.uri,
        'box',
        '2',
        'child-barcode',
        'folder',
        '3',
        'text',
        second_top_container.uri,
        '',
        ' ',
      ]]

      expect do
        import_accession_csv(headers, rows)
      end.to change { Accession.count }.by(1)

      accession = Accession.to_jsonmodel(Accession.order(Sequel.desc(:id)).first.id)
      expect(accession['id_0']).to eq(accession_id)
      expect(accession.instances).to contain_exactly(
        include(
          'instance_type' => 'mixed_materials',
          'sub_container' => include(
            'top_container' => include('ref' => first_top_container.uri),
            'type_2' => 'box',
            'indicator_2' => '2',
            'barcode_2' => 'child-barcode',
            'type_3' => 'folder',
            'indicator_3' => '3',
          ),
        ),
        include(
          'instance_type' => 'text',
          'sub_container' => include(
            'top_container' => include('ref' => second_top_container.uri),
          ),
        ),
      )
    end

    it 'links one existing Top Container to multiple imported Accessions' do
      top_container = create(:json_top_container)
      headers = [
        'accession_title',
        'accession_id_1',
        'instance_1_instance_type',
        'instance_1_top_container_1_uri',
      ]
      rows = [
        ['First shared container Accession', generate(:alphanumstr), 'mixed_materials', top_container.uri],
        ['Second shared container Accession', generate(:alphanumstr), 'text', top_container.uri],
      ]

      expect do
        import_accession_csv(headers, rows)
      end.to change { Accession.count }.by(2)

      imported = Accession.order(Sequel.desc(:id)).limit(2).map do |accession|
        Accession.to_jsonmodel(accession.id)
      end
      expect(imported.map {|accession| accession.instances.first['sub_container']['top_container']['ref'] }).to eq(
        [top_container.uri, top_container.uri],
      )
    end

    it 'rejects bare and shortened Top Container identifiers before importing the batch' do
      headers = [
        'accession_title',
        'accession_id_1',
        'instance_1_instance_type',
        'instance_1_top_container_1_uri',
      ]

      ['123', '/top_containers/123'].each do |invalid_uri|
        accession_count = Accession.count

        expect do
          import_accession_csv(
            headers,
            [['Invalid Top Container URI', generate(:alphanumstr), 'mixed_materials', invalid_uri]],
          )
        end.to raise_error(AccessionConverterInvalidTopContainerURIError, /#{Regexp.escape(invalid_uri)}/)

        expect(Accession.count).to eq(accession_count)
      end
    end

    it 'rejects a populated Instance without an Instance type and imports no rows' do
      top_container = create(:json_top_container)
      accession_count = Accession.count
      headers = [
        'accession_title',
        'accession_id_1',
        'instance_1_instance_type',
        'instance_1_top_container_1_uri',
      ]
      rows = [
        ['Valid row', generate(:alphanumstr), 'mixed_materials', top_container.uri],
        ['Partial row', generate(:alphanumstr), ' ', top_container.uri],
      ]

      expect do
        import_accession_csv(headers, rows)
      end.to raise_error(JSONModel::ValidationException)

      expect(Accession.count).to eq(accession_count)
    end

    it 'rejects a canonical URI for a missing Top Container and imports no rows' do
      top_container = create(:json_top_container)
      missing_id = top_container.uri.split('/').last.to_i + 100_000
      missing_uri = "/repositories/#{$repo_id}/top_containers/#{missing_id}"
      accession_count = Accession.count
      headers = [
        'accession_title',
        'accession_id_1',
        'instance_1_instance_type',
        'instance_1_top_container_1_uri',
      ]
      rows = [
        ['Valid row', generate(:alphanumstr), 'mixed_materials', top_container.uri],
        ['Missing Top Container row', generate(:alphanumstr), 'mixed_materials', missing_uri],
      ]

      expect do
        import_accession_csv(headers, rows)
      end.to raise_error(ReferenceError, /Reference does not exist/)

      expect(Accession.count).to eq(accession_count)
    end

    it 'rejects a populated Instance without a Top Container and imports no rows' do
      accession_count = Accession.count
      headers = [
        'accession_title',
        'accession_id_1',
        'instance_1_instance_type',
        'instance_1_top_container_1_uri',
        'instance_1_child_indicator',
      ]
      rows = [
        ['Valid row', generate(:alphanumstr), nil, nil, nil],
        ['Partial row', generate(:alphanumstr), 'mixed_materials', nil, '2'],
      ]

      expect do
        import_accession_csv(headers, rows)
      end.to raise_error(JSONModel::ValidationException)

      expect(Accession.count).to eq(accession_count)
    end
  end

  context 'when the CSV combines every repeatable family' do
    it 'imports all supported families together and ignores a blank Extent group' do
      existing_subject = create(:json_subject)
      existing_agent = create(:json_agent_person)
      existing_top_container = create(:json_top_container)
      accession_id = generate(:alphanumstr)
      created_indicator = generate(:alphanumstr)
      top_container_count = TopContainer.count
      headers = [
        'accession_title',
        'accession_id_1',
        'extent_1_portion',
        'extent_1_number',
        'extent_1_extent_type',
        'extent_12_portion',
        'extent_12_number',
        'extent_12_extent_type',
        'extent_30_portion',
        'extent_30_number',
        'extent_30_extent_type',
        'external_document_1_title',
        'external_document_1_location',
        'external_document_1_publish',
        'subject_1_record_id',
        'subject_12_source',
        'subject_12_term',
        'subject_12_term_type',
        'agent_1_record_id',
        'agent_1_role',
        'agent_1_agent_type',
        'agent_12_role',
        'agent_12_agent_type',
        'agent_12_agent_name_1_primary_name',
        'agent_12_agent_name_1_name_order',
        'instance_1_instance_type',
        'instance_1_top_container_1_uri',
        'instance_12_instance_type',
        'instance_12_top_container_1_type',
        'instance_12_top_container_1_indicator',
        'instance_12_top_container_1_barcode',
      ]
      rows = [[
        'Combined families',
        accession_id,
        'whole',
        '12',
        'linear_feet',
        'part',
        '2',
        'cubic_feet',
        '',
        ' ',
        nil,
        'Unpublished finding aid',
        'https://example.org/unpublished',
        '0',
        existing_subject.id,
        'local',
        'Combined created subject',
        'topical',
        existing_agent.id,
        'source',
        'agent_person',
        'creator',
        'agent_person',
        'Combined Created Person',
        'direct',
        'mixed_materials',
        existing_top_container.uri,
        'text',
        'box',
        created_indicator,
        'combined-barcode',
      ]]

      expect do
        import_accession_csv(headers, rows)
      end.to change { Accession.count }.by(1)

      expect(TopContainer.count).to eq(top_container_count + 1)

      accession = Accession.to_jsonmodel(Accession.order(Sequel.desc(:id)).first.id)
      expect(accession['id_0']).to eq(accession_id)
      expect(accession.extents).to contain_exactly(
        include('portion' => 'whole', 'number' => '12', 'extent_type' => 'linear_feet'),
        include('portion' => 'part', 'number' => '2', 'extent_type' => 'cubic_feet'),
      )
      expect(accession.external_documents).to contain_exactly(
        include(
          'title' => 'Unpublished finding aid',
          'location' => 'https://example.org/unpublished',
          'publish' => false,
        ),
      )
      expect(accession.subjects.map {|subject| subject['ref'] }).to include(existing_subject.uri)

      created_subject = JSONModel(:subject).find_by_uri(
        accession.subjects.map {|subject| subject['ref'] }.find {|uri| uri != existing_subject.uri },
      )
      expect(created_subject['source']).to eq('local')
      expect(created_subject['vocabulary']).to eq('/vocabularies/1')
      expect(created_subject['terms']).to contain_exactly(include(
        'term' => 'Combined created subject',
        'term_type' => 'topical',
        'vocabulary' => '/vocabularies/1',
      ))

      expect(accession.linked_agents).to include(
        include('ref' => existing_agent.uri, 'role' => 'source'),
      )
      created_agent_link = accession.linked_agents.find {|relationship| relationship['role'] == 'creator' }
      created_agent = JSONModel(:agent_person).find_by_uri(created_agent_link['ref'])
      expect(created_agent.names.first).to include(
        'primary_name' => 'Combined Created Person',
        'name_order' => 'direct',
      )

      created_top_container = TopContainer.to_jsonmodel(
        TopContainer.filter(:indicator => created_indicator).first.id,
      )
      expect(created_top_container).to include(
        'type' => 'box',
        'indicator' => created_indicator,
        'barcode' => 'combined-barcode',
      )
      expect(accession.instances).to contain_exactly(
        include(
          'instance_type' => 'mixed_materials',
          'sub_container' => include(
            'top_container' => include('ref' => existing_top_container.uri),
          ),
        ),
        include(
          'instance_type' => 'text',
          'sub_container' => include(
            'top_container' => include('ref' => created_top_container.uri),
          ),
        ),
      )
    end

    it 'rejects a mixed create and link group and imports no Accessions from the file' do
      existing_subject = create(:json_subject)
      accession_count = Accession.count
      headers = [
        'accession_title',
        'accession_id_1',
        'extent_1_portion',
        'extent_1_number',
        'extent_1_extent_type',
        'subject_1_record_id',
        'subject_1_term',
      ]
      rows = [
        ['Valid combined row', generate(:alphanumstr), 'whole', '1', 'linear_feet', nil, nil],
        [
          'Mixed Subject intent',
          generate(:alphanumstr),
          'whole',
          '2',
          'linear_feet',
          existing_subject.id,
          'Also create this Subject',
        ],
      ]

      expect do
        import_accession_csv(headers, rows)
      end.to raise_error(AccessionConverterSubjectModeConflictError)

      expect(Accession.count).to eq(accession_count)
    end
  end
end
