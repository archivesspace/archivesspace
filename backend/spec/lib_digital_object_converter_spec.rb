# encoding: utf-8
require 'spec_helper'
require 'converter_spec_helper'
require 'csv'

require_relative '../app/converters/digital_object_converter'

describe 'Digital Object converter' do

  def my_converter
    DigitalObjectConverter
  end


  before(:all) do
    test_file = File.expand_path("../../frontend/public/bulk_import_templates/aspace_digital_object_import_template.csv",
                                 File.dirname(__FILE__))
    @records = RequestContext.open(:current_username => 'admin') { convert(test_file) }
    @digital_objects = @records.select {|r| r['jsonmodel_type'] == 'digital_object' }
  end


  it "did something" do
    expect(@digital_objects[0]).not_to be_nil

    expect(@digital_objects[0]['jsonmodel_type']).to eq('digital_object')
    expect(@digital_objects[0]['level']).to eq('image')
    expect(@digital_objects[0]['title']).to eq('a new digital object')
    expect(@digital_objects[0]['publish']).to be_truthy
  end



  it "maps digital_object_file version information to the object" do
    expect(@digital_objects[0]['file_versions'].length).to eq(1)
    {"jsonmodel_type"=>"file_version", "uri"=>nil, "file_uri"=>"http://aspace.me", "publish"=>true, "use_statement"=>"It's all good", "xlink_actuate_attribute"=>"onRequest", "xlink_show_attribute"=>"embed", "file_format_name"=>"jpeg", "file_format_version"=>"1", "file_size_bytes"=>100, "checksum"=>"xxxxxxx", "checksum_method"=>"md5"}.each do |k, v|
      expect(@digital_objects[0]["file_versions"][0][k]).to eq(v)
    end
    expect(@digital_objects[0]["file_versions"][0]["file_size_bytes"]).to be_a(Integer)
  end


  describe "utf-8 encoding" do
    let(:test_file_bom) {
      File.expand_path('./examples/digital_object/test_digital_object_utf8_bom.csv',
                       File.dirname(__FILE__))
    }

    it "does something even if its a kooky utf-8 file with a BOM" do
      @records = convert(test_file_bom)
      @digital_objects = @records.select {|r| r['jsonmodel_type'] == 'digital_object' }

      expect(@digital_objects[0]).not_to be_nil

      expect(@digital_objects[0]['jsonmodel_type']).to eq('digital_object')
      expect(@digital_objects[0]['title']).to eq('DO test ¥j¥ü¥Ó/anne')
    end
  end

  describe "multiple file versions" do
    before(:all) do
      test_file = File.expand_path('./examples/digital_object/test_digital_object_multi_file_versions.csv',
                                   File.dirname(__FILE__))
      @multi_records = convert(test_file)
      @multi_dos = @multi_records.select {|r| r['jsonmodel_type'] == 'digital_object' }
    end

    it "creates a file version for each numbered column group" do
      expect(@multi_dos[0]['file_versions'].length).to eq(2)
    end

    it "maps _1 file version fields correctly" do
      fv = @multi_dos[0]['file_versions'][0]
      expect(fv['file_uri']).to eq('http://example.com/file1.jpg')
      expect(fv['publish']).to be true
      expect(fv['is_display_thumbnail']).to be true
      expect(fv['caption']).to eq('First file')
    end

    it "maps _2 file version fields correctly" do
      fv = @multi_dos[0]['file_versions'][1]
      expect(fv['file_uri']).to eq('http://example.com/file2.pdf')
      expect(fv['publish']).to be false
      expect(fv['is_display_thumbnail']).to be_falsey
      expect(fv['is_display_link']).to be false
      expect(fv['caption']).to eq('Second file')
    end

    it "skips a numbered group whose URI is the literal string NULL" do
      do_with_null_uri = @multi_dos[1]
      expect(do_with_null_uri['file_versions'].length).to eq(1)
      expect(do_with_null_uri['file_versions'][0]['file_uri']).to eq('http://example.com/only.jpg')
    end

    it "skips a numbered group whose URI is blank" do
      expect(@multi_dos[2]['file_versions'].length).to eq(1)
      expect(@multi_dos[2]['file_versions'][0]['file_uri']).to eq('http://example.com/blank.jpg')
    end

    it "strips leading and trailing whitespace from string fields" do
      expect(@multi_dos[3]['file_versions'][0]['caption']).to eq('Padded caption')
    end

    it "treats the literal string NULL in a non-URI field as unset" do
      fv = @multi_dos[4]['file_versions'][0]
      expect(fv['file_uri']).to eq('http://example.com/nullfield.jpg')
      expect(fv['caption']).to be_nil
    end
  end


  describe "file version headers" do
    it "rejects a file_version header that does not name a file version property" do
      _handlers, bad_headers = DigitalObjectConverter.configure_cell_handlers(
        ['digital_object_id', 'digital_object_title',
         'file_version_file_uri_1', 'file_version_is_display_thumbnail_1', 'file_version_is_representative_1'],
      )

      expect(bad_headers).to eq(['file_version_is_representative_1'])
    end
  end


  describe "duplicate file version headers" do
    it "permits legacy headers that remain in the maintained template" do
      _handlers, bad_headers = DigitalObjectConverter.configure_cell_handlers(
        [
          'digital_object_id',
          'digital_object_title',
          'agent_name_description_type',
          'digital_object_rights_transferred',
          'digital_object_rights_transferred_date',
          'digital_object_rights_transferred_note',
        ],
      )

      expect(bad_headers).to be_empty
    end

    it "raises an error when file_version headers are duplicated" do
      headers = ['digital_object_id', 'digital_object_title',
                 'file_version_file_uri_1', 'file_version_publish_1',
                 'file_version_file_uri_1', 'file_version_publish_1']
      expect {
        DigitalObjectConverter.configure_cell_handlers(headers)
      }.to raise_error(ASpaceImport::CSVConvert::CSVSyntaxException)
    end

    it "reports duplicated file_version headers with a translated message" do
      headers = ['digital_object_id', 'digital_object_title',
                 'file_version_file_uri_1', 'file_version_publish_1',
                 'file_version_file_uri_1', 'file_version_publish_1']

      expect(I18n.exists?('importer.error.duplicate_file_version_headers')).to be true

      expect {
        DigitalObjectConverter.configure_cell_handlers(headers)
      }.to raise_error(
        ASpaceImport::CSVConvert::CSVSyntaxException,
        I18n.t('importer.error.duplicate_file_version_headers',
               :columns => 'file_version_file_uri_1, file_version_publish_1'),
      )
    end
  end


  describe "file version backward compatibility" do
    before(:all) do
      test_file = File.expand_path('./examples/digital_object/test_digital_object_backward_compat.csv',
                                   File.dirname(__FILE__))
      @compat_records = convert(test_file)
      @compat_dos = @compat_records.select {|r| r['jsonmodel_type'] == 'digital_object' }
    end

    it "handles un-suffixed file_version_* columns from old CSVs" do
      expect(@compat_dos[0]['file_versions'].length).to eq(1)
      expect(@compat_dos[0]['file_versions'][0]['file_uri']).to eq('http://example.com/oldstyle.jpg')
      expect(@compat_dos[0]['file_versions'][0]['publish']).to be true
      expect(@compat_dos[0]['file_versions'][0]['caption']).to eq('Old style')
    end
  end


  describe "events" do
    def convert_csv(headers, *rows)
      convert(get_tempfile_path(CSV.generate do |csv|
        csv << headers
        rows.each { |row| csv << row }
      end))
    end

    def records_of_type(records, type)
      records.select { |record| record['jsonmodel_type'] == type }
    end

    it "creates an Event linked to the row's Digital Object" do
      records = convert_csv(
        %w[digital_object_id digital_object_title event_1_type event_1_date_begin],
        ['do-event-1', 'Event DO', 'cataloged', '1999-03-03'],
      )
      digital_object = records_of_type(records, 'digital_object').first
      events = records_of_type(records, 'event')

      aggregate_failures do
        expect(events.length).to eq(1)
        expect(events[0]['event_type']).to eq('cataloged')
        expect(events[0]['linked_records']).to eq([{ 'role' => 'source', 'ref' => digital_object['uri'] }])
        expect(events[0]['linked_agents']).to eq([
          { 'role' => 'executing_program', 'ref' => AgentSoftware.archivesspace_record.uri },
        ])
        expect(events[0]['date']).to include('begin' => '1999-03-03', 'label' => 'other', 'date_type' => 'single')
      end
    end

    it "maps every Event field from the maintained template" do
      agent_uri = create(:json_agent_person).uri
      records = convert_csv(
        %w[digital_object_id digital_object_title event_1_type event_1_outcome event_1_outcome_note
           event_1_date_begin event_1_date_label event_1_date_expression event_1_date_certainty
           event_1_date_era event_1_date_calendar event_1_agent_1_record_id event_1_agent_1_agent_type
           event_1_agent_1_role],
        ['do-event-full', 'Event DO', 'processed', 'pass', 'Checked', '2001-02', 'creation', 'February 2001',
         'approximate', 'ce', 'gregorian', agent_uri, '', 'implementer'],
      )
      event = records_of_type(records, 'event').first

      aggregate_failures do
        expect(event['outcome']).to eq('pass')
        expect(event['outcome_note']).to eq('Checked')
        expect(event['date']).to include(
          'begin' => '2001-02', 'label' => 'creation', 'expression' => 'February 2001',
          'certainty' => 'approximate', 'era' => 'ce', 'calendar' => 'gregorian', 'date_type' => 'single'
        )
        expect(event['linked_agents']).to eq([{ 'role' => 'implementer', 'ref' => agent_uri }])
      end
    end

    it "links an Agent by numeric ID and Agent Type" do
      agent = create(:json_agent_corporate_entity)
      records = convert_csv(
        %w[digital_object_id digital_object_title event_1_type event_1_date_expression
           event_1_agent_1_record_id event_1_agent_1_agent_type event_1_agent_1_role],
        ['do-event-numeric', 'Event DO', 'cataloged', 'undated', agent.id.to_s, 'corporate_entity', 'implementer'],
      )

      expect(records_of_type(records, 'event').first['linked_agents']).to eq([
        { 'role' => 'implementer', 'ref' => agent.uri },
      ])
    end

    it "ignores a blank Event group" do
      records = convert_csv(
        %w[digital_object_id digital_object_title event_1_type event_1_date_begin],
        ['do-event-blank', 'Event DO', '', ' '],
      )

      aggregate_failures do
        expect(records_of_type(records, 'digital_object').length).to eq(1)
        expect(records_of_type(records, 'event')).to be_empty
      end
    end

    it "creates one Event per filled group across gaps" do
      records = convert_csv(
        %w[digital_object_id digital_object_title event_5_type event_5_date_begin
           event_1_type event_1_date_begin event_2_type event_2_date_expression],
        ['do-event-groups', 'Event DO', 'processed', '2005', 'cataloged', '2001', 'acknowledgement_sent', 'later'],
      )

      expect(records_of_type(records, 'event').map { |event| event['event_type'] }).to contain_exactly(
        'cataloged', 'acknowledgement_sent', 'processed'
      )
    end

    it "fails on a partly filled Event group" do
      expect {
        convert_csv(
          %w[digital_object_id digital_object_title event_1_type event_1_date_begin event_1_outcome],
          ['do-event-partial', 'Event DO', '', '', 'pass'],
        )
      }.to raise_error(
        DigitalObjectConverterEventError,
        [
          I18n.t('importer.error.event_required_field', :index => 1, :field => 'event_1_type'),
          I18n.t('importer.error.event_date_required', :index => 1,
                 :begin_field => 'event_1_date_begin', :expression_field => 'event_1_date_expression'),
        ].join("\n")
      )
    end

    it "fails on controlled values that are not in their lists, without adding them" do
      expect {
        convert_csv(
          %w[digital_object_id digital_object_title event_1_type event_1_date_begin event_1_date_certainty],
          ['do-event-invalid', 'Event DO', 'not_a_type', '1999', 'not_a_certainty'],
        )
      }.to raise_error(
        DigitalObjectConverterEventError,
        [
          I18n.t('importer.error.event_invalid_controlled_value', :index => 1,
                 :field => 'event_1_type', :value => 'not_a_type'),
          I18n.t('importer.error.event_invalid_controlled_value', :index => 1,
                 :field => 'event_1_date_certainty', :value => 'not_a_certainty'),
        ].join("\n")
      )

      expect(Enumeration.filter(:name => 'event_event_type').first.enumeration_value.map(&:value))
        .not_to include('not_a_type')
    end

    it "fails on Event fields in a Digital Object Component row" do
      expect {
        convert_csv(
          %w[digital_object_id digital_object_title digital_object_is_component digital_object_component_id
             event_1_type event_1_date_begin],
          ['do-event-parent', 'Parent DO', 'FALSE', '', '', ''],
          ['do-event-parent', 'Child', 'TRUE', 'child-1', 'cataloged', '1999'],
        )
      }.to raise_error(
        DigitalObjectConverterEventError,
        I18n.t('importer.error.event_without_digital_object', :index => 1)
      )
    end

    it "fails on a date qualifier with no Begin or Expression" do
      expect {
        convert_csv(
          %w[digital_object_id digital_object_title event_1_type event_1_date_label],
          ['do-event-label-only', 'Event DO', 'cataloged', 'creation'],
        )
      }.to raise_error(
        DigitalObjectConverterEventError,
        I18n.t('importer.error.event_field_requires_date', :index => 1, :field => 'event_1_date_label',
               :value => 'creation', :begin_field => 'event_1_date_begin',
               :expression_field => 'event_1_date_expression')
      )
    end

    it "fails on a Begin date that is not a valid date" do
      expect {
        convert_csv(
          %w[digital_object_id digital_object_title event_1_type event_1_date_begin],
          ['do-event-bad-date', 'Event DO', 'cataloged', '1999/03'],
        )
      }.to raise_error(
        DigitalObjectConverterEventError,
        I18n.t('importer.error.event_invalid_date_begin', :index => 1,
               :field => 'event_1_date_begin', :value => '1999/03')
      )
    end

    it "fails on an Agent with no Role and a record ID that is not a number or an Agent URI" do
      expect {
        convert_csv(
          %w[digital_object_id digital_object_title event_1_type event_1_date_begin
             event_1_agent_1_record_id event_1_agent_1_role],
          ['do-event-bad-agent-id', 'Event DO', 'cataloged', '1999', 'abc', ''],
        )
      }.to raise_error(
        DigitalObjectConverterEventError,
        [
          I18n.t('importer.error.event_required_field', :index => 1, :field => 'event_1_agent_1_role'),
          I18n.t('importer.error.event_invalid_agent_record_id', :index => 1,
                 :field => 'event_1_agent_1_record_id', :value => 'abc'),
        ].join("\n")
      )
    end

    it "fails on an Agent Type filled in next to an Agent URI" do
      expect {
        convert_csv(
          %w[digital_object_id digital_object_title event_1_type event_1_date_begin
             event_1_agent_1_record_id event_1_agent_1_agent_type event_1_agent_1_role],
          ['do-event-uri-and-type', 'Event DO', 'cataloged', '1999',
           JSONModel(:agent_person).uri_for(15), 'person', 'implementer'],
        )
      }.to raise_error(
        DigitalObjectConverterEventError,
        I18n.t('importer.error.event_agent_type_with_uri', :index => 1, :field => 'event_1_agent_1_agent_type',
               :record_field => 'event_1_agent_1_record_id', :value => 'person')
      )
    end

    it "fails on an Agent record ID that does not match an existing Agent" do
      missing_agent_uri = JSONModel(:agent_person).uri_for(999_999)

      expect {
        convert_csv(
          %w[digital_object_id digital_object_title event_1_type event_1_date_begin
             event_1_agent_1_record_id event_1_agent_1_role],
          ['do-event-missing-agent', 'Event DO', 'cataloged', '1999', missing_agent_uri, 'implementer'],
        )
      }.to raise_error(
        DigitalObjectConverterEventError,
        I18n.t('importer.error.event_agent_not_found', :index => 1,
               :field => 'event_1_agent_1_record_id', :value => missing_agent_uri)
      )
    end

    it "fails on an Agent Type that is not supported" do
      expect {
        convert_csv(
          %w[digital_object_id digital_object_title event_1_type event_1_date_begin
             event_1_agent_1_record_id event_1_agent_1_agent_type event_1_agent_1_role],
          ['do-event-bad-agent-type', 'Event DO', 'cataloged', '1999', '27', 'widget', 'implementer'],
        )
      }.to raise_error(
        DigitalObjectConverterEventError,
        I18n.t('importer.error.event_agent_unsupported_type', :index => 1, :field => 'event_1_agent_1_agent_type',
               :value => 'widget', :accepted => EventBuilder.agent_types.join(', '))
      )
    end

    it "imports an Event that appears among the linked Agent's Events" do
      agent = create(:json_agent_person)
      csv_file = get_tempfile_path(CSV.generate do |csv|
        csv << %w[digital_object_id digital_object_title event_1_type event_1_date_begin
                  event_1_agent_1_record_id event_1_agent_1_role]
        csv << ['do-event-import', 'Imported DO', 'cataloged', '1999-03-03', agent.uri, 'implementer']
      end)
      converter = Converter.for('digital_object_csv', csv_file, {})
      converter.run

      created = File.open(converter.get_output_path, 'r') do |fh|
        batch = StreamingImport.new(fh, Ticker.new(Job.new))
        batch.process
        batch.created_records.values
      end
      digital_object_uri = created.find { |uri| uri.include?('/digital_objects/') }
      agent_events = Event.find_relationship(:linked_agents).who_participates_with(AgentPerson[agent.id])

      aggregate_failures do
        expect(digital_object_uri).not_to be_nil
        expect(agent_events.length).to eq(1)
        event = Event.to_jsonmodel(agent_events.first)
        expect(event['event_type']).to eq('cataloged')
        expect(event['linked_agents'].map { |link| [link['role'], link['ref']] }).to eq([['implementer', agent.uri]])
        expect(event['linked_records'].map { |link| [link['role'], link['ref']] }).to eq([['source', digital_object_uri]])
      end
    end
  end
end
