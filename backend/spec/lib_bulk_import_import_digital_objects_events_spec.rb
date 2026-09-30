require "spec_helper"
require_relative "../app/lib/bulk_import/import_digital_objects.rb"
require_relative "lib_bulk_import_import_digital_objects_shared_context"

describe "Import Digital Objects" do
  include_context "digital object importer harness"

  TEMPLATES_DIR = File.join(File.dirname(__FILE__), "../", "../", "frontend", "public", "bulk_import_templates")

  def event_event_type_values
    enumeration = Enumeration.find(:name => "event_event_type")
    Enumeration.to_jsonmodel(enumeration)["values"]
  end

  def event_outcome_values
    enumeration = Enumeration.find(:name => "event_outcome")
    Enumeration.to_jsonmodel(enumeration)["values"]
  end

  def unknown_event_type_sheet
    csv_data = CSV.read(File.join(TEMPLATES_DIR, "bulk_import_DO_template.csv"))
    columns = csv_data[0].dup
    column_explanations = csv_data[1].dup
    group_3_headers = family_headers_at(columns, "event", 3)
    columns += group_3_headers
    column_explanations += group_3_headers.map { "Event(3)" }

    unknown_type = "anw-2999-#{SecureRandom.uuid}"
    title = "Digital Object Title #{@now} #{unknown_type}"
    row = {}
    columns.each { |column| row[column] = nil }
    row["res_uri"] = @resource.uri
    row["ao_uri"] = @archival_object.uri
    row["digital_object_title"] = title
    row["event_1_type"] = "cataloged"
    row["event_1_date"] = "1999-03-03"
    row["event_3_type"] = unknown_type
    row["event_3_date"] = "2001-04-05"

    {
      :columns => columns,
      :column_explanations => column_explanations,
      :row => row,
      :unknown_type => unknown_type,
      :title => title,
      :field_code => "event_3_type",
      :group => 3,
    }
  end

  def unknown_event_outcome_sheet
    csv_data = CSV.read(File.join(TEMPLATES_DIR, "bulk_import_DO_template.csv"))
    columns = csv_data[0].dup
    column_explanations = csv_data[1].dup
    group_3_headers = family_headers_at(columns, "event", 3)
    columns += group_3_headers
    column_explanations += group_3_headers.map { "Event(3)" }

    unknown_outcome = "anw-2999-outcome-#{SecureRandom.uuid}"
    title = "Digital Object Title #{@now} #{unknown_outcome}"
    row = {}
    columns.each { |column| row[column] = nil }
    row["res_uri"] = @resource.uri
    row["ao_uri"] = @archival_object.uri
    row["digital_object_title"] = title
    row["event_1_type"] = "cataloged"
    row["event_1_date"] = "1999-03-03"
    row["event_3_type"] = "processed"
    row["event_3_date"] = "2001-04-05"
    row["event_3_outcome"] = unknown_outcome
    row["event_3_outcome_note"] = "should not persist"

    {
      :columns => columns,
      :column_explanations => column_explanations,
      :row => row,
      :unknown_outcome => unknown_outcome,
      :title => title,
      :field_code => "event_3_outcome",
      :group => 3,
    }
  end

  it 'creates cataloged and processed events for noncontiguous groups on the linked digital object' do
    csv_data = CSV.read(File.join(TEMPLATES_DIR, 'bulk_import_DO_template.csv'))
    expect(csv_data.count).to eq(2)

    columns = csv_data[0]
    column_explanations = csv_data[1]
    expect(columns).to include('event_1_type', 'event_1_date')
    expect(column_explanations.length).to eq(columns.length)

    group_3_headers = family_headers_at(columns, 'event', 3)
    expect(group_3_headers).to eq([
      'event_3_type',
      'event_3_date',
      'event_3_date_label',
      'event_3_outcome',
      'event_3_outcome_note',
      'event_3_agent_1_record_id',
      'event_3_agent_1_agent_type',
      'event_3_agent_1_role',
    ])
    columns += group_3_headers
    column_explanations += group_3_headers.map { 'Event(3)' }
    expect(columns).not_to include('event_2_type', 'event_2_date')

    digital_object_row = {}
    columns.each { |column| digital_object_row[column] = nil }
    digital_object_row['res_uri'] = @resource.uri
    digital_object_row['ao_uri'] = @archival_object.uri
    digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"
    digital_object_row['event_1_type'] = 'cataloged'
    digital_object_row['event_1_date'] = '1999-03-03'
    digital_object_row['event_3_type'] = 'processed'
    digital_object_row['event_3_date'] = '2001-04-05'

    events_before = Event.count
    report = import_digital_object_csv(columns, column_explanations, digital_object_row)

    expect(report.terminal_error).to eq(nil)
    expect(report.row_count).to eq(1)
    expect(report.rows[0].errors).to eq([])
    cataloged_success = I18n.t('bulk_import.event_created', :group => 1, :type => 'cataloged')
    processed_success = I18n.t('bulk_import.event_created', :group => 3, :type => 'processed')
    expect(cataloged_success).to include('1', 'cataloged')
    expect(processed_success).to include('3', 'processed')
    expect(cataloged_success).not_to include('translation missing')
    expect(processed_success).not_to include('translation missing')
    expect(report.rows[0].info).to include(cataloged_success, processed_success)
    expect(Event.count).to eq(events_before + 2)

    digital_objects_created = DigitalObject.where(:title => "Digital Object Title #{@now}").all
    expect(digital_objects_created.count).to eq(1)

    digital_object = JSONModel(:digital_object).find(digital_objects_created[0].id)
    expect(digital_object['linked_events'].length).to eq(2)

    events = digital_object['linked_events'].map { |link| JSONModel(:event).find_by_uri(link['ref']) }
    cataloged = events.find { |event| event['event_type'] == 'cataloged' }
    processed = events.find { |event| event['event_type'] == 'processed' }
    expect(cataloged['date']).to include(
      'label' => 'other',
      'date_type' => 'single',
      'begin' => '1999-03-03'
    )
    expect(processed['date']).to include(
      'label' => 'other',
      'date_type' => 'single',
      'begin' => '2001-04-05'
    )
    [cataloged, processed].each do |event|
      expect(event['outcome']).to be_nil
      expect(event['outcome_note']).to be_nil
      expect(event['linked_records'].map { |link| [link['role'], link['ref']] }).to eq([
        ['source', digital_object.uri],
      ])
      expect(event['linked_agents'].map { |link| [link['role'], link['ref']] }).to eq([
        ['executing_program', AgentSoftware.archivesspace_record.uri],
      ])
    end
  end

  it 'persists a known Event outcome and maximum-length outcome note on the linked digital object' do
    csv_data = CSV.read(File.join(TEMPLATES_DIR, 'bulk_import_DO_template.csv'))
    expect(csv_data.count).to eq(2)

    columns = csv_data[0]
    column_explanations = csv_data[1]
    expect(column_explanations.length).to eq(columns.length)
    expect(family_headers_at(columns, 'event', 1)).to eq([
      'event_1_type',
      'event_1_date',
      'event_1_date_label',
      'event_1_outcome',
      'event_1_outcome_note',
      'event_1_agent_1_record_id',
      'event_1_agent_1_agent_type',
      'event_1_agent_1_role',
    ])

    outcome = 'pass'
    outcome_note = 'n' * 16_384
    title = "Digital Object Title #{@now} outcome"

    digital_object_row = {}
    columns.each { |column| digital_object_row[column] = nil }
    digital_object_row['res_uri'] = @resource.uri
    digital_object_row['ao_uri'] = @archival_object.uri
    digital_object_row['digital_object_title'] = title
    digital_object_row['event_1_type'] = 'cataloged'
    digital_object_row['event_1_date'] = '1999-03-03'
    digital_object_row['event_1_outcome'] = outcome
    digital_object_row['event_1_outcome_note'] = outcome_note

    report = import_digital_object_csv(columns, column_explanations, digital_object_row)

    expect(report.terminal_error).to eq(nil)
    expect(report.row_count).to eq(1)
    expect(report.rows[0].errors).to eq([])
    created = I18n.t('bulk_import.event_created', :group => 1, :type => 'cataloged')
    expect(created).not_to include('translation missing')
    expect(report.rows[0].info).to include(created)

    digital_objects_created = DigitalObject.where(:title => title).all
    expect(digital_objects_created.count).to eq(1)

    digital_object = JSONModel(:digital_object).find(digital_objects_created[0].id)
    expect(digital_object['linked_events'].length).to eq(1)

    event = JSONModel(:event).find_by_uri(digital_object['linked_events'][0]['ref'])
    expect(event['event_type']).to eq('cataloged')
    expect(event['outcome']).to eq(outcome)
    expect(event['outcome_note']).to eq(outcome_note)
    expect(event['outcome_note'].length).to eq(16_384)
  end

  it 'persists an Event outcome note when outcome is omitted' do
    csv_data = CSV.read(File.join(TEMPLATES_DIR, 'bulk_import_DO_template.csv'))
    columns = csv_data[0]
    column_explanations = csv_data[1]
    outcome_note = 'Kept without an outcome'
    title = "Digital Object Title #{@now} outcome note only"

    digital_object_row = {}
    columns.each { |column| digital_object_row[column] = nil }
    digital_object_row['res_uri'] = @resource.uri
    digital_object_row['ao_uri'] = @archival_object.uri
    digital_object_row['digital_object_title'] = title
    digital_object_row['event_1_type'] = 'cataloged'
    digital_object_row['event_1_date'] = '1999-03-03'
    digital_object_row['event_1_outcome_note'] = outcome_note

    report = import_digital_object_csv(columns, column_explanations, digital_object_row)

    expect(report.terminal_error).to eq(nil)
    expect(report.rows[0].errors).to eq([])
    created = I18n.t('bulk_import.event_created', :group => 1, :type => 'cataloged')
    expect(report.rows[0].info).to include(created)

    digital_object = JSONModel(:digital_object).find(DigitalObject.where(:title => title).first.id)
    event = JSONModel(:event).find_by_uri(digital_object['linked_events'][0]['ref'])
    expect(event['outcome']).to be_nil
    expect(event['outcome_note']).to eq(outcome_note)
  end

  it 'creates higher noncontiguous Events in numeric group order and skips a blank Event group' do
    csv_data = CSV.read(File.join(TEMPLATES_DIR, 'bulk_import_DO_template.csv'))
    columns = csv_data[0].dup
    column_explanations = csv_data[1].dup
    [10, 4, 2].each do |index|
      headers = family_headers_at(csv_data[0], 'event', index)
      columns += headers
      column_explanations += headers.map { "Event(#{index})" }
    end

    title = "Digital Object Title #{@now} ordered events"
    digital_object_row = {}
    columns.each { |column| digital_object_row[column] = nil }
    digital_object_row['res_uri'] = @resource.uri
    digital_object_row['ao_uri'] = @archival_object.uri
    digital_object_row['digital_object_title'] = title
    digital_object_row['event_2_type'] = 'cataloged'
    digital_object_row['event_2_date'] = '1999-03-03'
    digital_object_row['event_10_type'] = 'processed'
    digital_object_row['event_10_date'] = '2010-10-10'

    events_before = Event.count
    report = import_digital_object_csv(columns, column_explanations, digital_object_row)

    group_2_success = I18n.t('bulk_import.event_created', :group => 2, :type => 'cataloged')
    group_10_success = I18n.t('bulk_import.event_created', :group => 10, :type => 'processed')
    info = report.rows[0].info

    expect(report.terminal_error).to eq(nil)
    expect(report.rows[0].errors).to eq([])
    expect(group_2_success).not_to include('translation missing')
    expect(group_10_success).not_to include('translation missing')
    expect(info.index(group_2_success)).to be < info.index(group_10_success)
    expect(info.join("\n")).not_to match(/\bgroup 4\b/)
    expect(Event.count).to eq(events_before + 2)

    digital_object = JSONModel(:digital_object).find(DigitalObject.where(:title => title).first.id)
    expect(digital_object['linked_events'].length).to eq(2)
    event_types = digital_object['linked_events'].map { |link|
      JSONModel(:event).find_by_uri(link['ref'])['event_type']
    }
    expect(event_types).to contain_exactly('cataloged', 'processed')
  end

  it 'rejects a later Event group that has optional values but no type before the digital object or any Event is saved' do
    csv_data = CSV.read(File.join(TEMPLATES_DIR, 'bulk_import_DO_template.csv'))
    columns = csv_data[0].dup
    column_explanations = csv_data[1].dup
    group_3_headers = family_headers_at(columns, 'event', 3)
    columns += group_3_headers
    column_explanations += group_3_headers.map { 'Event(3)' }

    title = "Digital Object Title #{@now} partial event"
    row = {}
    columns.each { |column| row[column] = nil }
    row['res_uri'] = @resource.uri
    row['ao_uri'] = @archival_object.uri
    row['digital_object_title'] = title
    row['event_1_type'] = 'cataloged'
    row['event_1_date'] = '1999-03-03'
    row['event_3_date'] = '2001-04-05'
    row['event_3_outcome'] = 'pass'
    row['event_3_outcome_note'] = 'partial group'

    events_before = Event.count
    report = import_digital_object_csv(columns, column_explanations, row)
    row_report = report.rows.first
    errors = row_report ? row_report.errors : []
    info = row_report ? row_report.info : []
    missing_type_errors = errors.select { |error|
      error.to_s.include?('event_3_type') && error.to_s.match?(/\bgroup 3\b/)
    }
    missing_type_error = missing_type_errors.first.to_s

    aggregate_failures do
      expect(report.terminal_error).to be_nil
      expect(missing_type_errors.length).to eq(1), errors.inspect
      expect(missing_type_error).to include('event_3_type'), missing_type_error.inspect
      expect(missing_type_error).to match(/\bgroup 3\b/), missing_type_error.inspect
      expect(missing_type_error).not_to include('translation missing'), missing_type_error.inspect
      expect(info).not_to include(
        I18n.t('bulk_import.event_created', :group => 1, :type => 'cataloged')
      )
      expect(info).not_to include(
        I18n.t('bulk_import.event_created', :group => 3, :type => nil)
      )
      expect(DigitalObject.where(:title => title).count).to eq(0)
      expect(Event.count).to eq(events_before)
    end
  end

  it 'attributes a missing Event type to the canonical field when that column is omitted' do
    csv_data = CSV.read(File.join(TEMPLATES_DIR, 'bulk_import_DO_template.csv'))
    columns = csv_data[0].dup
    column_explanations = csv_data[1].dup
    group_3_headers = family_headers_at(columns, 'event', 3).reject { |header| header == 'event_3_type' }
    columns += group_3_headers
    column_explanations += group_3_headers.map { 'Event(3)' }

    title = "Digital Object Title #{@now} omitted event type"
    row = {}
    columns.each { |column| row[column] = nil }
    row['res_uri'] = @resource.uri
    row['ao_uri'] = @archival_object.uri
    row['digital_object_title'] = title
    row['event_1_type'] = 'cataloged'
    row['event_1_date'] = '1999-03-03'
    row['event_3_date'] = '2001-04-05'

    events_before = Event.count
    report = import_digital_object_csv(columns, column_explanations, row)
    row_report = report.rows.first
    errors = row_report ? row_report.errors : []
    info = row_report ? row_report.info : []
    missing_type_errors = errors.select { |error|
      error.to_s.include?('event_3_type') && error.to_s.match?(/\bgroup 3\b/)
    }
    missing_type_error = missing_type_errors.first.to_s

    aggregate_failures do
      expect(columns).not_to include('event_3_type')
      expect(columns).to include('event_3_date')
      expect(report.terminal_error).to be_nil
      expect(missing_type_errors.length).to eq(1), errors.inspect
      expect(missing_type_error).to include('event_3_type'), missing_type_error.inspect
      expect(missing_type_error).to match(/\bgroup 3\b/), missing_type_error.inspect
      expect(missing_type_error).not_to include('translation missing'), missing_type_error.inspect
      expect(info).not_to include(
        I18n.t('bulk_import.event_created', :group => 1, :type => 'cataloged')
      )
      expect(DigitalObject.where(:title => title).count).to eq(0)
      expect(Event.count).to eq(events_before)
    end
  end

  it 'attributes an over-limit Event outcome note to that group and keeps the digital object, archival object link, and valid Events' do
    csv_data = CSV.read(File.join(TEMPLATES_DIR, 'bulk_import_DO_template.csv'))
    columns = csv_data[0].dup
    column_explanations = csv_data[1].dup
    [3, 10].each do |index|
      headers = family_headers_at(csv_data[0], 'event', index)
      columns += headers
      column_explanations += headers.map { "Event(#{index})" }
    end

    title = "Digital Object Title #{@now} event failure isolation"
    row = {}
    columns.each { |column| row[column] = nil }
    row['res_uri'] = @resource.uri
    row['ao_uri'] = @archival_object.uri
    row['digital_object_title'] = title
    row['event_1_type'] = 'cataloged'
    row['event_1_date'] = '1999-03-03'
    row['event_1_outcome'] = 'pass'
    row['event_1_outcome_note'] = 'Kept sibling'
    row['event_3_type'] = 'processed'
    row['event_3_date'] = '2001-04-05'
    row['event_3_outcome'] = 'pass'
    row['event_3_outcome_note'] = 'n' * 16_385
    row['event_10_type'] = 'capture'
    row['event_10_date'] = '2010-10-10'
    row['event_10_outcome'] = 'fail'
    row['event_10_outcome_note'] = 'Kept later group'

    events_before = Event.count
    report = import_digital_object_csv(columns, column_explanations, row)
    row_report = report.rows.first
    errors = row_report ? row_report.errors : []
    info = row_report ? row_report.info : []
    reported_error = errors.first.to_s
    attributed_failure = I18n.t(
      'bulk_import.error.event_validation',
      :group => 3,
      :type => 'processed',
      :err => ''
    ).strip
    sibling_created = I18n.t('bulk_import.event_created', :group => 1, :type => 'cataloged')
    failed_created = I18n.t('bulk_import.event_created', :group => 3, :type => 'processed')
    later_created = I18n.t('bulk_import.event_created', :group => 10, :type => 'capture')
    digital_objects = DigitalObject.where(:title => title).all
    digital_object = digital_objects.empty? ? nil : JSONModel(:digital_object).find(digital_objects[0].id)
    archival_object = JSONModel(:archival_object).find(@archival_object.id)
    events = if digital_object
               digital_object['linked_events'].map { |link| JSONModel(:event).find_by_uri(link['ref']) }
             else
               []
             end
    instance_links = archival_object.instances.map { |instance|
      digital_object_ref = instance['digital_object'] ? instance['digital_object']['ref'] : nil
      [instance['instance_type'], digital_object_ref]
    }

    aggregate_failures do
      expect(report.terminal_error).to be_nil
      expect(errors.length).to eq(1)
      expect(reported_error).to start_with(attributed_failure)
      expect(reported_error).not_to include('translation missing')
      expect(info).to include(sibling_created, later_created)
      expect(info).not_to include(failed_created)
      expect(digital_objects.count).to eq(1)
      expect(instance_links).to eq([['digital_object', digital_object && digital_object.uri]])
      expect(Event.count).to eq(events_before + 2)
      expect(events.map { |event| event['event_type'] }).to contain_exactly('cataloged', 'capture')
    end
  end

  context "unknown Event types" do
    def import_unknown_event_type(validate_only:)
      sheet = unknown_event_type_sheet
      values_before = event_event_type_values
      expect(values_before).to include("cataloged")
      expect(values_before).not_to include(sheet[:unknown_type])

      events_before = Event.count
      report = RequestContext.open(:create_enums => true) do
        import_digital_object_csv(
          sheet[:columns],
          sheet[:column_explanations],
          sheet[:row],
          validate_only: validate_only
        )
      end

      {
        :sheet => sheet,
        :enumeration_values_before => values_before,
        :events_before => events_before,
        :report => report,
      }
    end

    def expect_unknown_event_type_rejected(result)
      sheet = result[:sheet]
      values_before = result[:enumeration_values_before]
      events_before = result[:events_before]
      report = result[:report]
      row_report = report.rows.first
      errors = row_report ? row_report.errors : []
      info = row_report ? row_report.info : []
      event_type_errors = errors.select { |error|
        error.to_s.include?(sheet[:field_code]) && error.to_s.include?(sheet[:unknown_type])
      }
      event_type_error = event_type_errors.first.to_s
      values_after = event_event_type_values

      aggregate_failures do
        expect(report.terminal_error).to be_nil
        expect(event_type_errors.length).to eq(1)
        expect(event_type_error).to include(sheet[:field_code]), event_type_error.inspect
        expect(event_type_error).to match(/\bgroup 3\b/), event_type_error.inspect
        expect(event_type_error).to include(sheet[:unknown_type]), event_type_error.inspect
        expect(event_type_error).not_to include("translation missing")
        expect(info).not_to include(
          I18n.t("bulk_import.event_created", :group => 1, :type => "cataloged")
        )
        expect(info).not_to include(
          I18n.t("bulk_import.event_created", :group => sheet[:group], :type => sheet[:unknown_type])
        )
        expect(DigitalObject.where(:title => sheet[:title]).count).to eq(0)
        expect(Event.count).to eq(events_before)
        expect(values_after).to eq(values_before)
        expect(values_after).not_to include(sheet[:unknown_type])
      end
    end

    it "rejects an unknown later Event type before saving the digital object or changing event types" do
      expect_unknown_event_type_rejected(import_unknown_event_type(validate_only: false))
    end

    it "reports an unknown Event type during validate-only without saving records or event types" do
      expect_unknown_event_type_rejected(import_unknown_event_type(validate_only: true))
    end
  end

  context "unknown Event outcomes" do
    def import_unknown_event_outcome(validate_only:)
      sheet = unknown_event_outcome_sheet
      values_before = event_outcome_values
      expect(values_before).to include("pass")
      expect(values_before).not_to include(sheet[:unknown_outcome])

      events_before = Event.count
      report = RequestContext.open(:create_enums => true) do
        import_digital_object_csv(
          sheet[:columns],
          sheet[:column_explanations],
          sheet[:row],
          validate_only: validate_only
        )
      end

      {
        :sheet => sheet,
        :enumeration_values_before => values_before,
        :events_before => events_before,
        :report => report,
      }
    end

    def expect_unknown_event_outcome_rejected(result)
      sheet = result[:sheet]
      values_before = result[:enumeration_values_before]
      events_before = result[:events_before]
      report = result[:report]
      row_report = report.rows.first
      errors = row_report ? row_report.errors : []
      info = row_report ? row_report.info : []
      outcome_errors = errors.select { |error|
        error.to_s.include?(sheet[:field_code]) && error.to_s.include?(sheet[:unknown_outcome])
      }
      outcome_error = outcome_errors.first.to_s
      values_after = event_outcome_values

      aggregate_failures do
        expect(report.terminal_error).to be_nil
        expect(outcome_errors.length).to eq(1)
        expect(outcome_error).to include(sheet[:field_code]), outcome_error.inspect
        expect(outcome_error).to match(/\bgroup 3\b/), outcome_error.inspect
        expect(outcome_error).to include(sheet[:unknown_outcome]), outcome_error.inspect
        expect(outcome_error).not_to include("translation missing")
        expect(info).not_to include(
          I18n.t("bulk_import.event_created", :group => 1, :type => "cataloged")
        )
        expect(info).not_to include(
          I18n.t("bulk_import.event_created", :group => sheet[:group], :type => "processed")
        )
        expect(DigitalObject.where(:title => sheet[:title]).count).to eq(0)
        expect(Event.count).to eq(events_before)
        expect(values_after).to eq(values_before)
        expect(values_after).not_to include(sheet[:unknown_outcome])
      end
    end

    it "rejects an unknown later Event outcome before saving the digital object or changing outcomes" do
      expect_unknown_event_outcome_rejected(import_unknown_event_outcome(validate_only: false))
    end

    it "reports an unknown Event outcome during validate-only without saving records or outcomes" do
      expect_unknown_event_outcome_rejected(import_unknown_event_outcome(validate_only: true))
    end
  end

  context "Event dates and date labels" do
    def date_label_values
      enumeration = Enumeration.find(:name => "date_label")
      Enumeration.to_jsonmodel(enumeration)["values"]
    end

    def date_label_record_count
      enumeration = Enumeration.find(:name => "date_label")
      EnumerationValue.where(:enumeration_id => enumeration.id).count
    end

    def import_event_sheet(cells, title:, extra_indices: [], validate_only: false, create_enums: false)
      csv_data = CSV.read(File.join(TEMPLATES_DIR, "bulk_import_DO_template.csv"))
      columns = csv_data[0].dup
      explanations = csv_data[1].dup
      extra_indices.each do |index|
        headers = family_headers_at(columns, "event", index)
        columns += headers
        explanations += headers.map { "Event(#{index})" }
      end

      row = {}
      columns.each { |column| row[column] = nil }
      row["res_uri"] = @resource.uri
      row["ao_uri"] = @archival_object.uri
      row["digital_object_title"] = title
      cells.each { |key, value| row[key] = value }

      events_before = Event.count
      report = if create_enums
                 RequestContext.open(:create_enums => true) do
                   import_digital_object_csv(columns, explanations, row, validate_only: validate_only)
                 end
               else
                 import_digital_object_csv(columns, explanations, row, validate_only: validate_only)
               end

      {
        :title => title,
        :report => report,
        :events_before => events_before,
      }
    end

    def import_event_rows(row_specs)
      csv_data = CSV.read(File.join(TEMPLATES_DIR, "bulk_import_DO_template.csv"))
      columns = csv_data[0].dup
      explanations = csv_data[1].dup
      data_rows = row_specs.map do |spec|
        row = {}
        columns.each { |column| row[column] = nil }
        row["res_uri"] = @resource.uri
        row["ao_uri"] = @archival_object.uri
        row["digital_object_title"] = spec.fetch(:title)
        spec.fetch(:cells).each { |key, value| row[key] = value }
        row
      end

      csv_string = CSV.generate(col_sep: ",") do |csv|
        csv << columns
        csv << explanations
        data_rows.each { |row| csv << row.values }
      end
      csv_filename = "bulk_import_DO_template_#{@now}_#{SecureRandom.uuid}.csv"
      csv_path = File.join(Dir.tmpdir, csv_filename)
      File.write(csv_path, csv_string)
      opts = {
        :repo_id => @resource[:repo_id],
        :rid => @resource[:id],
        :type => "resource",
        :filename => csv_filename,
        :filepath => csv_path,
        :load_type => "digital_object",
        :validate => false,
      }
      events_before = Event.count
      report = ImportDigitalObjects.new(opts[:filepath], "csv", @current_user, opts).run
      {
        :report => report,
        :events_before => events_before,
      }
    end

    def row_messages(report)
      row_report = report.rows.first
      {
        :errors => row_report ? row_report.errors : [],
        :info => row_report ? row_report.info : [],
      }
    end

    def digital_object_for(title)
      records = DigitalObject.where(:title => title).all
      return nil if records.empty?

      JSONModel(:digital_object).find(records[0].id)
    end

    def events_for(digital_object)
      return [] unless digital_object

      digital_object["linked_events"].map { |link| JSONModel(:event).find_by_uri(link["ref"]) }
    end

    def expect_single_date(date, begin_value:, label:)
      expect(date).not_to be_nil
      return if date.nil?

      expect(date["begin"]).to eq(begin_value)
      expect(date["date_type"]).to eq("single")
      expect(date["label"]).to eq(label)
      expect(date["expression"]).to be_nil
      expect(date["end"]).to be_nil
    end

    def with_suppressed_date_label(stored_value)
      enumeration = Enumeration.find(:name => "date_label")
      enum_value = nil
      enum_value = EnumerationValue.find(:enumeration_id => enumeration.id, :value => stored_value)
      enum_value.suppressed = 1
      enum_value.save
      yield
    ensure
      if enum_value
        enum_value.suppressed = 0
        enum_value.save
      end
    end

    def expect_invalid_event_date(supplied_date, validate_only:)
      title = "Digital Object Title #{@now} invalid date #{supplied_date} #{validate_only}"
      result = import_event_sheet(
        {
          "event_1_type" => "cataloged",
          "event_1_date" => supplied_date,
        },
        :title => title,
        :validate_only => validate_only
      )
      messages = row_messages(result[:report])
      date_errors = messages[:errors].select { |error|
        text = error.to_s
        text.include?("event_1_date") && !text.include?("event_1_date_label") && text.include?(supplied_date)
      }
      date_error = date_errors.first.to_s
      unrelated_errors = messages[:errors].reject { |error| error.to_s.include?("event_") }

      aggregate_failures do
        expect(result[:report].terminal_error).to be_nil
        expect(date_errors.length).to eq(1), messages[:errors].inspect
        expect(date_error).to match(/\bgroup 1\b/), date_error.inspect
        expect(date_error).to include("event_1_date"), date_error.inspect
        expect(date_error).to include(supplied_date), date_error.inspect
        expect(date_error).not_to include("translation missing"), date_error.inspect
        expect(messages[:info]).not_to include(
          I18n.t("bulk_import.event_created", :group => 1, :type => "cataloged")
        )
        expect(DigitalObject.where(:title => title).count).to eq(0)
        expect(Event.count).to eq(result[:events_before])
        if validate_only
          expect(messages[:info]).not_to include(
            I18n.t("bulk_import.could_be", :what => I18n.t("bulk_import.dig"))
          )
          expect(unrelated_errors.map(&:to_s)).to eq([
            I18n.t("bulk_import.object_not_created_be", :what => I18n.t("bulk_import.dig")),
          ]), messages[:errors].inspect
        else
          expect(messages[:info].join("\n")).not_to include(
            I18n.t("bulk_import.created", :what => I18n.t("bulk_import.dig"), :id => "").rstrip
          )
          expect(unrelated_errors).to eq([]), messages[:errors].inspect
        end
      end
    end

    it "persists a year-precision Event date as a single begin value and defaults a blank label to other" do
      title = "Digital Object Title #{@now} year event date"
      result = import_event_sheet(
        {
          "event_1_type" => "cataloged",
          "event_1_date" => "1999",
        },
        :title => title
      )
      messages = row_messages(result[:report])
      event = events_for(digital_object_for(title)).find { |item| item["event_type"] == "cataloged" }

      aggregate_failures do
        expect(result[:report].terminal_error).to be_nil
        expect(messages[:errors]).to eq([])
        expect(messages[:info]).to include(
          I18n.t("bulk_import.event_created", :group => 1, :type => "cataloged")
        )
        expect(DigitalObject.where(:title => title).count).to eq(1)
        expect(Event.count).to eq(result[:events_before] + 1)
        expect_single_date(event && event["date"], :begin_value => "1999", :label => "other")
      end
    end

    it "persists a year-month Event date as a single begin value and defaults a blank label to other" do
      title = "Digital Object Title #{@now} year month event date"
      result = import_event_sheet(
        {
          "event_1_type" => "cataloged",
          "event_1_date" => "1999-03",
        },
        :title => title
      )
      messages = row_messages(result[:report])
      event = events_for(digital_object_for(title)).find { |item| item["event_type"] == "cataloged" }

      aggregate_failures do
        expect(result[:report].terminal_error).to be_nil
        expect(messages[:errors]).to eq([])
        expect(DigitalObject.where(:title => title).count).to eq(1)
        expect_single_date(event && event["date"], :begin_value => "1999-03", :label => "other")
      end
    end

    it "trims a whitespace-padded Event date and keeps that precision in begin" do
      title = "Digital Object Title #{@now} trimmed event date"
      result = import_event_sheet(
        {
          "event_1_type" => "cataloged",
          "event_1_date" => "  1999-03-03  ",
        },
        :title => title
      )
      event = events_for(digital_object_for(title)).find { |item| item["event_type"] == "cataloged" }

      aggregate_failures do
        expect(result[:report].terminal_error).to be_nil
        expect(row_messages(result[:report])[:errors]).to eq([])
        expect_single_date(event && event["date"], :begin_value => "1999-03-03", :label => "other")
      end
    end

    it "persists a supplied stored Date Label as that controlled value" do
      title = "Digital Object Title #{@now} stored date label"
      result = import_event_sheet(
        {
          "event_1_type" => "cataloged",
          "event_1_date" => "2012-08-09",
          "event_1_date_label" => "creation",
        },
        :title => title
      )
      messages = row_messages(result[:report])
      event = events_for(digital_object_for(title)).find { |item| item["event_type"] == "cataloged" }

      aggregate_failures do
        expect(result[:report].terminal_error).to be_nil, result[:report].terminal_error.inspect
        expect(messages[:errors]).to eq([])
        expect(DigitalObject.where(:title => title).count).to eq(1)
        expect_single_date(event && event["date"], :begin_value => "2012-08-09", :label => "creation")
      end
    end

    it "accepts a translated Date Label on a noncontiguous Event group and stores the controlled value" do
      title = "Digital Object Title #{@now} translated date label"
      result = nil
      I18n.with_locale(:en) do
        result = import_event_sheet(
          {
            "event_4_type" => "processed",
            "event_4_date" => "1988",
            "event_4_date_label" => "Creation",
          },
          :title => title,
          :extra_indices => [4]
        )
      end
      messages = row_messages(result[:report])
      event = events_for(digital_object_for(title)).find { |item| item["event_type"] == "processed" }

      aggregate_failures do
        expect(result[:report].terminal_error).to be_nil, result[:report].terminal_error.inspect
        expect(messages[:errors]).to eq([])
        expect(messages[:info]).to include(
          I18n.t("bulk_import.event_created", :group => 4, :type => "processed")
        )
        expect(DigitalObject.where(:title => title).count).to eq(1)
        expect_single_date(event && event["date"], :begin_value => "1988", :label => "creation")
      end
    end

    it "treats a whitespace-only Date Label as blank and defaults it to other" do
      title = "Digital Object Title #{@now} blank date label"
      result = import_event_sheet(
        {
          "event_1_type" => "cataloged",
          "event_1_date" => "1999-03",
          "event_1_date_label" => "   ",
        },
        :title => title
      )
      event = events_for(digital_object_for(title)).find { |item| item["event_type"] == "cataloged" }

      aggregate_failures do
        expect(result[:report].terminal_error).to be_nil, result[:report].terminal_error.inspect
        expect(row_messages(result[:report])[:errors]).to eq([])
        expect_single_date(event && event["date"], :begin_value => "1999-03", :label => "other")
      end
    end

    it "saves the digital object when an Event type has no date, reports that Event validation failure, and imports the next row" do
      undated_title = "Digital Object Title #{@now} undated event row"
      dated_title = "Digital Object Title #{@now} dated event row"
      result = import_event_rows([
        {
          :title => undated_title,
          :cells => {
            "event_1_type" => "cataloged",
          },
        },
        {
          :title => dated_title,
          :cells => {
            "event_1_type" => "processed",
            "event_1_date" => "2001-04-05",
          },
        },
      ])
      report = result[:report]
      undated_row = report.rows[0]
      dated_row = report.rows[1]
      undated_errors = undated_row ? undated_row.errors.map(&:to_s) : []
      undated_info = undated_row ? undated_row.info : []
      dated_errors = dated_row ? dated_row.errors : []
      dated_info = dated_row ? dated_row.info : []
      missing_date = {
        "date" => ["Must specify either a date or a timestamp"],
        "timestamp" => ["Must specify either a date or a timestamp"],
      }
      expected_error = I18n.t(
        "bulk_import.error.event_validation",
        :group => 1,
        :type => "cataloged",
        :err => missing_date
      )
      failed_created = I18n.t("bulk_import.event_created", :group => 1, :type => "cataloged")
      dated_created = I18n.t("bulk_import.event_created", :group => 1, :type => "processed")
      undated_object = digital_object_for(undated_title)
      dated_object = digital_object_for(dated_title)
      dated_event = events_for(dated_object).find { |event| event["event_type"] == "processed" }
      archival_object = JSONModel(:archival_object).find(@archival_object.id)
      instance_links = archival_object.instances.map { |instance|
        digital_object_ref = instance["digital_object"] ? instance["digital_object"]["ref"] : nil
        [instance["instance_type"], digital_object_ref]
      }

      aggregate_failures do
        expect(report.terminal_error).to be_nil
        expect(report.row_count).to eq(2)
        expect(undated_errors).to eq([expected_error])
        expect(expected_error).to include("group 1")
        expect(expected_error).to include("cataloged")
        expect(expected_error).to include("Must specify either a date or a timestamp")
        expect(expected_error).not_to include("translation missing")
        expect(undated_info).to include(I18n.t("bulk_import.dig_assoc"))
        expect(undated_info).not_to include(failed_created)
        expect(DigitalObject.where(:title => undated_title).count).to eq(1)
        expect(instance_links).to include(["digital_object", undated_object && undated_object.uri])
        expect(undated_object && undated_object["linked_events"]).to eq([])
        expect(dated_errors).to eq([])
        expect(dated_info).to include(dated_created)
        expect(DigitalObject.where(:title => dated_title).count).to eq(1)
        expect(instance_links).to include(["digital_object", dated_object && dated_object.uri])
        expect_single_date(dated_event && dated_event["date"], :begin_value => "2001-04-05", :label => "other")
        expect(Event.count).to eq(result[:events_before] + 1)
      end
    end

    it "rejects a malformed Event date before saving the digital object or an Event" do
      expect_invalid_event_date("1999/03/03", :validate_only => false)
    end

    it "reports a malformed Event date during validate-only without saving a digital object or an Event" do
      expect_invalid_event_date("1999/03/03", :validate_only => true)
    end

    it "rejects an impossible Event calendar date before saving the digital object or an Event" do
      expect_invalid_event_date("1999-02-31", :validate_only => false)
    end

    it "reports an impossible Event calendar date during validate-only without saving a digital object or an Event" do
      expect_invalid_event_date("1999-02-31", :validate_only => true)
    end

    [
      ["1999-3", "an unpadded month"],
      ["1999-03-3", "an unpadded day"],
      ["1999-03-03T00:00:00", "a timestamp"],
    ].each do |supplied_date, shape|
      it "rejects Event date #{supplied_date}, #{shape}, before saving the digital object or an Event" do
        expect_invalid_event_date(supplied_date, :validate_only => false)
      end
    end

    it "continues to the next CSV row after an Event date error and persists only the valid row" do
      rejected_date = "1999/03/03"
      rejected_title = "Digital Object Title #{@now} rejected event date row"
      accepted_title = "Digital Object Title #{@now} accepted event date row"
      result = import_event_rows([
        {
          :title => rejected_title,
          :cells => {
            "event_1_type" => "cataloged",
            "event_1_date" => rejected_date,
          },
        },
        {
          :title => accepted_title,
          :cells => {
            "event_1_type" => "processed",
            "event_1_date" => "2001-04-05",
          },
        },
      ])
      report = result[:report]
      rejected_row = report.rows[0]
      accepted_row = report.rows[1]
      rejected_errors = rejected_row ? rejected_row.errors : []
      rejected_info = rejected_row ? rejected_row.info : []
      accepted_errors = accepted_row ? accepted_row.errors : []
      accepted_info = accepted_row ? accepted_row.info : []
      date_errors = rejected_errors.select { |error|
        text = error.to_s
        text.include?("event_1_date") && !text.include?("event_1_date_label") && text.include?(rejected_date)
      }
      date_error = date_errors.first.to_s
      accepted_object = digital_object_for(accepted_title)
      accepted_events = events_for(accepted_object)

      aggregate_failures do
        expect(report.terminal_error).to be_nil
        expect(report.row_count).to eq(2)
        expect(date_errors.length).to eq(1), rejected_errors.inspect
        expect(date_error).to match(/\bgroup 1\b/), date_error.inspect
        expect(date_error).to include("event_1_date"), date_error.inspect
        expect(date_error).to include(rejected_date), date_error.inspect
        expect(date_error).not_to include("translation missing"), date_error.inspect
        expect(rejected_info).not_to include(
          I18n.t("bulk_import.event_created", :group => 1, :type => "cataloged")
        )
        expect(DigitalObject.where(:title => rejected_title).count).to eq(0)
        expect(accepted_errors).to eq([])
        expect(accepted_info).to include(
          I18n.t("bulk_import.event_created", :group => 1, :type => "processed")
        )
        expect(DigitalObject.where(:title => accepted_title).count).to eq(1)
        expect(accepted_events.map { |event| event["event_type"] }).to eq(["processed"])
        expect(Event.count).to eq(result[:events_before] + 1)
      end
    end

    def expect_label_without_date(validate_only:)
      title = "Digital Object Title #{@now} label without date #{validate_only}"
      result = import_event_sheet(
        {
          "event_1_type" => "cataloged",
          "event_1_date" => "   ",
          "event_1_date_label" => "creation",
        },
        :title => title,
        :validate_only => validate_only
      )
      messages = row_messages(result[:report])
      label_errors = messages[:errors].select { |error|
        text = error.to_s
        text.include?("event_1_date_label") && text.include?("creation") && text.match?(/\bgroup 1\b/)
      }
      date_errors = messages[:errors].select { |error|
        text = error.to_s
        text.include?("event_1_date") && !text.include?("event_1_date_label")
      }
      label_error = label_errors.first.to_s

      aggregate_failures do
        expect(result[:report].terminal_error).to be_nil, result[:report].terminal_error.inspect
        expect(label_errors.length).to eq(1), messages[:errors].inspect
        expect(label_error).to include("event_1_date_label"), label_error.inspect
        expect(label_error).to include("creation"), label_error.inspect
        expect(label_error).to match(/\bgroup 1\b/), label_error.inspect
        expect(label_error).not_to include("translation missing"), label_error.inspect
        expect(date_errors).to eq([]), messages[:errors].inspect
        expect(messages[:info]).not_to include(
          I18n.t("bulk_import.event_created", :group => 1, :type => "cataloged")
        )
        expect(DigitalObject.where(:title => title).count).to eq(0)
        expect(Event.count).to eq(result[:events_before])
      end
    end

    it "rejects a Date Label without a date before saving the digital object or an Event" do
      expect_label_without_date(:validate_only => false)
    end

    it "reports a Date Label without a date during validate-only without saving a digital object or an Event" do
      expect_label_without_date(:validate_only => true)
    end

    it "recognizes an Event group when Date Label is its only populated field and reports missing type plus label without date" do
      title = "Digital Object Title #{@now} date label only"
      labels_before = date_label_values
      label_count_before = date_label_record_count
      expect(labels_before).to include("creation")

      result = import_event_sheet(
        {
          "event_1_date_label" => "creation",
        },
        :title => title,
        :create_enums => true
      )
      messages = row_messages(result[:report])
      errors = messages[:errors]
      type_errors = errors.select { |error|
        text = error.to_s
        text.include?("event_1_type") && text.match?(/\bgroup 1\b/)
      }
      label_errors = errors.select { |error|
        text = error.to_s
        text.include?("event_1_date_label") && text.include?("creation") && text.match?(/\bgroup 1\b/)
      }
      date_errors = errors.select { |error|
        text = error.to_s
        text.include?("event_1_date") && !text.include?("event_1_date_label")
      }
      type_error = type_errors.first.to_s
      label_error = label_errors.first.to_s

      aggregate_failures do
        expect(result[:report].terminal_error).to be_nil, result[:report].terminal_error.inspect
        expect(type_errors.length).to eq(1), errors.inspect
        expect(type_error).to include("event_1_type"), type_error.inspect
        expect(type_error).to match(/\bgroup 1\b/), type_error.inspect
        expect(type_error).not_to include("translation missing"), type_error.inspect
        expect(label_errors.length).to eq(1), errors.inspect
        expect(label_error).to include("event_1_date_label"), label_error.inspect
        expect(label_error).to include("creation"), label_error.inspect
        expect(label_error).to match(/\bgroup 1\b/), label_error.inspect
        expect(label_error).not_to include("translation missing"), label_error.inspect
        expect(date_errors).to eq([]), errors.inspect
        expect(errors.length).to eq(2), errors.inspect
        expect(messages[:info]).not_to include(
          I18n.t("bulk_import.event_created", :group => 1, :type => nil)
        )
        expect(DigitalObject.where(:title => title).count).to eq(0)
        expect(Event.count).to eq(result[:events_before])
        expect(date_label_values).to eq(labels_before)
        expect(date_label_record_count).to eq(label_count_before)
      end
    end

    def expect_unknown_date_label_rejected(validate_only:)
      unknown_label = "anw-2999-date-label-#{SecureRandom.uuid}"
      title = "Digital Object Title #{@now} #{unknown_label}"
      values_before = date_label_values
      count_before = date_label_record_count
      expect(values_before).to include("creation")
      expect(values_before).not_to include(unknown_label)

      result = import_event_sheet(
        {
          "event_1_type" => "cataloged",
          "event_1_date" => "1999-03-03",
          "event_1_date_label" => unknown_label,
        },
        :title => title,
        :validate_only => validate_only,
        :create_enums => true
      )
      messages = row_messages(result[:report])
      label_errors = messages[:errors].select { |error|
        text = error.to_s
        text.include?("event_1_date_label") && text.include?(unknown_label)
      }
      label_error = label_errors.first.to_s
      values_after = date_label_values

      aggregate_failures do
        expect(result[:report].terminal_error).to be_nil, result[:report].terminal_error.inspect
        expect(label_errors.length).to eq(1), messages[:errors].inspect
        expect(label_error).to include("event_1_date_label"), label_error.inspect
        expect(label_error).to match(/\bgroup 1\b/), label_error.inspect
        expect(label_error).to include(unknown_label), label_error.inspect
        expect(label_error).not_to include("translation missing"), label_error.inspect
        expect(messages[:info]).not_to include(
          I18n.t("bulk_import.event_created", :group => 1, :type => "cataloged")
        )
        expect(DigitalObject.where(:title => title).count).to eq(0)
        expect(Event.count).to eq(result[:events_before])
        expect(values_after).to eq(values_before)
        expect(values_after).not_to include(unknown_label)
        expect(date_label_record_count).to eq(count_before)
      end
    end

    it "rejects an unknown Date Label before saving the digital object or creating a controlled value" do
      expect_unknown_date_label_rejected(:validate_only => false)
    end

    it "reports an unknown Date Label during validate-only without saving records or creating a controlled value" do
      expect_unknown_date_label_rejected(:validate_only => true)
    end

    def expect_suppressed_date_label_rejected(validate_only:)
      title = "Digital Object Title #{@now} suppressed date label #{validate_only}"
      expect(date_label_values).to include("deaccession")
      captured = {}

      with_suppressed_date_label("deaccession") do
        captured[:during] = date_label_values
        captured[:count] = date_label_record_count
        captured[:result] = import_event_sheet(
          {
            "event_1_type" => "cataloged",
            "event_1_date" => "1999-03-03",
            "event_1_date_label" => "deaccession",
          },
          :title => title,
          :validate_only => validate_only,
          :create_enums => true
        )
        captured[:after] = date_label_values
        captured[:count_after] = date_label_record_count
      end

      result = captured[:result]
      messages = row_messages(result[:report])
      label_errors = messages[:errors].select { |error|
        text = error.to_s
        text.include?("event_1_date_label") && text.include?("deaccession")
      }
      label_error = label_errors.first.to_s

      aggregate_failures do
        expect(captured[:during]).not_to include("deaccession")
        expect(result[:report].terminal_error).to be_nil, result[:report].terminal_error.inspect
        expect(label_errors.length).to eq(1), messages[:errors].inspect
        expect(label_error).to include("event_1_date_label"), label_error.inspect
        expect(label_error).to match(/\bgroup 1\b/), label_error.inspect
        expect(label_error).to include("deaccession"), label_error.inspect
        expect(label_error).not_to include("translation missing"), label_error.inspect
        expect(messages[:info]).not_to include(
          I18n.t("bulk_import.event_created", :group => 1, :type => "cataloged")
        )
        expect(DigitalObject.where(:title => title).count).to eq(0)
        expect(Event.count).to eq(result[:events_before])
        expect(captured[:after]).to eq(captured[:during])
        expect(captured[:after]).not_to include("deaccession")
        expect(captured[:count_after]).to eq(captured[:count])
        expect(date_label_values).to include("deaccession")
      end
    end

    it "rejects a suppressed Date Label before saving the digital object or changing controlled values" do
      expect_suppressed_date_label_rejected(:validate_only => false)
    end

    it "reports a suppressed Date Label during validate-only without saving records or changing controlled values" do
      expect_suppressed_date_label_rejected(:validate_only => true)
    end

    def expect_independent_event_input_errors(validate_only:)
      bad_type = "not-a-real-event-type"
      bad_outcome = "not-a-real-outcome"
      malformed_date = "1999/03/03"
      impossible_date = "1999-02-31"
      title = "Digital Object Title #{@now} accumulated event errors #{validate_only}"
      types_before = event_event_type_values
      outcomes_before = event_outcome_values
      result = import_event_sheet(
        {
          "event_1_type" => bad_type,
          "event_1_date" => malformed_date,
          "event_1_outcome" => bad_outcome,
          "event_4_type" => "processed",
          "event_4_date" => impossible_date,
          "event_8_date" => "2010",
          "event_8_outcome" => "pass",
        },
        :title => title,
        :extra_indices => [2, 4, 8],
        :validate_only => validate_only,
        :create_enums => true
      )
      messages = row_messages(result[:report])
      errors = messages[:errors]
      event_errors = errors.select { |error| error.to_s.include?("event_") }

      type_1 = event_errors.select { |error|
        text = error.to_s
        text.include?("event_1_type") && text.include?(bad_type) && text.match?(/\bgroup 1\b/)
      }
      date_1 = event_errors.select { |error|
        text = error.to_s
        text.include?("event_1_date") && !text.include?("event_1_date_label") &&
          text.include?(malformed_date) && text.match?(/\bgroup 1\b/)
      }
      outcome_1 = event_errors.select { |error|
        text = error.to_s
        text.include?("event_1_outcome") && text.include?(bad_outcome) && text.match?(/\bgroup 1\b/)
      }
      date_4 = event_errors.select { |error|
        text = error.to_s
        text.include?("event_4_date") && text.include?(impossible_date) && text.match?(/\bgroup 4\b/)
      }
      type_8 = event_errors.select { |error|
        text = error.to_s
        text.include?("event_8_type") && text.match?(/\bgroup 8\b/)
      }
      unrelated_errors = errors.reject { |error| error.to_s.include?("event_") }

      aggregate_failures do
        expect(result[:report].terminal_error).to be_nil
        expect(type_1.length).to eq(1), errors.inspect
        expect(date_1.length).to eq(1), errors.inspect
        expect(outcome_1.length).to eq(1), errors.inspect
        expect(date_4.length).to eq(1), errors.inspect
        expect(type_8.length).to eq(1), errors.inspect
        expect(type_1.first.to_s).not_to include("translation missing")
        expect(date_1.first.to_s).not_to include("translation missing")
        expect(outcome_1.first.to_s).not_to include("translation missing")
        expect(date_4.first.to_s).not_to include("translation missing")
        expect(type_8.first.to_s).not_to include("translation missing")
        expect(event_errors.length).to eq(5), errors.inspect
        expect(errors.join("\n")).not_to match(/\bgroup 2\b/)
        expect(errors.join("\n")).not_to include("event_2_")
        expect(errors.join("\n")).not_to include("event_4_type")
        expect(errors.join("\n")).not_to include("event_4_outcome")
        expect(errors.join("\n")).not_to include("event_8_date")
        expect(errors.join("\n")).not_to include("event_8_outcome")
        expect(errors.join("\n")).not_to include("2010")
        expect(messages[:info]).not_to include(
          I18n.t("bulk_import.event_created", :group => 1, :type => bad_type)
        )
        expect(messages[:info]).not_to include(
          I18n.t("bulk_import.event_created", :group => 4, :type => "processed")
        )
        expect(DigitalObject.where(:title => title).count).to eq(0)
        expect(Event.count).to eq(result[:events_before])
        expect(event_event_type_values).to eq(types_before)
        expect(event_event_type_values).not_to include(bad_type)
        expect(event_outcome_values).to eq(outcomes_before)
        expect(event_outcome_values).not_to include(bad_outcome)
        if validate_only
          expect(unrelated_errors.map(&:to_s)).to eq([
            I18n.t("bulk_import.object_not_created_be", :what => I18n.t("bulk_import.dig")),
          ]), errors.inspect
        else
          expect(unrelated_errors).to eq([]), errors.inspect
        end
      end
    end

    it "reports every independent invalid Type, Date, and Outcome across Event groups before saving" do
      expect_independent_event_input_errors(:validate_only => false)
    end

    it "reports the same independent Event input errors during validate-only without saving records" do
      expect_independent_event_input_errors(:validate_only => true)
    end

    it "reports independent Date Label errors across Event groups without a derivative Date error or new controlled values" do
      bad_type = "not-a-real-event-type"
      bad_outcome = "not-a-real-outcome"
      unknown_label = "anw-2999-date-label-#{SecureRandom.uuid}"
      impossible_date = "1999-13-01"
      title = "Digital Object Title #{@now} accumulated date labels"
      labels_before = date_label_values
      label_count_before = date_label_record_count
      types_before = event_event_type_values
      outcomes_before = event_outcome_values
      result = import_event_sheet(
        {
          "event_1_type" => "cataloged",
          "event_1_date" => "   ",
          "event_1_date_label" => "publication",
          "event_6_type" => bad_type,
          "event_6_date" => impossible_date,
          "event_6_date_label" => unknown_label,
          "event_6_outcome" => bad_outcome,
        },
        :title => title,
        :extra_indices => [2, 6],
        :create_enums => true
      )
      messages = row_messages(result[:report])
      errors = messages[:errors]
      label_without_date = errors.select { |error|
        text = error.to_s
        text.include?("event_1_date_label") && text.include?("publication") && text.match?(/\bgroup 1\b/)
      }
      group_1_date_errors = errors.select { |error|
        text = error.to_s
        text.include?("event_1_date") && !text.include?("event_1_date_label")
      }
      type_6 = errors.select { |error|
        text = error.to_s
        text.include?("event_6_type") && text.include?(bad_type) && text.match?(/\bgroup 6\b/)
      }
      date_6 = errors.select { |error|
        text = error.to_s
        text.include?("event_6_date") && !text.include?("event_6_date_label") &&
          text.include?(impossible_date) && text.match?(/\bgroup 6\b/)
      }
      label_6 = errors.select { |error|
        text = error.to_s
        text.include?("event_6_date_label") && text.include?(unknown_label) && text.match?(/\bgroup 6\b/)
      }
      outcome_6 = errors.select { |error|
        text = error.to_s
        text.include?("event_6_outcome") && text.include?(bad_outcome) && text.match?(/\bgroup 6\b/)
      }

      aggregate_failures do
        expect(result[:report].terminal_error).to be_nil, result[:report].terminal_error.inspect
        expect(label_without_date.length).to eq(1), errors.inspect
        expect(group_1_date_errors).to eq([]), errors.inspect
        expect(type_6.length).to eq(1), errors.inspect
        expect(date_6.length).to eq(1), errors.inspect
        expect(label_6.length).to eq(1), errors.inspect
        expect(outcome_6.length).to eq(1), errors.inspect
        expect(errors.length).to eq(5), errors.inspect
        expect(errors.join("\n")).not_to match(/\bgroup 2\b/)
        expect(errors.join("\n")).not_to include("translation missing")
        expect(messages[:info]).not_to include(
          I18n.t("bulk_import.event_created", :group => 1, :type => "cataloged")
        )
        expect(messages[:info]).not_to include(
          I18n.t("bulk_import.event_created", :group => 6, :type => bad_type)
        )
        expect(DigitalObject.where(:title => title).count).to eq(0)
        expect(Event.count).to eq(result[:events_before])
        expect(date_label_values).to eq(labels_before)
        expect(date_label_values).not_to include(unknown_label)
        expect(date_label_record_count).to eq(label_count_before)
        expect(event_event_type_values).to eq(types_before)
        expect(event_outcome_values).to eq(outcomes_before)
      end
    end

    it "includes event_1_date_label once in the maintained Event family" do
      csv_data = CSV.read(File.join(TEMPLATES_DIR, "bulk_import_DO_template.csv"))
      columns = csv_data[0]
      explanations = csv_data[1]

      aggregate_failures do
        expect(csv_data.count).to eq(2)
        expect(explanations.length).to eq(columns.length)
        expect(family_headers_at(columns, "event", 1)).to eq([
          "event_1_type",
          "event_1_date",
          "event_1_date_label",
          "event_1_outcome",
          "event_1_outcome_note",
          "event_1_agent_1_record_id",
          "event_1_agent_1_agent_type",
          "event_1_agent_1_role",
        ])
        label_index = columns.index("event_1_date_label")
        expect(explanations[label_index || columns.length]).to eq("Event(1) Date Label (optional with Date; blank defaults to other)")
        expect(columns.grep(/\Aevent_1_/).length).to eq(8)
      end
    end

    it "derives a noncontiguous Event date label from the maintained event_1 family" do
      columns = CSV.read(File.join(TEMPLATES_DIR, "bulk_import_DO_template.csv"))[0]

      expect(family_headers_at(columns, "event", 10)).to eq([
        "event_10_type",
        "event_10_date",
        "event_10_date_label",
        "event_10_outcome",
        "event_10_outcome_note",
        "event_10_agent_1_record_id",
        "event_10_agent_1_agent_type",
        "event_10_agent_1_role",
      ])
    end
  end

  context "Event agent links" do
    def import_event_with_agent_columns(cells, title:, extra_indices: [], validate_only: false)
      report = import_event_agent_rows(
        [{ :title => title, :cells => cells }],
        :extra_indices => extra_indices,
        :validate_only => validate_only
      )
      digital_object, event = persisted_event_for(title)
      {
        :report => report,
        :digital_object => digital_object,
        :event => event,
      }
    end

    def import_event_agent_rows(row_specs, extra_indices: [], validate_only: false)
      csv_data = CSV.read(File.join(TEMPLATES_DIR, "bulk_import_DO_template.csv"))
      columns = csv_data[0].dup
      explanations = csv_data[1].dup
      extra_indices.each do |index|
        headers = family_headers_at(columns, "event", index)
        columns += headers
        explanations += headers.map { "Event(#{index})" }
      end

      data_rows = row_specs.map do |spec|
        row = {}
        columns.each { |column| row[column] = nil }
        row["res_uri"] = @resource.uri
        row["ao_uri"] = @archival_object.uri
        row["digital_object_title"] = spec.fetch(:title)
        spec.fetch(:cells).each { |key, value| row[key] = value }
        row
      end

      csv_string = CSV.generate(col_sep: ",") do |csv|
        csv << columns
        csv << explanations
        data_rows.each { |row| csv << row.values }
      end
      csv_filename = "bulk_import_DO_template_#{@now}_#{SecureRandom.uuid}.csv"
      csv_path = File.join(Dir.tmpdir, csv_filename)
      File.write(csv_path, csv_string)
      opts = {
        :repo_id => @resource[:repo_id],
        :rid => @resource[:id],
        :type => "resource",
        :filename => csv_filename,
        :filepath => csv_path,
        :load_type => "digital_object",
        :validate => validate_only,
      }
      ImportDigitalObjects.new(opts[:filepath], "csv", @current_user, opts).run
    end

    def persisted_event_for(title)
      records = DigitalObject.where(:title => title).all
      return [nil, nil] if records.empty?

      digital_object = JSONModel(:digital_object).find(records[0].id)
      linked_event = digital_object["linked_events"] && digital_object["linked_events"][0]
      event = linked_event ? JSONModel(:event).find_by_uri(linked_event["ref"]) : nil
      [digital_object, event]
    end

    def agent_record_count
      AgentPerson.count + AgentFamily.count + AgentCorporateEntity.count + AgentSoftware.count
    end

    def event_agent_role_values
      enumeration = Enumeration.find(:name => "linked_agent_event_roles")
      Enumeration.to_jsonmodel(enumeration)["values"]
    end

    def event_agent_role_record_count
      enumeration = Enumeration.find(:name => "linked_agent_event_roles")
      EnumerationValue.where(:enumeration_id => enumeration.id).count
    end

    def with_suppressed_event_agent_role(stored_value)
      enumeration = Enumeration.find(:name => "linked_agent_event_roles")
      enum_value = EnumerationValue.find(:enumeration_id => enumeration.id, :value => stored_value)
      enum_value.suppressed = 1
      enum_value.save
      yield
    ensure
      if enum_value
        enum_value.suppressed = 0
        enum_value.save
      end
    end

    def event_agent_pairs(event)
      return nil unless event

      event["linked_agents"].map { |link| [link["role"], link["ref"]] }
    end

    def event_source_pairs(event)
      return nil unless event

      event["linked_records"].map { |link| [link["role"], link["ref"]] }
    end

    def expect_saved_event_agent(result, role:, ref:)
      row_report = result[:report].rows.first
      errors = row_report ? row_report.errors : []
      digital_object = result[:digital_object]

      aggregate_failures do
        expect(result[:report].terminal_error).to be_nil, result[:report].terminal_error.inspect
        expect(errors).to eq([])
        expect(digital_object).not_to be_nil
        expect(event_agent_pairs(result[:event])).to eq([[role, ref]])
        expect(event_source_pairs(result[:event])).to eq([["source", digital_object && digital_object.uri]])
      end
    end

    it "links one existing Agent by canonical URI when Agent Type is blank" do
      agent = create(:json_agent_person)
      title = "Digital Object Title #{@now} event agent uri"
      result = import_event_with_agent_columns(
        {
          "event_1_type" => "cataloged",
          "event_1_date" => "1999-03-03",
          "event_1_agent_1_record_id" => agent.uri,
          "event_1_agent_1_agent_type" => nil,
          "event_1_agent_1_role" => "implementer",
        },
        :title => title
      )

      expect_saved_event_agent(result, :role => "implementer", :ref => agent.uri)
    end

    it "links one existing Agent by numeric ID and Agent Type" do
      agent = create(:json_agent_family)
      title = "Digital Object Title #{@now} event agent numeric id"
      result = import_event_with_agent_columns(
        {
          "event_1_type" => "cataloged",
          "event_1_date" => "1999-03-03",
          "event_1_agent_1_record_id" => agent.id,
          "event_1_agent_1_agent_type" => "agent_family",
          "event_1_agent_1_role" => "recipient",
        },
        :title => title
      )

      expect_saved_event_agent(result, :role => "recipient", :ref => agent.uri)
    end

    it "links an existing corporate entity by canonical URI and stores a translated role" do
      agent = create(:json_agent_corporate_entity)
      translated_role = I18n.t("enumerations.linked_agent_event_roles.authorizer")
      title = "Digital Object Title #{@now} event agent corporate uri"
      result = import_event_with_agent_columns(
        {
          "event_1_type" => "cataloged",
          "event_1_date" => "1999-03-03",
          "event_1_agent_1_record_id" => agent.uri,
          "event_1_agent_1_agent_type" => nil,
          "event_1_agent_1_role" => translated_role,
        },
        :title => title
      )

      expect(translated_role).not_to eq("authorizer")
      expect_saved_event_agent(result, :role => "authorizer", :ref => agent.uri)
    end

    it "rejects a URI with an Agent Type and a numeric ID without an Agent Type before saving" do
      person = create(:json_agent_person)
      family = create(:json_agent_family)
      title = "Digital Object Title #{@now} event agent identifier modes"
      events_before = Event.count
      result = import_event_with_agent_columns(
        {
          "event_1_type" => "cataloged",
          "event_1_date" => "1999-03-03",
          "event_1_agent_1_record_id" => person.uri,
          "event_1_agent_1_agent_type" => "agent_person",
          "event_1_agent_1_role" => "implementer",
          "event_2_type" => "processed",
          "event_2_date" => "2001-04-05",
          "event_2_agent_1_record_id" => family.id,
          "event_2_agent_1_agent_type" => nil,
          "event_2_agent_1_role" => "recipient",
        },
        :title => title,
        :extra_indices => [2]
      )
      row_report = result[:report].rows.first
      errors = row_report ? row_report.errors : []
      info = row_report ? row_report.info : []
      uri_errors = errors.select { |error| error.to_s.include?("event_1_agent_1_agent_type") && error.to_s.include?("agent_person") }
      missing_type_errors = errors.select { |error| error.to_s.include?("event_2_agent_1_agent_type") }

      aggregate_failures do
        expect(result[:report].terminal_error).to be_nil, result[:report].terminal_error.inspect
        expect(errors.length).to eq(2), errors.inspect
        expect(uri_errors.length).to eq(1), errors.inspect
        expect(missing_type_errors.length).to eq(1), errors.inspect
        expect(errors.join(" ")).not_to include("translation missing")
        expect(info).not_to include(I18n.t("bulk_import.event_created", :group => 1, :type => "cataloged"))
        expect(info).not_to include(I18n.t("bulk_import.event_created", :group => 2, :type => "processed"))
        expect(DigitalObject.where(:title => title).count).to eq(0)
        expect(Event.count).to eq(events_before)
      end
    end

    it "reports a nonexistent Agent and a missing role, then imports the next row" do
      agent = create(:json_agent_person)
      missing_uri = JSONModel(:agent_person).uri_for(2_000_000_001)
      rejected_title = "Digital Object Title #{@now} missing event agent"
      accepted_title = "Digital Object Title #{@now} continued event agent"
      agents_before = agent_record_count
      events_before = Event.count
      report = import_event_agent_rows([
        {
          :title => rejected_title,
          :cells => {
            "event_1_type" => "cataloged",
            "event_1_date" => "1999-03-03",
            "event_1_agent_1_record_id" => missing_uri,
            "event_1_agent_1_agent_type" => nil,
            "event_1_agent_1_role" => nil,
          },
        },
        {
          :title => accepted_title,
          :cells => {
            "event_1_type" => "processed",
            "event_1_date" => "2001-04-05",
            "event_1_agent_1_record_id" => agent.uri,
            "event_1_agent_1_agent_type" => nil,
            "event_1_agent_1_role" => "implementer",
          },
        },
      ])
      rejected_row = report.rows[0]
      accepted_row = report.rows[1]
      rejected_errors = rejected_row ? rejected_row.errors : []
      rejected_info = rejected_row ? rejected_row.info : []
      accepted_errors = accepted_row ? accepted_row.errors : []
      missing_errors = rejected_errors.select { |error| error.to_s.include?("event_1_agent_1_record_id") && error.to_s.include?(missing_uri) }
      role_errors = rejected_errors.select { |error| error.to_s.include?("event_1_agent_1_role") }
      digital_object, event = persisted_event_for(accepted_title)

      aggregate_failures do
        expect(report.terminal_error).to be_nil, report.terminal_error.inspect
        expect(report.row_count).to eq(2)
        expect(rejected_errors.length).to eq(2), rejected_errors.inspect
        expect(missing_errors.length).to eq(1), rejected_errors.inspect
        expect(role_errors.length).to eq(1), rejected_errors.inspect
        expect(rejected_errors.join(" ")).not_to include("translation missing")
        expect(rejected_info).not_to include(I18n.t("bulk_import.event_created", :group => 1, :type => "cataloged"))
        expect(DigitalObject.where(:title => rejected_title).count).to eq(0)
        expect(agent_record_count).to eq(agents_before)
        expect(accepted_errors).to eq([])
        expect(digital_object).not_to be_nil
        expect(event_agent_pairs(event)).to eq([["implementer", agent.uri]])
        expect(event_source_pairs(event)).to eq([["source", digital_object && digital_object.uri]])
        expect(Event.count).to eq(events_before + 1)
      end
    end

    it "rejects a non-Agent record URI before saving the digital object or creating an Agent" do
      title = "Digital Object Title #{@now} unsupported event agent uri"
      agents_before = agent_record_count
      events_before = Event.count
      result = import_event_with_agent_columns(
        {
          "event_1_type" => "cataloged",
          "event_1_date" => "1999-03-03",
          "event_1_agent_1_record_id" => @resource.uri,
          "event_1_agent_1_agent_type" => nil,
          "event_1_agent_1_role" => "transmitter",
        },
        :title => title
      )
      row_report = result[:report].rows.first
      errors = row_report ? row_report.errors : []
      info = row_report ? row_report.info : []
      identifier_errors = errors.select { |error| error.to_s.include?("event_1_agent_1_record_id") && error.to_s.include?(@resource.uri) }

      aggregate_failures do
        expect(result[:report].terminal_error).to be_nil, result[:report].terminal_error.inspect
        expect(errors.length).to eq(1), errors.inspect
        expect(identifier_errors.length).to eq(1), errors.inspect
        expect(errors.join(" ")).not_to include("translation missing")
        expect(info).not_to include(I18n.t("bulk_import.event_created", :group => 1, :type => "cataloged"))
        expect(DigitalObject.where(:title => title).count).to eq(0)
        expect(Event.count).to eq(events_before)
        expect(agent_record_count).to eq(agents_before)
      end
    end

    it "reports a suppressed Event agent role during validate-only without saving records or changing roles" do
      agent = create(:json_agent_person)
      title = "Digital Object Title #{@now} suppressed event agent role"
      expect(event_agent_role_values).to include("requester")
      captured = {}

      with_suppressed_event_agent_role("requester") do
        captured[:during] = event_agent_role_values
        captured[:count] = event_agent_role_record_count
        captured[:agents_before] = agent_record_count
        captured[:events_before] = Event.count
        captured[:result] = RequestContext.open(:create_enums => true) do
          import_event_with_agent_columns(
            {
              "event_1_type" => "cataloged",
              "event_1_date" => "1999-03-03",
              "event_1_agent_1_record_id" => agent.uri,
              "event_1_agent_1_agent_type" => nil,
              "event_1_agent_1_role" => "requester",
            },
            :title => title,
            :validate_only => true
          )
        end
        captured[:after] = event_agent_role_values
        captured[:count_after] = event_agent_role_record_count
      end

      result = captured[:result]
      row_report = result[:report].rows.first
      errors = row_report ? row_report.errors : []
      info = row_report ? row_report.info : []
      role_errors = errors.select { |error| error.to_s.include?("event_1_agent_1_role") && error.to_s.include?("requester") }

      aggregate_failures do
        expect(captured[:during]).not_to include("requester")
        expect(result[:report].terminal_error).to be_nil, result[:report].terminal_error.inspect
        expect(role_errors.length).to eq(1), errors.inspect
        expect(errors.join(" ")).not_to include("translation missing")
        expect(info).not_to include(I18n.t("bulk_import.event_created", :group => 1, :type => "cataloged"))
        expect(DigitalObject.where(:title => title).count).to eq(0)
        expect(Event.count).to eq(captured[:events_before])
        expect(agent_record_count).to eq(captured[:agents_before])
        expect(captured[:after]).to eq(captured[:during])
        expect(captured[:count_after]).to eq(captured[:count])
        expect(event_agent_role_values).to include("requester")
      end
    end
  end
end
