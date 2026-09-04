require 'spec_helper'
require 'converter_spec_helper'
require 'csv'
require_relative '../app/converters/accession_converter'

describe 'Accession converter' do
  let(:extent_headers) do
    %w[
      extent_1_portion
      extent_1_number
      extent_1_extent_type
      extent_1_container_summary
      extent_1_physical_details
      extent_1_dimensions
    ]
  end

  let(:external_document_headers) do
    %w[
      external_document_1_title
      external_document_1_location
      external_document_1_publish
    ]
  end

  let(:subject_headers) do
    %w[
      subject_1_record_id
      subject_1_source
      subject_1_term
      subject_1_term_type
    ]
  end

  let(:instance_headers) do
    %w[
      instance_1_instance_type
      instance_1_top_container_1_uri
      instance_1_top_container_1_type
      instance_1_top_container_1_indicator
      instance_1_top_container_1_barcode
      instance_1_top_container_1_container_profile_1_uri
      instance_1_child_type
      instance_1_child_indicator
      instance_1_child_barcode
      instance_1_grandchild_type
      instance_1_grandchild_indicator
    ]
  end

  let(:accession_id_headers) do
    %w[
      accession_id_1
      accession_id_2
      accession_id_3
      accession_id_4
    ]
  end

  let(:agent_headers) do
    %w[
      agent_1_record_id
      agent_1_role
      agent_1_relator
      agent_1_agent_type
      agent_1_agent_contact_1_address_1
      agent_1_agent_contact_1_address_2
      agent_1_agent_contact_1_address_3
      agent_1_agent_contact_1_city
      agent_1_agent_contact_1_country
      agent_1_agent_contact_1_email
      agent_1_agent_contact_1_fax_1_number
      agent_1_agent_contact_1_name
      agent_1_agent_contact_1_post_code
      agent_1_agent_contact_1_region
      agent_1_agent_contact_1_salutation
      agent_1_agent_contact_1_telephone_1_number
      agent_1_agent_contact_1_telephone_1_ext
      agent_1_agent_name_1_authority_id
      agent_1_agent_name_1_dates
      agent_1_agent_name_1_fuller_form
      agent_1_agent_name_1_name_order
      agent_1_agent_name_1_number
      agent_1_agent_name_1_prefix
      agent_1_agent_name_1_title
      agent_1_agent_name_1_primary_name
      agent_1_agent_name_1_qualifier
      agent_1_agent_name_1_rest_of_name
      agent_1_agent_name_1_rules
      agent_1_agent_name_1_sort_name
      agent_1_agent_name_1_source
      agent_1_agent_name_1_subordinate_name_1
      agent_1_agent_name_1_subordinate_name_2
      agent_1_agent_name_1_suffix
      agent_1_note_1_content
      agent_1_note_1_citation
    ]
  end

  def my_converter
    AccessionConverter
  end

  it 'recognizes higher structural indices without accepting non-contract fields' do
    _handlers, bad_headers = AccessionConverter.configure_cell_handlers(
      [
        'accession_title',
        'user_defined_string_1',
        'extent_45_number',
        'external_document_9_publish',
        'agent_45_record_id',
        'agent_45_agent_name_1_primary_name',
        'subject_45_record_id',
        'instance_45_top_container_1_uri',
        'instance_45_top_container_1_type',
        'instance_45_top_container_1_indicator',
        'instance_45_top_container_1_barcode',
        'instance_45_top_container_1_container_profile_1_uri',
        'instance_45_grandchild_indicator',
      ],
    )
    expect(bad_headers).to be_empty

    _handlers, bad_headers = AccessionConverter.configure_cell_handlers(
      [
        'accession_title',
        'extent_number',
        'extent_45_jsonmodel_type',
        'extent_45_lock_version',
        'external_document_9_jsonmodel_type',
        'external_document_9_lock_version',
        'agent_9_agent_name_2_primary_name',
        'agent_9_agent_contact_2_name',
        'agent_9_uri',
        'subject_9_jsonmodel_type',
        'subject_9_uri',
        'instance_9_top_container_uri',
        'instance_9_top_container_2_uri',
        'instance_9_top_container_1_ils_holding_id',
        'instance_9_top_container_1_container_location_1_uri',
        'instance_9_top_container_1_import_key',
        'instance_9_top_container_1_container_profile_1_name',
        'instance_9_grandchild_barcode',
      ],
    )
    expect(bad_headers).to eq([
      'extent_number',
      'extent_45_jsonmodel_type',
      'extent_45_lock_version',
      'external_document_9_jsonmodel_type',
      'external_document_9_lock_version',
      'agent_9_agent_name_2_primary_name',
      'agent_9_agent_contact_2_name',
      'agent_9_uri',
      'subject_9_jsonmodel_type',
      'subject_9_uri',
      'instance_9_top_container_uri',
      'instance_9_top_container_2_uri',
      'instance_9_top_container_1_ils_holding_id',
      'instance_9_top_container_1_container_location_1_uri',
      'instance_9_top_container_1_import_key',
      'instance_9_top_container_1_container_profile_1_name',
      'instance_9_grandchild_barcode',
    ])
  end

  it 'accepts hierarchical Accession ID and Agent fields without legacy aliases' do
    _handlers, bad_headers = AccessionConverter.configure_cell_handlers(
      ['accession_title', *accession_id_headers, *agent_headers],
    )
    expect(bad_headers).to be_empty

    _handlers, bad_headers = AccessionConverter.configure_cell_handlers(
      [
        'accession_number_1',
        'agent_role',
        'agent_type',
        'agent_contact_name',
        'agent_name_primary_name',
        'agent_name_description_note',
      ],
    )
    expect(bad_headers).to eq([
      'accession_number_1',
      'agent_role',
      'agent_type',
      'agent_contact_name',
      'agent_name_primary_name',
      'agent_name_description_note',
    ])
  end

  it 'keeps the maintained and test templates on the same repeatable field contract' do
    public_template = File.expand_path(
      '../../frontend/public/bulk_import_templates/aspace_accession_import_template.csv',
      __dir__,
    )
    test_template = File.expand_path('examples/aspace_accession_import_template.csv', __dir__)

    public_rows = CSV.read(public_template)
    test_rows = CSV.read(test_template)
    public_headers = public_rows.first
    test_headers = test_rows.first

    expect(public_headers).to eq(test_headers)
    expect(public_rows).to all(have_attributes(:length => public_headers.length))
    expect(test_rows).to all(have_attributes(:length => test_headers.length))
    expect(public_headers.grep(/\Aextent_/)).to eq(extent_headers)
    expect(public_headers.grep(/\Aexternal_document_/)).to eq(external_document_headers)
    expect(public_headers.grep(/\Asubject_/)).to eq(subject_headers)
    expect(public_headers.grep(/\Ainstance_/)).to eq(instance_headers)
    expect(public_headers.grep(/\Aaccession_id_/)).to eq(accession_id_headers)
    expect(public_headers.grep(/\Aagent_/)).to eq(agent_headers)
  end

  context 'when all accessions provided in the CSV are valid' do
    let(:converted_entries) do
      convert(csv_file)
    end

    let(:csv_file) do
      File.expand_path("../../backend/spec/examples/aspace_accession_import_template.csv", File.dirname(__FILE__))
    end

    let(:converted_accessions) do
      converted_entries.select do |entry|
        entry['jsonmodel_type'] == 'accession'
      end
    end

    let(:converted_agents) do
      converted_entries.select do |entry|
        entry['jsonmodel_type'].include?('agent_')
      end
    end

    let(:converted_subjects) do
      converted_entries.select do |entry|
        entry['jsonmodel_type'] == 'subject'
      end
    end

    let(:converted_events) do
      converted_entries.select do |entry|
        entry['jsonmodel_type'] == 'event'
      end
    end

    let(:converted_dates) do
      converted_dates = []

      converted_accessions.each do |accession|
        converted_dates = converted_dates + accession['dates']
      end

      converted_dates
    end

    it "successfully parses and converts records from the CSV" do
      expect(converted_accessions.count).to eq(10)
      expect(converted_agents.count).to eq(5)
      expect(converted_accessions.first).to include(
        'id_0' => 'UD5V1',
        'id_1' => '3EO74',
        'id_2' => 'SX896',
        'id_3' => '4E26P',
      )

      telephones = converted_agents.first['agent_contacts'].map { |c| c['telephones'] }.flatten
      expect(telephones.count).to eq(2)
      expect(telephones[0]['number_type']).to eq('fax')
      expect(telephones[0]['number']).to eq('999-444-4444')
      expect(telephones[1]['number_type']).to eq('home')
      expect(telephones[1]['ext']).to eq('247')

      expect(converted_agents.first['agent_contacts'].first).to include(
        'address_1' => '123 Fake St.',
        'address_2' => 'c/o Max Power',
        'address_3' => 'Apt 213',
        'city' => 'Springfield',
        'country' => 'USA',
        'email' => 'fake@fake.com',
        'name' => 'HOME',
        'post_code' => '74120',
        'region' => 'Central America',
        'salutation' => 'Dr',
      )
      expect(converted_agents.first['names'].first).to include(
        'authority_id' => 'Y12LR',
        'dates' => 'UEQ10',
        'fuller_form' => 'UX092',
        'name_order' => 'direct',
        'number' => '3',
        'prefix' => 'VBOJT',
        'primary_name' => 'PE953',
        'qualifier' => 'The Lesser',
        'rest_of_name' => '57DDD',
        'rules' => 'ciderhouse',
        'sort_name' => 'Jimmy',
        'sort_name_auto_generate' => false,
        'source' => 'local',
        'suffix' => 'T325H',
      )
      expect(converted_agents.first['notes'].first['subnotes']).to contain_exactly(
        include('jsonmodel_type' => 'note_text', 'content' => 'W1FNY'),
        include('jsonmodel_type' => 'note_citation', 'content' => ['IUP88']),
      )

      expect(converted_subjects.count).to eq(8)

      expect(converted_dates.count).to eq(2)

      expect(converted_accessions[0]['publish']).to eq(true)
      expect(converted_accessions[1]['publish']).to eq(false)
      expect(converted_accessions[2]['publish']).to eq(true)
      expect(converted_accessions[3]['publish']).to eq(false)

      expect(converted_events.count).to eq(26)

      converted_dates = converted_events.map { |e| e['date'] }.compact
      expect(converted_dates.count).to eq(26)
      expect(converted_dates.first['expression']).to eq('2001-01-22')

      notes = converted_events.map { |e| e['outcome_note'] }.compact
      expect(notes.count).to eq(6)
      expect(notes.last).to eq('TFY7B')

      notes = converted_events.map { |e| e['outcome_note'] }.compact
      expect(notes).not_to include('7YNN5')
    end
  end

  context 'when at least one accession provided in the CSV has an invalid date type' do
    let(:csv_file) do
      File.expand_path("../../backend/spec/examples/accession_import_with_invalid_date_types.csv", File.dirname(__FILE__))
    end

    it "fails to convert records from the CSV and raises invalid date type error" do
      accessions_count_before = ::Accession.count

      expect do
        convert(csv_file)
      end.to raise_error do |error|
        expect(error).to be_a AccessionConverterInvalidDateTypeError
        expect(error.message).to eq(
          'Invalid date type provided: inclusive dates; ' \
          'must be one of: ["bulk", "inclusive", "single"]; ' \
          'Date provided: #<JSONModel(:date) {"jsonmodel_type"=>"date", "uri"=>nil, "label"=>"Creation", "expression"=>"ca. 2006-2008", "begin"=>"2006", "end"=>"2008", "date_type"=>"inclusive dates"}>;'
        )

        accessions_count_after = ::Accession.count
        expect(accessions_count_before).to eq accessions_count_after
      end
    end
  end
end
