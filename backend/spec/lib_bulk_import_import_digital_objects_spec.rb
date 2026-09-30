# test ingest
require "spec_helper"
require_relative "../app/lib/bulk_import/import_digital_objects.rb"

require 'rubyXL/convenience_methods/cell'

describe "Import Digital Objects" do
  BULK_FIXTURES_DIR = File.join(File.dirname(__FILE__), "fixtures", "bulk_import")
  # Templates are canonical in frontend/public/bulk_import_templates/; pointing there directly so specs always use the current version
  TEMPLATES_DIR = File.join(File.dirname(__FILE__), "../", "../", "frontend", "public", "bulk_import_templates")

  def columns_with_second_file_version(columns, explanations)
    fv1 = columns.each_index.select { |i| columns[i].to_s =~ /\Afile_version_1_.+\z/ }
    at = fv1.max + 1
    cols = columns.dup.insert(at, *fv1.map { |i| columns[i].sub(/\Afile_version_1_/, "file_version_2_") })
    expl = explanations.dup.insert(at, *fv1.map { |i| explanations[i].to_s.sub("(1)", "(2)") })
    [cols, expl]
  end

  # Rewrite a family's maintained index-1 headers to another structural index.
  # Grouping tests and the header-guard table derive synthetic groups from the
  # CSV instead of keeping a second canonical-leaf inventory in the spec.
  def family_headers_at(columns, namespace, index)
    index_1 = columns.select { |column| column.to_s.start_with?("#{namespace}_1_") }
    return index_1 if index.to_s == "1"

    index_1.map { |column| column.sub(/\A#{Regexp.escape(namespace)}_1_/, "#{namespace}_#{index}_") }
  end

  def linked_agent_summaries(digital_object)
    digital_object.linked_agents.map do |agent_link|
      uri = agent_link["ref"]
      record, jsonmodel_type = if uri.include?("/agents/people/")
                                 [JSONModel(:agent_person).find_by_uri(uri), "agent_person"]
                               elsif uri.include?("/agents/families/")
                                 [JSONModel(:agent_family).find_by_uri(uri), "agent_family"]
                               elsif uri.include?("/agents/corporate_entities/")
                                 [JSONModel(:agent_corporate_entity).find_by_uri(uri), "agent_corporate_entity"]
                               end
      {
        :title => record.title,
        :jsonmodel_type => jsonmodel_type,
        :role => agent_link["role"],
      }
    end
  end

  def columns_with_second_lang_material(columns, explanations)
    lm1 = columns.each_index.select { |i| columns[i].to_s.start_with?("lang_material_1_") }
    at = lm1.max + 1
    cols = columns.dup.insert(at, *lm1.map { |i| columns[i].sub(/\Alang_material_1_/, "lang_material_2_") })
    expl = explanations.dup.insert(at, *lm1.map { |i| explanations[i].to_s.sub("(1)", "(2)") })
    [cols, expl]
  end

  def import_digital_object_csv(columns, column_explanations, row, validate_only: false)
    csv_string = CSV.generate(col_sep: ',') do |csv|
      csv << columns
      csv << column_explanations
      csv << row.values
    end
    csv_filename = "bulk_import_DO_template_#{@now}_#{SecureRandom.uuid}.csv"
    csv_path = File.join(Dir.tmpdir, csv_filename)
    File.write(csv_path, csv_string)
    opts = { :repo_id => @resource[:repo_id], :rid => @resource[:id], :type => "resource",
             :filename => csv_filename, :filepath => csv_path, :load_type => "digital_object",
             :validate => validate_only }

    ImportDigitalObjects.new(opts[:filepath], "csv", @current_user, opts).run
  end

  before(:each) do
    @now = Time.now.to_i

    @current_user = User.find(:username => "admin")

    resource = JSONModel(:resource).from_hash("id" => 12,
                                              "title" => "Resource Title #{@now}",
                                              "dates" => [{
                                                "date_type" => "single",
                                                "label" => "creation",
                                                "expression" => "1901",
                                              }],
                                              "id_0" => "abc123",
                                              "level" => "collection",
                                              "lang_materials" => [{
                                                "language_and_script" => {
                                                  "language" => "eng",
                                                  "script" => "Latn",
                                                },
                                              }],
                                              "finding_aid_language" => "eng",
                                              "finding_aid_script" => "Latn",
                                              "ead_id" => "VFIRST01",
                                              "extents" => [{
                                                "portion" => "whole",
                                                "number" => "5 or so",
                                                "extent_type" => "reels",
                                              }])

    id = resource.save
    @resource = Resource.get_or_die(id)
    @archival_object = create(
      :json_archival_object,
      title: "Archival Object Title #{@now}",
      :resource => { :ref => @resource.uri }
    )
  end

  it 'successfully creates and assigns a digital object to an existing archival object with extents' do
    # Load Digital Object CSV template file to get columns
    csv_template_path = TEMPLATES_DIR + "/bulk_import_DO_template.csv"
    csv_data = CSV.read(csv_template_path)
    expect(csv_data.count).to eq 2
    columns = csv_data[0] # CSV headers
    column_explanations = csv_data[1] # CSV header explanations

    subject = create(:json_subject)

    subject = nil
    expect do
      subject = create(:json_subject)
    end.to change { Subject.count }.by 1

    # Assign data to csv row, in the same a way user would write them
    digital_object_row = {}
    columns.each do |column|
      digital_object_row[column] = nil
    end
    digital_object_row['res_uri'] = @resource.uri
    digital_object_row['ao_uri'] = @archival_object.uri
    digital_object_row['digital_object_publish'] = 'TRUE'
    digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"

    # Extent 1
    digital_object_row['extent_1_portion'] = 'part'
    digital_object_row['extent_1_number'] = "Extent Number 1 #{@now}"
    digital_object_row['extent_1_extent_type'] = 'photographic_prints'
    digital_object_row['extent_1_container_summary'] = "Extent Container Summary 1 #{@now}"
    digital_object_row['extent_1_physical_details'] = "Extent Physical Details 1 #{@now}"
    digital_object_row['extent_1_dimensions'] = "Extent Dimensions 1 #{@now}"

    # Extent 2
    digital_object_row['extent_2_portion'] = 'whole'
    digital_object_row['extent_2_number'] = "Extent Number 2 #{@now}"
    digital_object_row['extent_2_extent_type'] = 'cassettes'
    digital_object_row['extent_2_container_summary'] = "Extent Container Summary 2 #{@now}"
    digital_object_row['extent_2_physical_details'] = "Extent Physical Details 2 #{@now}"
    digital_object_row['extent_2_dimensions'] = "Extent Dimensions 2 #{@now}"

    csv_string = CSV.generate(col_sep: ',') do |csv|
      csv << columns
      csv << column_explanations
      csv << digital_object_row.values
    end

    csv_filename = "bulk_import_DO_template_#{@now}_#{SecureRandom.uuid}.csv"
    csv_path = File.join(Dir.tmpdir, csv_filename)

    File.write(csv_path, csv_string)

    opts = { :repo_id => @resource[:repo_id],
             :rid => @resource[:id],
             :type => "resource",
             :filename => csv_filename,
             :filepath => csv_path,
             :load_type => "digital_object" }

    importer = ImportDigitalObjects.new(opts[:filepath], "csv", @current_user, opts)

    report = nil
    expect do
      report = importer.run
    end.to change { Extent.count }.by 2

    expect(report.terminal_error).to eq(nil)
    expect(report.row_count).to eq(1)
    expect(report.rows[0].errors).to eq([])
    expect(report.rows[0].archival_object_id).to eq @archival_object.uri
    expect(report.rows[0].archival_object_display).to include @archival_object.title

    digital_objects_created = DigitalObject.where(:title => "Digital Object Title #{@now}").all
    expect(digital_objects_created.count).to eq 1

    expect(digital_objects_created[0]).to have_attributes(
      title: "Digital Object Title #{@now}",
      publish: 1,
    )

    digital_object_created = JSONModel(:digital_object).find(digital_objects_created[0].id)

    expect(digital_object_created.extents.count).to eq 2

    expect(digital_object_created.extents).to match_array([
      include(
        'number' => "Extent Number 1 #{@now}",
        'container_summary' => "Extent Container Summary 1 #{@now}",
        'physical_details' => "Extent Physical Details 1 #{@now}",
        'dimensions' => "Extent Dimensions 1 #{@now}",
        'portion' => 'part',
        'extent_type' => 'photographic_prints'
      ),
      include(
        'number' => "Extent Number 2 #{@now}",
        'container_summary' => "Extent Container Summary 2 #{@now}",
        'physical_details' => "Extent Physical Details 2 #{@now}",
        'dimensions' => "Extent Dimensions 2 #{@now}",
        'portion' => 'whole',
        'extent_type' => 'cassettes'
      ),
    ])
  end

  it 'successfully creates and assigns a digital object to an existing archival object with subjects' do
    # Load Digital Object CSV template file to get columns
    csv_template_path = TEMPLATES_DIR + "/bulk_import_DO_template.csv"
    csv_data = CSV.read(csv_template_path)
    expect(csv_data.count).to eq 2
    columns = csv_data[0] # CSV headers
    column_explanations = csv_data[1] # CSV header explanations

    subject = create(:json_subject)

    subject = nil
    expect do
      subject = create(:json_subject)
    end.to change { Subject.count }.by 1

    # Assign data to csv row, in the same a way user would write them
    digital_object_row = {}
    columns.each do |column|
      digital_object_row[column] = nil
    end
    digital_object_row['res_uri'] = @resource.uri
    digital_object_row['ao_uri'] = @archival_object.uri
    digital_object_row['digital_object_publish'] = 'TRUE'
    digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"

    # Subject 1
    digital_object_row['subject_1_record_id'] = subject.id

    # Subject 2
    digital_object_row['subject_2_term'] = "Subject Term #{@now}"
    digital_object_row['subject_2_type'] = 'genre_form'
    digital_object_row['subject_2_source'] = 'local'

    csv_string = CSV.generate(col_sep: ',') do |csv|
      csv << columns
      csv << column_explanations
      csv << digital_object_row.values
    end

    csv_filename = "bulk_import_DO_template_#{@now}_#{SecureRandom.uuid}.csv"
    csv_path = File.join(Dir.tmpdir, csv_filename)

    File.write(csv_path, csv_string)

    opts = { :repo_id => @resource[:repo_id],
             :rid => @resource[:id],
             :type => "resource",
             :filename => csv_filename,
             :filepath => csv_path,
             :load_type => "digital_object" }

    importer = ImportDigitalObjects.new(opts[:filepath], "csv", @current_user, opts)

    report = nil
    expect do
      report = importer.run
    end.to change { Subject.count }.by 1

    expect(report.terminal_error).to eq(nil)
    expect(report.row_count).to eq(1)
    expect(report.rows[0].errors).to eq([])
    expect(report.rows[0].archival_object_id).to eq @archival_object.uri
    expect(report.rows[0].archival_object_display).to include @archival_object.title

    digital_objects_created = DigitalObject.where(:title => "Digital Object Title #{@now}").all
    expect(digital_objects_created.count).to eq 1

    expect(digital_objects_created[0]).to have_attributes(
      title: "Digital Object Title #{@now}",
      publish: 1,
    )

    digital_object_created = JSONModel(:digital_object).find(digital_objects_created[0].id)

    subject_1 = JSONModel(:subject).find_by_uri(digital_object_created.subjects[0]['ref'])
    expect(subject_1.title).to eq subject.title

    subject_2 = JSONModel(:subject).find_by_uri(digital_object_created.subjects[1]['ref'])
    expect(subject_2.title).to eq "Subject Term #{@now}"
    expect(subject_2.source).to eq 'local'
  end

  it 'successfully creates and assigns a digital object to an existing archival object with agents' do
    # Load Digital Object CSV template file to get columns
    csv_template_path = TEMPLATES_DIR + "/bulk_import_DO_template.csv"
    csv_data = CSV.read(csv_template_path)
    expect(csv_data.count).to eq 2
    columns = csv_data[0] # CSV headers
    column_explanations = csv_data[1] # CSV header explanations

    agent_person = nil
    expect do
      agent_person = create(:json_agent_person)
    end.to change { AgentPerson.count }.by 1

    digital_object_row = {}
    columns.each do |column|
      digital_object_row[column] = nil
    end
    digital_object_row['res_uri'] = @resource.uri
    digital_object_row['ao_uri'] = @archival_object.uri
    digital_object_row['digital_object_publish'] = 'TRUE'
    digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"

    digital_object_row['agent_1_agent_type'] = 'agent_person'
    digital_object_row['agent_1_record_id'] = agent_person.id

    digital_object_row['agent_2_agent_type'] = 'agent_person'
    digital_object_row['agent_2_header'] = "Agent Person Title 1 #{@now}"
    digital_object_row['agent_2_role'] = "Creator"

    csv_string = CSV.generate(col_sep: ',') do |csv|
      csv << columns
      csv << column_explanations
      csv << digital_object_row.values
    end

    csv_filename = "bulk_import_DO_template_#{@now}_#{SecureRandom.uuid}.csv"
    csv_path = File.join(Dir.tmpdir, csv_filename)

    File.write(csv_path, csv_string)

    opts = { :repo_id => @resource[:repo_id],
             :rid => @resource[:id],
             :type => "resource",
             :filename => csv_filename,
             :filepath => csv_path,
             :load_type => "digital_object" }

    importer = ImportDigitalObjects.new(opts[:filepath], "csv", @current_user, opts)

    report = nil
    expect do
      report = importer.run
    end.to change { AgentPerson.count }.by 1

    expect(report.terminal_error).to eq(nil)
    expect(report.row_count).to eq(1)
    expect(report.rows[0].errors).to eq([])
    expect(report.rows[0].archival_object_id).to eq @archival_object.uri
    expect(report.rows[0].archival_object_display).to include @archival_object.title

    digital_objects_created = DigitalObject.where(:title => "Digital Object Title #{@now}").all
    expect(digital_objects_created.count).to eq 1

    expect(digital_objects_created[0]).to have_attributes(
      title: "Digital Object Title #{@now}",
      publish: 1,
    )

    digital_object_created = JSONModel(:digital_object).find(digital_objects_created[0].id)

    expect(linked_agent_summaries(digital_object_created)).to match_array([
      { :title => agent_person.title, :jsonmodel_type => "agent_person", :role => "creator" },
      { :title => "Agent Person Title 1 #{@now}", :jsonmodel_type => "agent_person", :role => "creator" },
    ])
  end

  it 'successfully creates and assigns a digital object to an existing archival object with notes' do
    # Load Digital Object CSV template file to get columns
    csv_template_path = TEMPLATES_DIR + "/bulk_import_DO_template.csv"
    csv_data = CSV.read(csv_template_path)
    expect(csv_data.count).to eq 2
    columns = csv_data[0] # CSV headers
    column_explanations = csv_data[1] # CSV header explanations

    # Assign data to csv row, in the same a way user would write them
    digital_object_row = {}
    columns.each do |column|
      digital_object_row[column] = nil
    end
    digital_object_row['res_uri'] = @resource.uri
    digital_object_row['ao_uri'] = @archival_object.uri
    digital_object_row['digital_object_publish'] = 'TRUE'
    digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"
    # Notes 1
    digital_object_row['note_1_type'] = 'bibliography'
    digital_object_row['note_1_label'] = "Bibliography Note Label #{@now}"
    digital_object_row['note_1_publish'] = 'TRUE'
    digital_object_row['note_1_content'] = "Bibliography Note content #{@now}"
    # Notes 2
    digital_object_row['note_2_type'] = 'accessrestrict'
    digital_object_row['note_2_label'] = "Digital Object Note Label #{@now}"
    digital_object_row['note_2_publish'] = '1'
    digital_object_row['note_2_content'] = "Digital Object Note content #{@now}"

    csv_string = CSV.generate(col_sep: ',') do |csv|
      csv << columns
      csv << column_explanations
      csv << digital_object_row.values
    end

    csv_filename = "bulk_import_DO_template_#{@now}_#{SecureRandom.uuid}.csv"
    csv_path = File.join(Dir.tmpdir, csv_filename)

    File.write(csv_path, csv_string)

    opts = { :repo_id => @resource[:repo_id],
             :rid => @resource[:id],
             :type => "resource",
             :filename => csv_filename,
             :filepath => csv_path,
             :load_type => "digital_object" }

    importer = ImportDigitalObjects.new(opts[:filepath], "csv", @current_user, opts)

    report = importer.run

    expect(report.terminal_error).to eq(nil)
    expect(report.row_count).to eq(1)
    expect(report.rows[0].errors).to eq([])
    expect(report.rows[0].archival_object_id).to eq @archival_object.uri
    expect(report.rows[0].archival_object_display).to include @archival_object.title

    digital_objects_created = DigitalObject.where(:title => "Digital Object Title #{@now}").all
    expect(digital_objects_created.count).to eq 1

    expect(digital_objects_created[0]).to have_attributes(
      title: "Digital Object Title #{@now}",
      publish: 1,
    )

    digital_object_created = JSONModel(:digital_object).find(digital_objects_created[0].id)
    expect(digital_object_created.notes.map { |note|
      [note['jsonmodel_type'], note['type'], note['content'], note['label'], note['publish']]
    }).to match_array([
      ['note_bibliography', 'bibliography', ["Bibliography Note content #{@now}"], "Bibliography Note Label #{@now}", true],
      ['note_digital_object', 'accessrestrict', ["Digital Object Note content #{@now}"], "Digital Object Note Label #{@now}", true],
    ])
  end

  it 'successfully creates and assigns a digital object to an existing archival object with dates' do
    csv_template_path = TEMPLATES_DIR + "/bulk_import_DO_template.csv"
    csv_data = CSV.read(csv_template_path)
    columns = csv_data[0]
    column_explanations = csv_data[1]

    digital_object_row = {}
    columns.each { |column| digital_object_row[column] = nil }
    digital_object_row['res_uri'] = @resource.uri
    digital_object_row['ao_uri'] = @archival_object.uri
    digital_object_row['digital_object_publish'] = 'TRUE'
    digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"
    digital_object_row['date_1_label'] = 'creation'
    digital_object_row['date_1_date_type'] = 'inclusive'
    digital_object_row['date_1_begin'] = '2024-01-01'
    digital_object_row['date_1_end'] = '2024-02-01'
    digital_object_row['date_1_certainty'] = 'approximate'
    digital_object_row['date_2_label'] = 'broadcast'
    digital_object_row['date_2_date_type'] = 'bulk'
    digital_object_row['date_2_begin'] = '2022-01-01'
    digital_object_row['date_2_end'] = '2022-02-01'
    digital_object_row['date_2_certainty'] = 'inferred'

    report = import_digital_object_csv(columns, column_explanations, digital_object_row)

    expect(report.terminal_error).to eq(nil)
    expect(report.row_count).to eq(1)
    expect(report.rows[0].errors).to eq([])
    expect(report.rows[0].archival_object_id).to eq @archival_object.uri
    expect(report.rows[0].archival_object_display).to include @archival_object.title

    digital_objects_created = DigitalObject.where(:title => "Digital Object Title #{@now}").all
    expect(digital_objects_created.count).to eq 1
    expect(digital_objects_created[0]).to have_attributes(
      title: "Digital Object Title #{@now}",
      publish: 1,
    )

    digital_object_created = JSONModel(:digital_object).find(digital_objects_created[0].id)
    expect(digital_object_created.dates.count).to eq 2

    dates_by_label = digital_object_created.dates.each_with_object({}) do |date, hash|
      hash[date['label']] = date
    end
    expect(dates_by_label.keys).to match_array(%w[creation broadcast])
    expect(dates_by_label['creation']).to include(
      'begin' => '2024-01-01',
      'end' => '2024-02-01',
      'date_type' => 'inclusive',
      'label' => 'creation',
      'certainty' => 'approximate'
    )
    expect(dates_by_label['broadcast']).to include(
      'begin' => '2022-01-01',
      'end' => '2022-02-01',
      'date_type' => 'bulk',
      'label' => 'broadcast',
      'certainty' => 'inferred'
    )
  end

  it 'successfully creates and assigns a digital object to an existing archival object with repeatable language materials' do
    csv_template_path = TEMPLATES_DIR + "/bulk_import_DO_template.csv"
    csv_data = CSV.read(csv_template_path)
    columns, column_explanations = columns_with_second_lang_material(csv_data[0], csv_data[1])

    digital_object_row = {}
    columns.each { |column| digital_object_row[column] = nil }
    digital_object_row['res_uri'] = @resource.uri
    digital_object_row['ao_uri'] = @archival_object.uri
    digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"
    digital_object_row['lang_material_1_language_and_script_language'] = 'eng'
    digital_object_row['lang_material_1_language_and_script_script'] = 'Latn'
    digital_object_row['lang_material_2_language_and_script_language'] = 'fre'
    digital_object_row['lang_material_2_language_and_script_script'] = 'Latn'

    report = import_digital_object_csv(columns, column_explanations, digital_object_row)

    expect(report.terminal_error).to eq(nil)
    expect(report.rows[0].errors).to eq([])

    digital_objects_created = DigitalObject.where(:title => "Digital Object Title #{@now}").all
    expect(digital_objects_created.count).to eq 1

    digital_object_created = JSONModel(:digital_object).find(digital_objects_created[0].id)
    expect(digital_object_created.lang_materials.count).to eq 2
    expect(digital_object_created.lang_materials[0]['language_and_script']['language']).to eq 'eng'
    expect(digital_object_created.lang_materials[0]['language_and_script']['script']).to eq 'Latn'
    expect(digital_object_created.lang_materials[1]['language_and_script']['language']).to eq 'fre'
    expect(digital_object_created.lang_materials[1]['language_and_script']['script']).to eq 'Latn'
  end

  it 'successfully creates and assigns a digital object to an existing archival object with user-defined fields' do
    csv_template_path = TEMPLATES_DIR + "/bulk_import_DO_template.csv"
    csv_data = CSV.read(csv_template_path)
    columns = csv_data[0]
    column_explanations = csv_data[1]

    digital_object_row = {}
    columns.each { |column| digital_object_row[column] = nil }
    digital_object_row['res_uri'] = @resource.uri
    digital_object_row['ao_uri'] = @archival_object.uri
    digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"
    digital_object_row['user_defined_string_1'] = 'sv'
    digital_object_row['user_defined_text_1'] = 'a longer note'
    digital_object_row['user_defined_boolean_1'] = 'true'
    digital_object_row['user_defined_integer_1'] = '42'
    digital_object_row['user_defined_real_1'] = '3.14159'
    digital_object_row['user_defined_date_1'] = '2024-01-01'

    report = import_digital_object_csv(columns, column_explanations, digital_object_row)

    expect(report.terminal_error).to eq(nil)
    expect(report.rows[0].errors).to eq([])

    digital_objects_created = DigitalObject.where(:title => "Digital Object Title #{@now}").all
    expect(digital_objects_created.count).to eq 1

    digital_object_created = JSONModel(:digital_object).find(digital_objects_created[0].id)
    ud = digital_object_created.user_defined
    expect(ud['string_1']).to eq 'sv'
    expect(ud['text_1']).to eq 'a longer note'
    expect(ud['boolean_1']).to eq true
    expect(ud['integer_1']).to eq '42'
    expect(ud['real_1']).to eq '3.14159'
    expect(ud['date_1']).to eq '2024-01-01'
  end

  it 'reads User Defined booleans from the row hash after normalization' do
    importer = ImportDigitalObjects.new(nil, 'csv', @current_user, {}, nil)
    importer.instance_variable_set(:@row_hash, { 'user_defined_boolean_1' => 'true' })
    allow(importer).to receive(:normalize_boolean_column) do |row_hash, column|
      row_hash[column] = true
      nil
    end

    expect(importer.send(:create_user_defined)['boolean_1']).to eq(true)
  end

  it 'reads Collection Management booleans from the row hash after normalization' do
    importer = ImportDigitalObjects.new(nil, 'csv', @current_user, {}, nil)
    importer.instance_variable_set(:@row_hash, { 'collection_management_rights_determined' => 'true' })
    allow(importer).to receive(:normalize_boolean_column) do |row_hash, column|
      row_hash[column] = true
      nil
    end

    expect(importer.send(:create_collection_management)['rights_determined']).to eq(true)
  end

  it 'normalizes User Defined whole-number representations without truncating fractions' do
    importer = ImportDigitalObjects.new(nil, 'csv', @current_user, {}, nil)

    expect(importer.send(:normalize_user_defined_integer, '42')).to eq('42')
    expect(importer.send(:normalize_user_defined_integer, '42.0')).to eq('42')
    expect(importer.send(:normalize_user_defined_integer, '4.2e1')).to eq('42')
    %w[42.5 invalid NaN Infinity].each do |value|
      expect { importer.send(:normalize_user_defined_integer, value) }.to raise_error(BulkImportException)
    end
  end

  it 'normalizes User Defined real values without rounding meaningful precision' do
    importer = ImportDigitalObjects.new(nil, 'csv', @current_user, {}, nil)

    expect(importer.send(:normalize_user_defined_real, '3.14000')).to eq('3.14')
    expect(importer.send(:normalize_user_defined_real, '3.14159')).to eq('3.14159')
    expect(importer.send(:normalize_user_defined_real, '1e3')).to eq('1000')
    %w[3.141592 invalid NaN Infinity 1234567890].each do |value|
      expect { importer.send(:normalize_user_defined_real, value) }.to raise_error(BulkImportException)
    end
  end

  it 'successfully creates and assigns a digital object to an existing archival object with collection management' do
    csv_template_path = TEMPLATES_DIR + "/bulk_import_DO_template.csv"
    csv_data = CSV.read(csv_template_path)
    columns = csv_data[0]
    column_explanations = csv_data[1]

    digital_object_row = {}
    columns.each { |column| digital_object_row[column] = nil }
    digital_object_row['res_uri'] = @resource.uri
    digital_object_row['ao_uri'] = @archival_object.uri
    digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"
    digital_object_row['collection_management_processing_status'] = 'completed'
    digital_object_row['collection_management_processing_priority'] = 'high'
    digital_object_row['collection_management_processing_plan'] = 'the plan'
    digital_object_row['collection_management_processors'] = 'Jane Archivist'
    digital_object_row['collection_management_processing_funding_source'] = 'NEH grant'
    digital_object_row['collection_management_processing_hours_per_foot_estimate'] = '5'
    digital_object_row['collection_management_processing_hours_total'] = '40'
    digital_object_row['collection_management_processing_total_extent'] = '3'
    digital_object_row['collection_management_processing_total_extent_type'] = 'cubic_feet'
    digital_object_row['collection_management_rights_determined'] = 'true'

    report = import_digital_object_csv(columns, column_explanations, digital_object_row)

    expect(report.terminal_error).to eq(nil)
    expect(report.rows[0].errors).to eq([])

    digital_objects_created = DigitalObject.where(:title => "Digital Object Title #{@now}").all
    expect(digital_objects_created.count).to eq 1

    digital_object_created = JSONModel(:digital_object).find(digital_objects_created[0].id)
    cm = digital_object_created.collection_management
    expect(cm['processing_status']).to eq 'completed'
    expect(cm['processing_priority']).to eq 'high'
    expect(cm['processing_plan']).to eq 'the plan'
    expect(cm['processors']).to eq 'Jane Archivist'
    expect(cm['processing_funding_source']).to eq 'NEH grant'
    expect(cm['processing_hours_per_foot_estimate']).to eq '5'
    expect(cm['processing_hours_total']).to eq '40'
    expect(cm['processing_total_extent']).to eq '3'
    expect(cm['processing_total_extent_type']).to eq 'cubic_feet'
    expect(cm['rights_determined']).to eq true
  end

  it 'does not report the header marker cell as an unknown column when it differs from the template marker' do
    csv_template_path = TEMPLATES_DIR + "/bulk_import_DO_template.csv"
    csv_data = CSV.read(csv_template_path)
    columns = csv_data[0].dup
    columns[0] = "ArchivesSpace digital object import field codes"
    column_explanations = csv_data[1]

    digital_object_row = {}
    csv_data[0].each { |column| digital_object_row[column] = nil }
    digital_object_row['res_uri'] = @resource.uri
    digital_object_row['ao_uri'] = @archival_object.uri
    digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"

    csv_string = CSV.generate(col_sep: ',') do |csv|
      csv << columns
      csv << column_explanations
      csv << digital_object_row.values
    end

    csv_filename = "bulk_import_DO_template_#{@now}_#{SecureRandom.uuid}.csv"
    csv_path = File.join(Dir.tmpdir, csv_filename)
    File.write(csv_path, csv_string)

    opts = { :repo_id => @resource[:repo_id],
             :rid => @resource[:id],
             :type => "resource",
             :filename => csv_filename,
             :filepath => csv_path,
             :load_type => "digital_object" }

    report = ImportDigitalObjects.new(opts[:filepath], "csv", @current_user, opts).run

    expect(report.terminal_error).to eq(nil)
    expect(DigitalObject.where(:title => "Digital Object Title #{@now}").all.count).to eq 1
  end

  it 'successfully creates and assigns a digital object to an existing archival object' do
    # Load Digital Object CSV template file to get columns
    csv_template_path = TEMPLATES_DIR + "/bulk_import_DO_template.csv"
    csv_data = CSV.read(csv_template_path)
    expect(csv_data.count).to eq 2

    columns = csv_data[0] # CSV headers
    column_explanations = csv_data[1] # CSV header explanation

    # Assign data to csv row, in the same a way user would write them
    digital_object_row = {}
    columns.each do |column|
      digital_object_row[column] = nil
    end
    digital_object_row['level'] = 'collection'
    digital_object_row['restrictions'] = 'TRUE'
    digital_object_row['res_uri'] = @resource.uri
    digital_object_row['ao_uri'] = @archival_object.uri
    digital_object_row['digital_object_publish'] = 'TRUE'
    digital_object_row['digital_object_type'] = "mixed_materials"
    digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"

    csv_string = CSV.generate(col_sep: ',') do |csv|
      csv << columns
      csv << column_explanations
      csv << digital_object_row.values
    end

    csv_filename = "bulk_import_DO_template_#{@now}_#{SecureRandom.uuid}.csv"
    csv_path = File.join(Dir.tmpdir, csv_filename)

    File.write(csv_path, csv_string)

    opts = { :repo_id => @resource[:repo_id],
             :rid => @resource[:id],
             :type => "resource",
             :filename => csv_filename,
             :filepath => csv_path,
             :load_type => "digital_object" }

    importer = ImportDigitalObjects.new(opts[:filepath], "csv", @current_user, opts)
    report = importer.run

    expect(report.terminal_error).to eq(nil)
    expect(report.row_count).to eq(1)
    expect(report.rows[0].errors).to eq([])
    expect(report.rows[0].archival_object_id).to eq @archival_object.uri
    expect(report.rows[0].archival_object_display).to include @archival_object.title

    digital_objects_created = DigitalObject.where(:title => "Digital Object Title #{@now}").all
    expect(digital_objects_created.count).to eq 1

    # Find level_id
    enum = Enumeration.find(:name => "digital_object_level")
    level_id = EnumerationValue.where(enumeration_id: enum.id, value: 'collection').map {|e| e.values[:id]}.first

    # Find digital_object_type_id
    enum = Enumeration.find(:name => "digital_object_digital_object_type")
    digital_object_type_id = EnumerationValue.where(enumeration_id: enum.id, value: 'mixed_materials').map {|e| e.values[:id]}.first

    expect(digital_objects_created[0]).to have_attributes(
      title: "Digital Object Title #{@now}",
      publish: 1,
      restrictions: 1,
      level_id: level_id,
      digital_object_type_id: digital_object_type_id
    )
  end

  context 'create and assign digital object to an archival object with use statement succeeds' do
    context 'when provided file is CSV' do
      it 'successfully creates and assigns a digital object to an archival object with use statement' do
        digital_object_count_before = ::DigitalObject.count

        # Load Digital Object CSV template file to get columns
        csv_template_path = TEMPLATES_DIR + "/bulk_import_DO_template.csv"
        csv_data = CSV.read(csv_template_path)
        expect(csv_data.count).to eq 2

        columns = csv_data[0] # CSV headers
        column_explanations = csv_data[1] # CSV header explanation

        # Assign data to csv row, in the same a way user would write them
        digital_object_row = {}
        columns.each do |column|
          digital_object_row[column] = nil
        end

        digital_object_row['res_uri'] = @resource.uri
        digital_object_row['ao_uri'] = @archival_object.uri
        digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"
        digital_object_row['file_version_1_file_uri'] = "uri"
        digital_object_row['file_version_1_use_statement'] = "application-pdf"

        csv_string = CSV.generate(col_sep: ',') do |csv|
          csv << columns
          csv << column_explanations
          csv << digital_object_row.values
        end

        csv_filename = "bulk_import_DO_template_#{@now}_#{SecureRandom.uuid}.csv"
        csv_path = File.join(Dir.tmpdir, csv_filename)

        File.write(csv_path, csv_string)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => csv_filename,
                 :filepath => csv_path,
                 :load_type => "digital_object" }
        importer = ImportDigitalObjects.new(opts[:filepath], "csv", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        expect(report.rows[0].errors).to eq([])
        expect(report.rows[0].archival_object_id).to eq @archival_object.uri
        expect(report.rows[0].archival_object_display).to include @archival_object.title

        digital_object_count_after = ::DigitalObject.count
        expect(digital_object_count_after).to eq digital_object_count_before + 1

        digital_objects_created = DigitalObject.where(:title => "Digital Object Title #{@now}").all
        expect(digital_objects_created.count).to eq 1
        digital_object = ::DigitalObject.to_jsonmodel(digital_objects_created[0].id)

        expect(digital_object.file_versions.length).to eq 1
        expect(digital_object.file_versions[0]['use_statement']).to eq 'application-pdf'
      end
    end

    context 'when provided file is XLSX' do
      it 'successfully creates and assigns a digital object to an archival object with use statement' do
        digital_object_count_before = ::DigitalObject.count

        xlsx_template_path = TEMPLATES_DIR + "/bulk_import_DO_template.xlsx"
        excel_file = RubyXL::Parser.parse(xlsx_template_path)
        sheet = excel_file['Data']

        column_names = sheet[3].cells.map(&:value)

        # Initialize an empty row
        column_names.each do |column|
          column_index = column_names.find_index(column)
          sheet.add_cell(5, column_index, nil)
        end


        find_index = column_names.find_index('res_uri')
        sheet[5][find_index].change_contents(@resource.uri)

        find_index = column_names.find_index('ao_uri')
        sheet[5][find_index].change_contents(@archival_object.id)

        find_index = column_names.find_index('digital_object_title')
        sheet[5][find_index].change_contents("Digital Object Title #{@now}")

        find_index = column_names.find_index('file_version_1_file_uri')
        sheet[5][find_index].change_contents('file-uri')

        find_index = column_names.find_index('file_version_1_use_statement')
        sheet[5][find_index].change_contents('application-pdf')

        xlsx_filename = "bulk_import_template_#{@now}_#{SecureRandom.uuid}.xlsx"
        xlsx_path = File.join(Dir.tmpdir, xlsx_filename)
        excel_file.save(xlsx_path)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => xlsx_filename,
                 :filepath => xlsx_path,
                 :load_type => "digital_object" }
        importer = ImportDigitalObjects.new(opts[:filepath], "xlsx", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        expect(report.rows[0].errors).to eq([])
        expect(report.rows[0].archival_object_id).to eq @archival_object.uri
        expect(report.rows[0].archival_object_display).to include @archival_object.title

        digital_object_count_after = ::DigitalObject.count
        expect(digital_object_count_after).to eq digital_object_count_before + 1

        digital_objects_created = DigitalObject.where(:title => "Digital Object Title #{@now}").all
        expect(digital_objects_created.count).to eq 1
        digital_object = ::DigitalObject.to_jsonmodel(digital_objects_created[0].id)

        expect(digital_object.file_versions.length).to eq 1
        expect(digital_object.file_versions[0]['use_statement']).to eq 'application-pdf'
      end
    end
  end

  context 'create and assign digital object to an archival object with use statement fails' do
    context 'when provided file is CSV' do
      it 'fails when the digital object file version has an invalid use statement and does not create any records' do
        digital_object_count_before = ::DigitalObject.count

        # Load Digital Object CSV template file to get columns
        csv_template_path = TEMPLATES_DIR + "/bulk_import_DO_template.csv"
        csv_data = CSV.read(csv_template_path)
        expect(csv_data.count).to eq 2

        columns = csv_data[0] # CSV headers
        column_explanations = csv_data[1] # CSV header explanation

        # Assign data to csv row, in the same a way user would write them
        digital_object_row = {}
        columns.each do |column|
          digital_object_row[column] = nil
        end

        digital_object_row['res_uri'] = @resource.uri
        digital_object_row['ao_uri'] = @archival_object.uri
        digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"
        digital_object_row['file_version_1_file_uri'] = "rep-file-uri"
        digital_object_row['file_version_1_use_statement'] = "INVALID_REP_USE_STATEMENT"

        csv_string = CSV.generate(col_sep: ',') do |csv|
          csv << columns
          csv << column_explanations
          csv << digital_object_row.values
        end

        csv_filename = "bulk_import_DO_template_#{@now}_#{SecureRandom.uuid}.csv"
        csv_path = File.join(Dir.tmpdir, csv_filename)

        File.write(csv_path, csv_string)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => csv_filename,
                 :filepath => csv_path,
                 :load_type => "digital_object" }
        importer = ImportDigitalObjects.new(opts[:filepath], "csv", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        rep_use_statement_error = "Cannot create the digital object INVALID: file_version_use_statement: 'INVALID_REP_USE_STATEMENT'. Must be one of: application, application-pdf, audio-clip, audio-master, audio-master-edited, audio-service, image-master, image-master-edited, image-service, image-service-edited, image-thumbnail, test-data, text-codebook, text-data_definition, text-georeference, text-ocr-edited, text-ocr-unedited, text-tei-transcripted, text-tei-translated, video-clip, video-master, video-master-edited, video-service, video-streaming, text-json"
        expect(report.rows[0].errors).to include(rep_use_statement_error)
        expect(report.rows[0].archival_object_id).to eq @archival_object.uri
        expect(report.rows[0].archival_object_display).to include @archival_object.title

        digital_object_count_after = ::DigitalObject.count
        expect(digital_object_count_after).to eq digital_object_count_before
      end
    end

    context 'when provided file is XLSX' do
      it 'fails when the digital object file version has an invalid use statement and does not create any records' do
        digital_object_count_before = ::DigitalObject.count

        xlsx_template_path = TEMPLATES_DIR + "/bulk_import_DO_template.xlsx"
        excel_file = RubyXL::Parser.parse(xlsx_template_path)
        sheet = excel_file['Data']

        column_names = sheet[3].cells.map(&:value)

        # Initialize an empty row
        column_names.each do |column|
          column_index = column_names.find_index(column)
          sheet.add_cell(5, column_index, nil)
        end


        find_index = column_names.find_index('res_uri')
        sheet[5][find_index].change_contents(@resource.uri)

        find_index = column_names.find_index('ao_uri')
        sheet[5][find_index].change_contents(@archival_object.id)

        find_index = column_names.find_index('digital_object_title')
        sheet[5][find_index].change_contents("Digital Object Title #{@now}")

        find_index = column_names.find_index('file_version_1_file_uri')
        sheet[5][find_index].change_contents('file-uri')

        find_index = column_names.find_index('file_version_1_use_statement')
        sheet[5][find_index].change_contents('INVALID_REP_USE_STATEMENT')

        xlsx_filename = "bulk_import_template_#{@now}_#{SecureRandom.uuid}.xlsx"
        xlsx_path = File.join(Dir.tmpdir, xlsx_filename)
        excel_file.save(xlsx_path)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => xlsx_filename,
                 :filepath => xlsx_path,
                 :load_type => "digital_object" }
        importer = ImportDigitalObjects.new(opts[:filepath], "xlsx", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        rep_use_statement_error = "Cannot create the digital object INVALID: file_version_use_statement: 'INVALID_REP_USE_STATEMENT'. Must be one of: application, application-pdf, audio-clip, audio-master, audio-master-edited, audio-service, image-master, image-master-edited, image-service, image-service-edited, image-thumbnail, test-data, text-codebook, text-data_definition, text-georeference, text-ocr-edited, text-ocr-unedited, text-tei-transcripted, text-tei-translated, video-clip, video-master, video-master-edited, video-service, video-streaming, text-json"
        expect(report.rows[0].errors).to include(rep_use_statement_error)
        expect(report.rows[0].archival_object_id).to eq @archival_object.uri
        expect(report.rows[0].archival_object_display).to include @archival_object.title

        digital_object_count_after = ::DigitalObject.count
        expect(digital_object_count_after).to eq digital_object_count_before
      end
    end
  end

  context 'create and assign digital object to an archival object with file format name succeeds' do
    context 'when provided file is CSV' do
      it 'successfully creates and assigns a digital object to an archival object with file format name' do
        digital_object_count_before = ::DigitalObject.count

        # Load Digital Object CSV template file to get columns
        csv_template_path = TEMPLATES_DIR + "/bulk_import_DO_template.csv"
        csv_data = CSV.read(csv_template_path)
        expect(csv_data.count).to eq 2

        columns = csv_data[0] # CSV headers
        column_explanations = csv_data[1] # CSV header explanation

        # Assign data to csv row, in the same a way user would write them
        digital_object_row = {}
        columns.each do |column|
          digital_object_row[column] = nil
        end

        digital_object_row['res_uri'] = @resource.uri
        digital_object_row['ao_uri'] = @archival_object.uri
        digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"
        digital_object_row['file_version_1_file_uri'] = "uri"
        digital_object_row['file_version_1_file_format_name'] = "aiff"

        csv_string = CSV.generate(col_sep: ',') do |csv|
          csv << columns
          csv << column_explanations
          csv << digital_object_row.values
        end

        csv_filename = "bulk_import_DO_template_#{@now}_#{SecureRandom.uuid}.csv"
        csv_path = File.join(Dir.tmpdir, csv_filename)

        File.write(csv_path, csv_string)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => csv_filename,
                 :filepath => csv_path,
                 :load_type => "digital_object" }
        importer = ImportDigitalObjects.new(opts[:filepath], "csv", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        expect(report.rows[0].errors).to eq([])
        expect(report.rows[0].archival_object_id).to eq @archival_object.uri
        expect(report.rows[0].archival_object_display).to include @archival_object.title

        digital_object_count_after = ::DigitalObject.count
        expect(digital_object_count_after).to eq digital_object_count_before + 1

        digital_objects_created = DigitalObject.where(:title => "Digital Object Title #{@now}").all
        expect(digital_objects_created.count).to eq 1
        digital_object = ::DigitalObject.to_jsonmodel(digital_objects_created[0].id)

        expect(digital_object.file_versions.length).to eq 1
        expect(digital_object.file_versions[0]['file_format_name']).to eq 'aiff'
      end
    end

    context 'when provided file is XLSX' do
      it 'successfully creates and assigns a digital object to an archival object with file format name' do
        digital_object_count_before = ::DigitalObject.count

        xlsx_template_path = TEMPLATES_DIR + "/bulk_import_DO_template.xlsx"
        excel_file = RubyXL::Parser.parse(xlsx_template_path)
        sheet = excel_file['Data']

        column_names = sheet[3].cells.map(&:value)

        # Initialize an empty row
        column_names.each do |column|
          column_index = column_names.find_index(column)
          sheet.add_cell(5, column_index, nil)
        end

        find_index = column_names.find_index('res_uri')
        sheet[5][find_index].change_contents(@resource.uri)

        find_index = column_names.find_index('ao_uri')
        sheet[5][find_index].change_contents(@archival_object.id)

        find_index = column_names.find_index('digital_object_title')
        sheet[5][find_index].change_contents("Digital Object Title #{@now}")

        find_index = column_names.find_index('file_version_1_file_uri')
        sheet[5][find_index].change_contents('file-uri')

        find_index = column_names.find_index('file_version_1_file_format_name')
        sheet[5][find_index].change_contents('aiff')

        xlsx_filename = "bulk_import_template_#{@now}_#{SecureRandom.uuid}.xlsx"
        xlsx_path = File.join(Dir.tmpdir, xlsx_filename)
        excel_file.save(xlsx_path)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => xlsx_filename,
                 :filepath => xlsx_path,
                 :load_type => "digital_object" }
        importer = ImportDigitalObjects.new(opts[:filepath], "xlsx", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        expect(report.rows[0].errors).to eq([])
        expect(report.rows[0].archival_object_id).to eq @archival_object.uri
        expect(report.rows[0].archival_object_display).to include @archival_object.title

        digital_object_count_after = ::DigitalObject.count
        expect(digital_object_count_after).to eq digital_object_count_before + 1

        digital_objects_created = DigitalObject.where(:title => "Digital Object Title #{@now}").all
        expect(digital_objects_created.count).to eq 1
        digital_object = ::DigitalObject.to_jsonmodel(digital_objects_created[0].id)

        expect(digital_object.file_versions.length).to eq 1
        expect(digital_object.file_versions[0]['file_format_name']).to eq 'aiff'
      end
    end
  end

  context 'create and assign digital object to an archival object with file format name fails' do
    context 'when provided file is CSV' do
      it 'fails when the digital object file version has an invalid file format name and does not create any records' do
        digital_object_count_before = ::DigitalObject.count

        # Load Digital Object CSV template file to get columns
        csv_template_path = TEMPLATES_DIR + "/bulk_import_DO_template.csv"
        csv_data = CSV.read(csv_template_path)
        expect(csv_data.count).to eq 2

        columns = csv_data[0] # CSV headers
        column_explanations = csv_data[1] # CSV header explanation

        # Assign data to csv row, in the same a way user would write them
        digital_object_row = {}
        columns.each do |column|
          digital_object_row[column] = nil
        end

        digital_object_row['res_uri'] = @resource.uri
        digital_object_row['ao_uri'] = @archival_object.uri
        digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"
        digital_object_row['file_version_1_file_uri'] = "rep-file-uri"
        digital_object_row['file_version_1_file_format_name'] = "INVALID_REP_FILE_FORMAT"

        csv_string = CSV.generate(col_sep: ',') do |csv|
          csv << columns
          csv << column_explanations
          csv << digital_object_row.values
        end

        csv_filename = "bulk_import_DO_template_#{@now}_#{SecureRandom.uuid}.csv"
        csv_path = File.join(Dir.tmpdir, csv_filename)

        File.write(csv_path, csv_string)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => csv_filename,
                 :filepath => csv_path,
                 :load_type => "digital_object" }
        importer = ImportDigitalObjects.new(opts[:filepath], "csv", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        rep_file_format_error = "Cannot create the digital object INVALID: file_version_file_format_name: 'INVALID_REP_FILE_FORMAT'. Must be one of: aiff, avi, gif, jpeg, mp3, pdf, tiff, txt, iiif"
        expect(report.rows[0].errors).to include(rep_file_format_error)
        expect(report.rows[0].archival_object_id).to eq @archival_object.uri
        expect(report.rows[0].archival_object_display).to include @archival_object.title

        digital_object_count_after = ::DigitalObject.count
        expect(digital_object_count_after).to eq digital_object_count_before
      end
    end

    context 'when provided file is XLSX' do
      it 'fails when the digital object file version has an invalid file format name and does not create any records' do
        digital_object_count_before = ::DigitalObject.count

        xlsx_template_path = TEMPLATES_DIR + "/bulk_import_DO_template.xlsx"
        excel_file = RubyXL::Parser.parse(xlsx_template_path)
        sheet = excel_file['Data']

        column_names = sheet[3].cells.map(&:value)

        # Initialize an empty row
        column_names.each do |column|
          column_index = column_names.find_index(column)
          sheet.add_cell(5, column_index, nil)
        end


        find_index = column_names.find_index('res_uri')
        sheet[5][find_index].change_contents(@resource.uri)

        find_index = column_names.find_index('ao_uri')
        sheet[5][find_index].change_contents(@archival_object.id)

        find_index = column_names.find_index('digital_object_title')
        sheet[5][find_index].change_contents("Digital Object Title #{@now}")

        find_index = column_names.find_index('file_version_1_file_uri')
        sheet[5][find_index].change_contents('rep-file-uri')

        find_index = column_names.find_index('file_version_1_file_format_name')
        sheet[5][find_index].change_contents('INVALID_REP_FILE_FORMAT')

        xlsx_filename = "bulk_import_template_#{@now}_#{SecureRandom.uuid}.xlsx"
        xlsx_path = File.join(Dir.tmpdir, xlsx_filename)
        excel_file.save(xlsx_path)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => xlsx_filename,
                 :filepath => xlsx_path,
                 :load_type => "digital_object" }
        importer = ImportDigitalObjects.new(opts[:filepath], "xlsx", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        rep_file_format_error = "Cannot create the digital object INVALID: file_version_file_format_name: 'INVALID_REP_FILE_FORMAT'. Must be one of: aiff, avi, gif, jpeg, mp3, pdf, tiff, txt, iiif"
        expect(report.rows[0].errors).to include(rep_file_format_error)
        expect(report.rows[0].archival_object_id).to eq @archival_object.uri
        expect(report.rows[0].archival_object_display).to include @archival_object.title

        digital_object_count_after = ::DigitalObject.count
        expect(digital_object_count_after).to eq digital_object_count_before
      end
    end
  end

  context 'create and assign digital object to an archival object with a repeatable file version' do
    context 'when provided file is CSV' do
      it 'creates a digital object with a single representative file version' do
        digital_object_count_before = ::DigitalObject.count

        csv_template_path = TEMPLATES_DIR + "/bulk_import_DO_template.csv"
        csv_data = CSV.read(csv_template_path)
        columns = csv_data[0]
        column_explanations = csv_data[1]

        digital_object_row = {}
        columns.each { |column| digital_object_row[column] = nil }

        digital_object_row['res_uri'] = @resource.uri
        digital_object_row['ao_uri'] = @archival_object.uri
        digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"
        digital_object_row['file_version_1_file_uri'] = "http://example.com/av1"
        digital_object_row['file_version_1_is_representative'] = "true"
        digital_object_row['file_version_1_use_statement'] = "image-service"

        csv_string = CSV.generate(col_sep: ',') do |csv|
          csv << columns
          csv << column_explanations
          csv << digital_object_row.values
        end

        csv_filename = "bulk_import_DO_template_#{@now}_#{SecureRandom.uuid}.csv"
        csv_path = File.join(Dir.tmpdir, csv_filename)
        File.write(csv_path, csv_string)

        opts = { :repo_id => @resource[:repo_id], :rid => @resource[:id],
                 :type => "resource", :filename => csv_filename,
                 :filepath => csv_path, :load_type => "digital_object" }
        importer = ImportDigitalObjects.new(opts[:filepath], "csv", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        expect(report.rows[0].errors).to eq([])

        digital_object_count_after = ::DigitalObject.count
        expect(digital_object_count_after).to eq digital_object_count_before + 1

        digital_objects_created = DigitalObject.where(:title => "Digital Object Title #{@now}").all
        expect(digital_objects_created.count).to eq 1
        digital_object = ::DigitalObject.to_jsonmodel(digital_objects_created[0].id)

        expect(digital_object.file_versions.length).to eq 1
        expect(digital_object.file_versions[0]['is_representative']).to be true
        expect(digital_object.file_versions[0]['file_uri']).to eq "http://example.com/av1"
        expect(digital_object.file_versions[0]['use_statement']).to eq 'image-service'
      end

      it 'creates a digital object with two file versions, one representative' do
        digital_object_count_before = ::DigitalObject.count

        csv_data = CSV.read(TEMPLATES_DIR + "/bulk_import_DO_template.csv")
        columns, column_explanations = columns_with_second_file_version(csv_data[0], csv_data[1])

        digital_object_row = {}
        columns.each { |column| digital_object_row[column] = nil }

        digital_object_row['res_uri'] = @resource.uri
        digital_object_row['ao_uri'] = @archival_object.uri
        digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"
        digital_object_row['file_version_1_file_uri'] = "http://example.com/rep"
        digital_object_row['file_version_1_is_representative'] = "true"
        digital_object_row['file_version_1_use_statement'] = "image-service"
        digital_object_row['file_version_2_file_uri'] = "http://example.com/nonrep"
        digital_object_row['file_version_2_use_statement'] = "image-thumbnail"

        csv_string = CSV.generate(col_sep: ',') do |csv|
          csv << columns
          csv << column_explanations
          csv << digital_object_row.values
        end

        csv_filename = "bulk_import_DO_template_#{@now}_#{SecureRandom.uuid}.csv"
        csv_path = File.join(Dir.tmpdir, csv_filename)
        File.write(csv_path, csv_string)

        opts = { :repo_id => @resource[:repo_id], :rid => @resource[:id],
                 :type => "resource", :filename => csv_filename,
                 :filepath => csv_path, :load_type => "digital_object" }
        importer = ImportDigitalObjects.new(opts[:filepath], "csv", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        expect(report.rows[0].errors).to eq([])

        digital_object_count_after = ::DigitalObject.count
        expect(digital_object_count_after).to eq digital_object_count_before + 1

        digital_objects_created = DigitalObject.where(:title => "Digital Object Title #{@now}").all
        expect(digital_objects_created.count).to eq 1
        digital_object = ::DigitalObject.to_jsonmodel(digital_objects_created[0].id)

        expect(digital_object.file_versions.length).to eq 2
        expect(digital_object.file_versions.map { |fv| fv['is_representative'] }).to contain_exactly(true, false)
        expect(digital_object.file_versions.map { |fv| fv['file_uri'] }).to contain_exactly(
          "http://example.com/rep", "http://example.com/nonrep")
      end

      it 'reports an error for each invalid file version and creates no records' do
        digital_object_count_before = ::DigitalObject.count

        csv_data = CSV.read(TEMPLATES_DIR + "/bulk_import_DO_template.csv")
        columns, column_explanations = columns_with_second_file_version(csv_data[0], csv_data[1])

        digital_object_row = {}
        columns.each { |column| digital_object_row[column] = nil }

        digital_object_row['res_uri'] = @resource.uri
        digital_object_row['ao_uri'] = @archival_object.uri
        digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"
        digital_object_row['file_version_1_file_uri'] = "uri-1"
        digital_object_row['file_version_1_use_statement'] = "INVALID_ONE"
        digital_object_row['file_version_2_file_uri'] = "uri-2"
        digital_object_row['file_version_2_use_statement'] = "INVALID_TWO"

        csv_string = CSV.generate(col_sep: ',') do |csv|
          csv << columns
          csv << column_explanations
          csv << digital_object_row.values
        end

        csv_filename = "bulk_import_DO_template_#{@now}_#{SecureRandom.uuid}.csv"
        csv_path = File.join(Dir.tmpdir, csv_filename)
        File.write(csv_path, csv_string)

        opts = { :repo_id => @resource[:repo_id], :rid => @resource[:id],
                 :type => "resource", :filename => csv_filename,
                 :filepath => csv_path, :load_type => "digital_object" }
        importer = ImportDigitalObjects.new(opts[:filepath], "csv", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        expect(report.rows[0].errors).to include(
          a_string_matching(/INVALID_ONE/), a_string_matching(/INVALID_TWO/))

        digital_object_count_after = ::DigitalObject.count
        expect(digital_object_count_after).to eq digital_object_count_before
      end

      it 'reports an error when a file version block is filled in but file_uri is blank' do
        digital_object_count_before = ::DigitalObject.count

        csv_data = CSV.read(TEMPLATES_DIR + "/bulk_import_DO_template.csv")
        columns = csv_data[0]
        column_explanations = csv_data[1]

        digital_object_row = {}
        columns.each { |column| digital_object_row[column] = nil }

        digital_object_row['res_uri'] = @resource.uri
        digital_object_row['ao_uri'] = @archival_object.uri
        digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"
        digital_object_row['file_version_1_use_statement'] = "image-service"

        csv_string = CSV.generate(col_sep: ',') do |csv|
          csv << columns
          csv << column_explanations
          csv << digital_object_row.values
        end

        csv_filename = "bulk_import_DO_template_#{@now}_#{SecureRandom.uuid}.csv"
        csv_path = File.join(Dir.tmpdir, csv_filename)
        File.write(csv_path, csv_string)

        opts = { :repo_id => @resource[:repo_id], :rid => @resource[:id],
                 :type => "resource", :filename => csv_filename,
                 :filepath => csv_path, :load_type => "digital_object" }
        importer = ImportDigitalObjects.new(opts[:filepath], "csv", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        expect(report.rows[0].errors).not_to be_empty
        expect(report.rows[0].errors.join(" ")).to match(/file_uri/)

        digital_object_count_after = ::DigitalObject.count
        expect(digital_object_count_after).to eq digital_object_count_before
      end
    end
  end

  context 'header validation guard against outdated templates' do
    def build_do_csv(columns, column_explanations)
      digital_object_row = {}
      columns.each { |column| digital_object_row[column] = nil }
      digital_object_row['res_uri'] = @resource.uri
      digital_object_row['ao_uri'] = @archival_object.uri
      digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"
      digital_object_row['digital_object_id'] = "do#{@now}"
      yield digital_object_row if block_given?

      csv_string = CSV.generate(col_sep: ',') do |csv|
        csv << columns
        csv << column_explanations
        csv << digital_object_row.values
      end
      csv_filename = "bulk_import_DO_guard_#{@now}_#{SecureRandom.uuid}.csv"
      csv_path = File.join(Dir.tmpdir, csv_filename)
      File.write(csv_path, csv_string)
      [csv_filename, csv_path]
    end

    def run_guard_import(csv_filename, csv_path)
      opts = { :repo_id => @resource[:repo_id], :rid => @resource[:id],
               :type => "resource", :filename => csv_filename,
               :filepath => csv_path, :load_type => "digital_object", :validate => true }
      ImportDigitalObjects.new(opts[:filepath], "csv", @current_user, opts).run
    end

    it 'aborts the whole import with a terminal error when an unrecognized column is present' do
      csv_data = CSV.read(TEMPLATES_DIR + "/bulk_import_DO_template.csv")
      columns = csv_data[0] + ['rep_file_uri']
      column_explanations = csv_data[1] + ['Legacy column']
      csv_filename, csv_path = build_do_csv(columns, column_explanations) do |row|
        row['rep_file_uri'] = "http://example.com/legacy"
      end

      report = run_guard_import(csv_filename, csv_path)

      expect(report.terminal_error).to match(/rep_file_uri/)
    end

    it 'does not flag any column when the spreadsheet matches the current template' do
      csv_data = CSV.read(TEMPLATES_DIR + "/bulk_import_DO_template.csv")
      csv_filename, csv_path = build_do_csv(csv_data[0], csv_data[1])

      report = run_guard_import(csv_filename, csv_path)

      expect(report.terminal_error).to be_nil
    end

    it 'accepts canonical and higher-index headers for every repeatable family and rejects invalid shapes in upload order' do
      csv_data = CSV.read(TEMPLATES_DIR + "/bulk_import_DO_template.csv")
      families = [
        {
          :namespace => "file_version",
          :invented => "file_version_1_bogus",
          :former => %w[file_version_file_uri_2],
        },
        {
          :namespace => "lang_material",
          :invented => "lang_material_1_language_and_script_bogus",
          :former => %w[lang_material_language_2 lang_material_script_1],
        },
        {
          :namespace => "subject",
          :invented => "subject_1_bogus",
          :former => %w[subject_record_id_2 subject_term_1],
        },
        {
          :namespace => "date",
          :invented => "date_1_bogus",
          :former => %w[
            dates_label begin end date_type expression date_certainty
            dates_label_1 begin_1 end_1 date_type_1 expression_1 date_certainty_1
            dates_label_2 begin_2 end_2 date_type_2 expression_2 date_certainty_2
          ],
        },
        {
          :namespace => "note",
          :invented => "note_1_made",
          :former => %w[
            note_type note_label note_publish note_content
            note_type_1 note_label_2 note_publish_9 note_content_3
          ],
        },
        {
          :namespace => "agent",
          :invented => "agent_1_nickname",
          :malformed_extra => %w[agent_-1_relator agent_1.5_header],
          :former => %w[
            people_agent_record_id_1 people_agent_header_1 people_agent_role_1 people_agent_relator_1
            people_agent_record_id_2 people_agent_header_2 people_agent_role_2 people_agent_relator_2
            people_agent_record_id_3 people_agent_header_3 people_agent_role_3 people_agent_relator_3
            people_agent_record_id_4 people_agent_header_4 people_agent_role_4 people_agent_relator_4
            people_agent_record_id_5 people_agent_header_5 people_agent_role_5 people_agent_relator_5
            families_agent_record_id_1 families_agent_header_1 families_agent_role_1 families_agent_relator_1
            families_agent_record_id_2 families_agent_header_2 families_agent_role_2 families_agent_relator_2
            corporate_entities_agent_record_id_1 corporate_entities_agent_header_1 corporate_entities_agent_role_1 corporate_entities_agent_relator_1
            corporate_entities_agent_record_id_2 corporate_entities_agent_header_2 corporate_entities_agent_role_2 corporate_entities_agent_relator_2
            corporate_entities_agent_record_id_3 corporate_entities_agent_header_3 corporate_entities_agent_role_3 corporate_entities_agent_relator_3
          ],
        },
        {
          :namespace => "extent",
          :invented => "extent_1_bogus",
          :malformed_extra => %w[extent__portion extent_x_portion],
        },
      ]

      extra_headers = []
      extra_explanations = []
      families.each do |family|
        already_has_2 = csv_data[0].any? { |column| column.to_s.start_with?("#{family[:namespace]}_2_") }
        [already_has_2 ? nil : 2, 9].compact.each do |idx|
          higher = family_headers_at(csv_data[0], family[:namespace], idx)
          extra_headers.concat(higher)
          extra_explanations.concat(higher.map { "#{family[:namespace]}(#{idx})" })
        end
      end

      csv_filename, csv_path = build_do_csv(csv_data[0] + extra_headers, csv_data[1] + extra_explanations)
      report = run_guard_import(csv_filename, csv_path)
      expect(report.terminal_error).to be_nil

      rejected = []
      families.each do |family|
        index_1 = family_headers_at(csv_data[0], family[:namespace], 1)
        rejected << family[:invented]
        rejected << index_1.first.sub(/\A#{Regexp.escape(family[:namespace])}_1_/, "#{family[:namespace]}_0_")
        rejected << index_1.last.sub(/\A#{Regexp.escape(family[:namespace])}_1_/, "#{family[:namespace]}_01_")
        rejected.concat(Array(family[:malformed_extra]))
        if family[:namespace] == "extent"
          extent_leaves = index_1.map { |header| header.sub(/\Aextent_1_/, "") }
          rejected.concat(extent_leaves)
          rejected.concat(%w[1 2].flat_map { |index| extent_leaves.map { |leaf| "#{leaf}_#{index}" } })
        else
          rejected.concat(Array(family[:former]))
        end
      end
      rejected << "user_defined_boolean_4"

      csv_filename, csv_path = build_do_csv(csv_data[0] + rejected, csv_data[1] + rejected.map { "invalid header" })
      report = run_guard_import(csv_filename, csv_path)
      expect(report.terminal_error).to include(rejected.join(", "))
    end

    it 'permits a blank header cell and still builds Date and Extent groups' do
      csv_data = CSV.read(TEMPLATES_DIR + "/bulk_import_DO_template.csv")
      columns = csv_data[0] + [nil]
      column_explanations = csv_data[1] + [nil]

      row = {}
      columns.each { |column| row[column] = nil }
      row['res_uri'] = @resource.uri
      row['ao_uri'] = @archival_object.uri
      row['digital_object_title'] = "Digital Object Title #{@now}"
      row['date_1_begin'] = '2020-01-01'
      row['date_1_date_type'] = 'single'
      row['extent_1_number'] = '1'
      row['extent_1_extent_type'] = 'cassettes'

      report = import_digital_object_csv(columns, column_explanations, row)

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])
    end
  end

  context 'File Version grouping' do
    def run_fv_import(row_overrides)
      csv_data = CSV.read(TEMPLATES_DIR + "/bulk_import_DO_template.csv")
      fv1 = family_headers_at(csv_data[0], "file_version", 1)
      extra_indices = row_overrides.keys.map { |k| k[/\Afile_version_(\d+)_/, 1] }.compact.uniq
      columns = csv_data[0].dup
      column_explanations = csv_data[1].dup
      extra_indices.each do |idx|
        next if idx == "1"

        columns += fv1.map { |c| c.sub(/\Afile_version_1_/, "file_version_#{idx}_") }
        column_explanations += fv1.map { "File Version(#{idx})" }
      end

      row = {}
      columns.each { |column| row[column] = nil }
      row['res_uri'] = @resource.uri
      row['ao_uri'] = @archival_object.uri
      row['digital_object_title'] = "Digital Object Title #{@now}"
      row_overrides.each { |k, v| row[k] = v }

      import_digital_object_csv(columns, column_explanations, row)
    end

    it 'builds noncontiguous groups in numeric order and ignores an entirely blank group' do
      report = run_fv_import(
        'file_version_10_file_uri' => "http://example.com/ten",
        'file_version_10_use_statement' => "image-thumbnail",
        'file_version_1_file_uri' => nil,
        'file_version_1_use_statement' => nil,
        'file_version_5_file_uri' => nil,
        'file_version_2_file_uri' => "http://example.com/two",
        'file_version_2_use_statement' => "image-service",
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])

      digital_object = ::DigitalObject.to_jsonmodel(
        DigitalObject.where(:title => "Digital Object Title #{@now}").first.id)
      expect(digital_object.file_versions.map { |fv| fv['file_uri'] }).to eq(
        ["http://example.com/two", "http://example.com/ten"])
    end

    it 'lets a partial group reach normal validation' do
      report = run_fv_import(
        'file_version_1_file_uri' => "http://example.com/a",
        'file_version_2_use_statement' => "image-thumbnail",
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.join(" ")).to match(/file_uri/)
    end
  end

  context 'Language Material grouping' do
    def run_lm_import(row_overrides)
      csv_data = CSV.read(TEMPLATES_DIR + "/bulk_import_DO_template.csv")
      lm1 = family_headers_at(csv_data[0], "lang_material", 1)
      extra_indices = row_overrides.keys.map { |k| k[/\Alang_material_(\d+)_language_and_script_/, 1] }.compact.uniq
      columns = csv_data[0].dup
      column_explanations = csv_data[1].dup
      extra_indices.each do |idx|
        next if idx == "1"

        columns += lm1.map { |c| c.sub(/\Alang_material_1_/, "lang_material_#{idx}_") }
        column_explanations += lm1.map { "Language Material(#{idx})" }
      end

      row = {}
      columns.each { |column| row[column] = nil }
      row['res_uri'] = @resource.uri
      row['ao_uri'] = @archival_object.uri
      row['digital_object_title'] = "Digital Object Title #{@now}"
      row_overrides.each { |k, v| row[k] = v }

      import_digital_object_csv(columns, column_explanations, row)
    end

    it 'builds noncontiguous groups in numeric order and ignores an entirely blank group' do
      report = run_lm_import(
        'lang_material_10_language_and_script_language' => 'fre',
        'lang_material_10_language_and_script_script' => 'Latn',
        'lang_material_1_language_and_script_language' => nil,
        'lang_material_1_language_and_script_script' => nil,
        'lang_material_5_language_and_script_language' => nil,
        'lang_material_5_language_and_script_script' => nil,
        'lang_material_2_language_and_script_language' => 'eng',
        'lang_material_2_language_and_script_script' => 'Latn',
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])

      digital_object = ::DigitalObject.to_jsonmodel(
        DigitalObject.where(:title => "Digital Object Title #{@now}").first.id)
      expect(digital_object.lang_materials.map { |lm| lm['language_and_script']['language'] }).to eq(
        %w[eng fre])
    end

    it 'creates a Language-only group without script' do
      report = run_lm_import(
        'lang_material_1_language_and_script_language' => 'eng',
        'lang_material_1_language_and_script_script' => nil,
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])

      digital_object = ::DigitalObject.to_jsonmodel(
        DigitalObject.where(:title => "Digital Object Title #{@now}").first.id)
      expect(digital_object.lang_materials.length).to eq 1
      expect(digital_object.lang_materials[0]['language_and_script']['language']).to eq 'eng'
      expect(digital_object.lang_materials[0]['language_and_script']['script']).to be_nil
    end

    it 'reports a Script-only language material group instead of silently dropping it' do
      report = run_lm_import(
        'lang_material_1_language_and_script_language' => nil,
        'lang_material_1_language_and_script_script' => 'Latn',
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to include(I18n.t("bulk_import.error.lang_code", :lang => ""))
    end
  end

  context 'Subject grouping' do
    def run_subject_import(row_overrides)
      csv_data = CSV.read(TEMPLATES_DIR + "/bulk_import_DO_template.csv")
      subj1 = family_headers_at(csv_data[0], "subject", 1)
      extra_indices = row_overrides.keys.map { |k| k[/\Asubject_(\d+)_/, 1] }.compact.uniq
      columns = csv_data[0].dup
      column_explanations = csv_data[1].dup
      extra_indices.each do |idx|
        next if %w[1 2].include?(idx)

        columns += subj1.map { |c| c.sub(/\Asubject_1_/, "subject_#{idx}_") }
        column_explanations += subj1.map { "Subject(#{idx})" }
      end

      row = {}
      columns.each { |column| row[column] = nil }
      row['res_uri'] = @resource.uri
      row['ao_uri'] = @archival_object.uri
      row['digital_object_title'] = "Digital Object Title #{@now}"
      row_overrides.each { |k, v| row[k] = v }

      import_digital_object_csv(columns, column_explanations, row)
    end

    it 'imports noncontiguous subject groups, merges fields by index, and ignores an entirely blank group' do
      linked_subject = create(:json_subject)
      report = run_subject_import(
        'subject_1_record_id' => nil,
        'subject_1_term' => nil,
        'subject_1_type' => nil,
        'subject_1_source' => nil,
        'subject_5_record_id' => nil,
        'subject_5_term' => nil,
        'subject_5_type' => nil,
        'subject_5_source' => nil,
        'subject_2_term' => "Subject Two #{@now}",
        'subject_2_type' => 'genre_form',
        'subject_2_source' => 'local',
        'subject_10_record_id' => linked_subject.id,
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])

      digital_object = ::DigitalObject.to_jsonmodel(
        DigitalObject.where(:title => "Digital Object Title #{@now}").first.id)
      expect(digital_object.subjects.length).to eq 2

      subjects_by_title = digital_object.subjects.each_with_object({}) do |subject_link, hash|
        subject = JSONModel(:subject).find_by_uri(subject_link['ref'])
        hash[subject.title] = subject
      end
      expect(subjects_by_title.keys).to match_array([linked_subject.title, "Subject Two #{@now}"])

      created_subject = subjects_by_title["Subject Two #{@now}"]
      expect(created_subject.source).to eq 'local'
      expect(created_subject.terms[0]['term_type']).to eq 'genre_form'

      expect(subjects_by_title[linked_subject.title].id).to eq linked_subject.id
    end

    it 'lets a partial group reach normal validation' do
      report = run_subject_import(
        'subject_1_term' => "Partial Subject #{@now}",
        'subject_1_source' => 'ingested',
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.join(" ")).to match(/subject_source/)
    end

    it 'reports a type/source-only subject group instead of silently dropping it' do
      report = run_subject_import(
        'subject_1_type' => 'genre_form',
        'subject_1_source' => 'local',
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to include(
        I18n.t("bulk_import.error.subject_missing_identity", :num => 1))
    end
  end

  context 'Date grouping' do
    def run_date_import(row_overrides)
      csv_data = CSV.read(TEMPLATES_DIR + "/bulk_import_DO_template.csv")
      date_1_headers = family_headers_at(csv_data[0], "date", 1)
      extra_indices = row_overrides.keys.map { |k| k[/\Adate_(\d+)_/, 1] }.compact.uniq
      columns = csv_data[0].dup
      column_explanations = csv_data[1].dup
      extra_indices.each do |idx|
        next if %w[1 2].include?(idx)

        columns += date_1_headers.map { |c| c.sub(/\Adate_1_/, "date_#{idx}_") }
        column_explanations += date_1_headers.map { "Date(#{idx})" }
      end

      row = {}
      columns.each { |column| row[column] = nil }
      row['res_uri'] = @resource.uri
      row['ao_uri'] = @archival_object.uri
      row['digital_object_title'] = "Digital Object Title #{@now}"
      row_overrides.each { |k, v| row[k] = v }

      import_digital_object_csv(columns, column_explanations, row)
    end

    it 'imports noncontiguous date groups, merges fields by index, and ignores an entirely blank group' do
      report = run_date_import(
        'date_1_label' => nil,
        'date_1_begin' => nil,
        'date_1_end' => nil,
        'date_1_date_type' => nil,
        'date_1_expression' => nil,
        'date_1_certainty' => nil,
        'date_5_label' => nil,
        'date_5_begin' => nil,
        'date_5_end' => nil,
        'date_5_date_type' => nil,
        'date_5_expression' => nil,
        'date_5_certainty' => nil,
        'date_2_label' => 'creation',
        'date_2_date_type' => 'single',
        'date_2_begin' => '2000-01-01',
        'date_10_label' => 'broadcast',
        'date_10_date_type' => 'bulk',
        'date_10_begin' => '2010-01-01',
        'date_10_end' => '2011-01-01',
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])

      digital_object = ::DigitalObject.to_jsonmodel(
        DigitalObject.where(:title => "Digital Object Title #{@now}").first.id)
      expect(digital_object.dates.map { |date| [date['label'], date['begin']] }).to match_array(
        [%w[creation 2000-01-01], %w[broadcast 2010-01-01]])
    end

    it 'reports a higher metadata-only date group instead of silently dropping it' do
      report = run_date_import(
        'date_9_label' => 'creation',
        'date_9_date_type' => 'inclusive',
        'date_9_certainty' => 'approximate',
      )

      expect(report.terminal_error).to be_nil
      invalid_date_suffix = I18n.t("bulk_import.error.invalid_date", :what => "x", :date_str => "y").split(". ", 2).last
      expect(report.rows[0].errors.any? { |err| err.end_with?(invalid_date_suffix) }).to be true
      digital_object = ::DigitalObject.to_jsonmodel(
        DigitalObject.where(:title => "Digital Object Title #{@now}").first.id)
      expect(digital_object.dates).to eq([])
    end
  end

  context 'Note grouping' do
    def run_note_import(row_overrides)
      csv_data = CSV.read(TEMPLATES_DIR + "/bulk_import_DO_template.csv")
      columns = csv_data[0].dup
      column_explanations = csv_data[1].dup
      row_overrides.keys.each do |key|
        next if columns.include?(key)

        columns << key
        column_explanations << key
      end

      row = {}
      columns.each { |column| row[column] = nil }
      row['res_uri'] = @resource.uri
      row['ao_uri'] = @archival_object.uri
      row['digital_object_title'] = "Digital Object Title #{@now}"
      row_overrides.each { |k, v| row[k] = v }

      import_digital_object_csv(columns, column_explanations, row)
    end

    it 'imports template groups 1 and 2 and a skipped higher group, merging fields by index and ignoring an entirely blank group' do
      report = run_note_import(
        'note_1_type' => 'bibliography',
        'note_1_label' => "Bibliography Note Label #{@now}",
        'note_1_publish' => 'TRUE',
        'note_1_content' => "Bibliography Note content #{@now}",
        'note_2_type' => 'accessrestrict',
        'note_2_label' => "Digital Object Note Label #{@now}",
        'note_2_publish' => '1',
        'note_2_content' => "Digital Object Note content #{@now}",
        'note_5_type' => nil,
        'note_5_label' => nil,
        'note_5_publish' => nil,
        'note_5_content' => nil,
        'note_9_type' => 'summary',
        'note_9_label' => "Summary Note Label #{@now}",
        'note_9_publish' => 'TRUE',
        'note_9_content' => "Summary Note content #{@now}",
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])

      digital_object = ::DigitalObject.to_jsonmodel(
        DigitalObject.where(:title => "Digital Object Title #{@now}").first.id)
      expect(digital_object.notes.map { |note| [note['type'], note['content'], note['label']] }).to match_array([
        ['bibliography', ["Bibliography Note content #{@now}"], "Bibliography Note Label #{@now}"],
        ['accessrestrict', ["Digital Object Note content #{@now}"], "Digital Object Note Label #{@now}"],
        ['summary', ["Summary Note content #{@now}"], "Summary Note Label #{@now}"],
      ])
    end

    it 'discovers a populated group from a type-only canonical header' do
      report = run_note_import(
        'note_9_type' => 'summary',
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.first).to start_with(
        I18n.t("bulk_import.error.bad_note", :type => "summary", :msg => "").rstrip
      )
    end

    it 'discovers a populated group from a label-only canonical header' do
      report = run_note_import(
        'note_9_label' => "Label-only note #{@now}",
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to include(
        I18n.t("bulk_import.error.bad_note_type", :type => nil)
      )
    end

    it 'discovers a populated group from a publish-only canonical header' do
      report = run_note_import(
        'note_9_publish' => 'TRUE',
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to include(
        I18n.t("bulk_import.error.bad_note_type", :type => nil)
      )
    end

    it 'sends a content-only note group to NotesHandler instead of silently ignoring it' do
      report = run_note_import(
        'note_9_content' => "Orphaned note content #{@now}",
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to include(
        I18n.t("bulk_import.error.bad_note_type", :type => nil)
      )
    end
  end

  context 'Agent grouping' do
    def run_agent_import(row_overrides)
      csv_data = CSV.read(TEMPLATES_DIR + "/bulk_import_DO_template.csv")
      agent_1_headers = family_headers_at(csv_data[0], "agent", 1)
      extra_indices = row_overrides.keys.map { |k| k[/\Aagent_(\d+)_/, 1] }.compact.uniq
      columns = csv_data[0].dup
      column_explanations = csv_data[1].dup
      extra_indices.each do |idx|
        next if %w[1 2].include?(idx)

        columns += agent_1_headers.map { |c| c.sub(/\Aagent_1_/, "agent_#{idx}_") }
        column_explanations += agent_1_headers.map { "Agent(#{idx})" }
      end

      row = {}
      columns.each { |column| row[column] = nil }
      row['res_uri'] = @resource.uri
      row['ao_uri'] = @archival_object.uri
      row['digital_object_title'] = "Digital Object Title #{@now}"
      row_overrides.each { |k, v| row[k] = v }

      import_digital_object_csv(columns, column_explanations, row)
    end

    it 'imports both displayed canonical groups and all three supported Agent types' do
      report = run_agent_import(
        'agent_1_agent_type' => 'agent_person',
        'agent_1_header' => "Person one #{@now}",
        'agent_1_role' => "Creator",
        'agent_2_agent_type' => 'agent_family',
        'agent_2_header' => "Family two #{@now}",
        'agent_2_role' => "Creator",
        'agent_3_agent_type' => 'agent_corporate_entity',
        'agent_3_header' => "Corporate three #{@now}",
        'agent_3_role' => "Creator",
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])

      digital_object = ::DigitalObject.to_jsonmodel(
        DigitalObject.where(:title => "Digital Object Title #{@now}").first.id)
      expect(linked_agent_summaries(digital_object)).to match_array([
        { :title => "Person one #{@now}", :jsonmodel_type => "agent_person", :role => "creator" },
        { :title => "Family two #{@now}", :jsonmodel_type => "agent_family", :role => "creator" },
        { :title => "Corporate three #{@now}", :jsonmodel_type => "agent_corporate_entity", :role => "creator" },
      ])
    end

    it 'links an existing Agent by numeric record ID' do
      linked = create(:json_agent_person)
      report = run_agent_import(
        'agent_1_agent_type' => 'agent_person',
        'agent_1_record_id' => linked.id,
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])

      digital_object = ::DigitalObject.to_jsonmodel(
        DigitalObject.where(:title => "Digital Object Title #{@now}").first.id)
      expect(linked_agent_summaries(digital_object)).to match_array([
        { :title => linked.title, :jsonmodel_type => "agent_person", :role => "creator" },
      ])
      expect(digital_object.linked_agents[0]['ref']).to eq(linked.uri)
    end

    it 'finds an existing Agent by header instead of creating a duplicate' do
      header = "Shared Person #{@now}"
      original_count = AgentPerson.count

      report = run_agent_import(
        'agent_1_agent_type' => 'agent_person',
        'agent_1_header' => header,
        'agent_1_role' => "Creator",
        'agent_2_agent_type' => 'agent_person',
        'agent_2_header' => header,
        'agent_2_role' => "Creator",
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])
      expect(AgentPerson.count).to eq(original_count + 1)

      digital_object = ::DigitalObject.to_jsonmodel(
        DigitalObject.where(:title => "Digital Object Title #{@now}").first.id)
      expect(digital_object.linked_agents.map { |link| link['ref'] }.uniq.length).to eq(1)
      expect(linked_agent_summaries(digital_object).map { |summary| summary[:title] }.uniq).to eq([header])
    end

    it 'imports a high skipped Agent group and ignores an entirely blank group' do
      report = run_agent_import(
        'agent_1_agent_type' => nil,
        'agent_1_record_id' => nil,
        'agent_1_header' => nil,
        'agent_1_role' => nil,
        'agent_1_relator' => nil,
        'agent_5_agent_type' => 'agent_person',
        'agent_5_header' => "Person five #{@now}",
        'agent_5_role' => "Creator",
        'agent_9_agent_type' => nil,
        'agent_9_record_id' => nil,
        'agent_9_header' => nil,
        'agent_9_role' => nil,
        'agent_9_relator' => nil,
        'agent_10_agent_type' => 'agent_family',
        'agent_10_header' => "Family ten #{@now}",
        'agent_10_role' => "Creator",
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])

      digital_object = ::DigitalObject.to_jsonmodel(
        DigitalObject.where(:title => "Digital Object Title #{@now}").first.id)
      expect(linked_agent_summaries(digital_object)).to match_array([
        { :title => "Person five #{@now}", :jsonmodel_type => "agent_person", :role => "creator" },
        { :title => "Family ten #{@now}", :jsonmodel_type => "agent_family", :role => "creator" },
      ])
    end

    it 'groups Agent fields that share an index' do
      report = run_agent_import(
        'agent_5_agent_type' => 'agent_corporate_entity',
        'agent_5_header' => "Corporate five #{@now}",
        'agent_5_role' => "Source",
        'agent_5_relator' => "aut",
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])

      digital_object = ::DigitalObject.to_jsonmodel(
        DigitalObject.where(:title => "Digital Object Title #{@now}").first.id)
      expect(linked_agent_summaries(digital_object)).to match_array([
        { :title => "Corporate five #{@now}", :jsonmodel_type => "agent_corporate_entity", :role => "source" },
      ])
      expect(digital_object.linked_agents[0]['relator']).to eq('aut')
    end

    it 'reports a role-only Agent group instead of silently dropping it' do
      report = run_agent_import(
        'agent_1_role' => "Creator",
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to include(
        I18n.t("bulk_import.error.agent_missing_identity", :num => 1))

      digital_object = ::DigitalObject.to_jsonmodel(
        DigitalObject.where(:title => "Digital Object Title #{@now}").first.id)
      expect(digital_object.linked_agents).to eq([])
    end

    it 'reports a relator-only Agent group instead of silently dropping it' do
      report = run_agent_import(
        'agent_1_relator' => "aut",
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to include(
        I18n.t("bulk_import.error.agent_missing_identity", :num => 1))

      digital_object = ::DigitalObject.to_jsonmodel(
        DigitalObject.where(:title => "Digital Object Title #{@now}").first.id)
      expect(digital_object.linked_agents).to eq([])
    end

    it 'reports a missing Agent type instead of silently dropping the group' do
      report = run_agent_import(
        'agent_1_header' => "Person missing type #{@now}",
        'agent_1_role' => "Creator",
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to include(
        I18n.t("bulk_import.error.agent_missing_type", :num => 1))

      digital_object = ::DigitalObject.to_jsonmodel(
        DigitalObject.where(:title => "Digital Object Title #{@now}").first.id)
      expect(digital_object.linked_agents).to eq([])
    end

    it 'reports an unsupported Agent type instead of silently dropping the group' do
      report = run_agent_import(
        'agent_1_agent_type' => 'agent_software',
        'agent_1_header' => "Software one #{@now}",
        'agent_1_role' => "Creator",
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to include(
        I18n.t("bulk_import.error.agent_unsupported_type", :num => 1, :agent_type => 'agent_software'))

      digital_object = ::DigitalObject.to_jsonmodel(
        DigitalObject.where(:title => "Digital Object Title #{@now}").first.id)
      expect(digital_object.linked_agents).to eq([])
    end
  end

  context 'Extent grouping' do
    def run_extent_import(row_overrides)
      csv_data = CSV.read(TEMPLATES_DIR + "/bulk_import_DO_template.csv")
      extra_indices = row_overrides.keys.map { |k| k[/\Aextent_(\d+)_/, 1] }.compact.uniq
      columns = csv_data[0].dup
      column_explanations = csv_data[1].dup
      extra_indices.each do |idx|
        next if columns.any? { |column| column =~ /\Aextent_#{idx}_/ }

        extra = family_headers_at(columns, "extent", idx)
        columns += extra
        column_explanations += extra.map { "Extent(#{idx})" }
      end

      row = {}
      columns.each { |column| row[column] = nil }
      row['res_uri'] = @resource.uri
      row['ao_uri'] = @archival_object.uri
      row['digital_object_title'] = "Digital Object Title #{@now}"
      row_overrides.each { |k, v| row[k] = v }

      import_digital_object_csv(columns, column_explanations, row)
    end

    it 'imports template groups 1 and 2 and a skipped higher group, merging fields by index and ignoring an entirely blank group' do
      report = run_extent_import(
        'extent_1_portion' => 'part',
        'extent_1_number' => "Extent Number 1 #{@now}",
        'extent_1_extent_type' => 'photographic_prints',
        'extent_1_container_summary' => "Extent Container Summary 1 #{@now}",
        'extent_1_physical_details' => "Extent Physical Details 1 #{@now}",
        'extent_1_dimensions' => "Extent Dimensions 1 #{@now}",
        'extent_2_portion' => 'whole',
        'extent_2_number' => "Extent Number 2 #{@now}",
        'extent_2_extent_type' => 'cassettes',
        'extent_2_container_summary' => "Extent Container Summary 2 #{@now}",
        'extent_2_physical_details' => "Extent Physical Details 2 #{@now}",
        'extent_2_dimensions' => "Extent Dimensions 2 #{@now}",
        'extent_3_portion' => nil,
        'extent_3_number' => nil,
        'extent_3_extent_type' => nil,
        'extent_3_container_summary' => nil,
        'extent_3_physical_details' => nil,
        'extent_3_dimensions' => nil,
        'extent_5_portion' => 'part',
        'extent_5_number' => "Extent Number 5 #{@now}",
        'extent_5_extent_type' => 'reels',
        'extent_5_container_summary' => "Extent Container Summary 5 #{@now}",
        'extent_5_physical_details' => "Extent Physical Details 5 #{@now}",
        'extent_5_dimensions' => "Extent Dimensions 5 #{@now}",
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])

      digital_object = ::DigitalObject.to_jsonmodel(
        DigitalObject.where(:title => "Digital Object Title #{@now}").first.id)
      expect(digital_object.extents).to match_array([
        include(
          'portion' => 'part',
          'number' => "Extent Number 1 #{@now}",
          'extent_type' => 'photographic_prints',
          'container_summary' => "Extent Container Summary 1 #{@now}",
          'physical_details' => "Extent Physical Details 1 #{@now}",
          'dimensions' => "Extent Dimensions 1 #{@now}"
        ),
        include(
          'portion' => 'whole',
          'number' => "Extent Number 2 #{@now}",
          'extent_type' => 'cassettes',
          'container_summary' => "Extent Container Summary 2 #{@now}",
          'physical_details' => "Extent Physical Details 2 #{@now}",
          'dimensions' => "Extent Dimensions 2 #{@now}"
        ),
        include(
          'portion' => 'part',
          'number' => "Extent Number 5 #{@now}",
          'extent_type' => 'reels',
          'container_summary' => "Extent Container Summary 5 #{@now}",
          'physical_details' => "Extent Physical Details 5 #{@now}",
          'dimensions' => "Extent Dimensions 5 #{@now}"
        ),
      ])
    end

    it 'groups Extent fields that share an index' do
      report = run_extent_import(
        'extent_5_portion' => 'part',
        'extent_5_number' => "Grouped Extent #{@now}",
        'extent_5_extent_type' => 'cassettes',
        'extent_5_container_summary' => "Grouped summary #{@now}",
        'extent_5_physical_details' => "Grouped details #{@now}",
        'extent_5_dimensions' => "Grouped dimensions #{@now}",
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])

      digital_object = ::DigitalObject.to_jsonmodel(
        DigitalObject.where(:title => "Digital Object Title #{@now}").first.id)
      expect(digital_object.extents).to match_array([
        include(
          'portion' => 'part',
          'number' => "Grouped Extent #{@now}",
          'extent_type' => 'cassettes',
          'container_summary' => "Grouped summary #{@now}",
          'physical_details' => "Grouped details #{@now}",
          'dimensions' => "Grouped dimensions #{@now}"
        ),
      ])
    end

    it 'reports a container-summary-only Extent group instead of silently dropping it' do
      report = run_extent_import(
        'extent_5_container_summary' => "Summary-only #{@now}",
      )

      expect(report.terminal_error).to be_nil
      extent_error_prefix = I18n.t("bulk_import.error.extent_validation", :msg => "x", :ext => "y").split(" (y)").first
      expect(report.rows[0].errors.any? { |err| err.start_with?(extent_error_prefix) }).to be true

      digital_object = ::DigitalObject.to_jsonmodel(
        DigitalObject.where(:title => "Digital Object Title #{@now}").first.id)
      expect(digital_object.extents).to eq([])
    end
  end

  context "strict Digital Object booleans" do
    # Upstream ASpaceImport::Utils.normalize_boolean truth table. Real booleans
    # and surrounding whitespace never survive the spreadsheet parser, so the
    # value table reads importer methods directly. The import examples below
    # prove those values round-trip as per-row results.
    TRUE_TOKENS = ["1", "T", "Y", "YES", "TRUE", "t", "yes", "True", " y ", true, 1].freeze
    FALSE_TOKENS = ["0", "F", "N", "NO", "FALSE", "f", "no", "False", " n ", false, 0].freeze
    BLANK_TOKENS = [nil, "", "   "].freeze
    REJECTED_BOOLEAN = "not-a-boolean"
    BOOLEAN_COLUMNS = %w[
      digital_object_publish
      restrictions
      note_9_publish
      file_version_2_publish
      file_version_2_is_representative
      user_defined_boolean_1
      user_defined_boolean_2
      user_defined_boolean_3
      collection_management_rights_determined
    ].freeze

    def importer_for(row_hash)
      importer = ImportDigitalObjects.new(nil, "csv", @current_user, {}, nil)
      importer.instance_variable_set(:@row_hash, row_hash)
      importer.instance_variable_set(:@report, BulkImportReport.new)
      importer.instance_variable_set(:@notes_handler, NotesHandler.new)
      importer
    end

    def root_booleans_for(token)
      @root_booleans_for ||= {}
      @root_booleans_for[token] ||= begin
        captured = {}
        handler = Object.new
        handler.define_singleton_method(:create) do |title:, id:, publish:, level:, digital_object_type:, restrictions:,
                                                     dates:, notes:, extents:, subjects:, linked_agents:, archival_object:,
                                                     report:, file_versions: [], lang_materials: [], user_defined: nil,
                                                     collection_management: nil|
          captured[:publish] = publish
          captured[:restrictions] = restrictions
          nil
        end
        report = BulkImportReport.new
        report.new_row(1)
        importer = importer_for(
          "digital_object_publish" => token,
          "restrictions" => token
        )
        importer.instance_variable_set(:@report, report)
        importer.instance_variable_set(:@digital_object_handler, handler)
        # process_subjects splits @repository before it looks for subject columns.
        importer.instance_variable_set(:@repository, "/repositories/#{@resource.repo_id}")
        importer.create_instance(@archival_object)
        if report.current_row.errors.any?
          raise report.current_row.errors.join("\n")
        end

        captured
      end
    end

    def file_version_boolean(index, field, token)
      row = {
        "file_version_#{index}_file_uri" => "http://example.com/file-version-#{index}",
        "file_version_#{index}_publish" => (field == :publish ? token : false),
        "file_version_#{index}_is_representative" => (field == :is_representative ? token : false),
      }
      importer_for(row).file_versions.first[field]
    end

    def note_publish(index, token)
      notes = importer_for(
        "note_#{index}_type" => "bibliography",
        "note_#{index}_label" => "Label",
        "note_#{index}_content" => "Content",
        "note_#{index}_publish" => token
      ).send(:create_notes)
      notes.first["publish"]
    end

    def boolean_value(column, token)
      case column
      when "digital_object_publish"
        root_booleans_for(token)[:publish]
      when "restrictions"
        root_booleans_for(token)[:restrictions]
      when /\Auser_defined_(boolean_\d+)\z/
        field = Regexp.last_match(1)
        record = importer_for(column => token).send(:create_user_defined)
        record.nil? ? nil : record[field]
      when "collection_management_rights_determined"
        record = importer_for(column => token).send(:create_collection_management)
        record.nil? ? nil : record["rights_determined"]
      when /\Anote_(\d+)_publish\z/
        note_publish(Regexp.last_match(1), token)
      when /\Afile_version_(\d+)_publish\z/
        file_version_boolean(Regexp.last_match(1), :publish, token)
      when /\Afile_version_(\d+)_is_representative\z/
        file_version_boolean(Regexp.last_match(1), :is_representative, token)
      end
    end

    def import_boolean_row(overrides)
      csv_data = CSV.read(TEMPLATES_DIR + "/bulk_import_DO_template.csv")
      columns = csv_data[0].dup
      explanations = csv_data[1].dup
      overrides.each_key do |key|
        next if columns.include?(key)

        columns << key
        explanations << key
      end

      row = {}
      columns.each { |column| row[column] = nil }
      row["res_uri"] = @resource.uri
      row["ao_uri"] = @archival_object.uri
      row["digital_object_title"] = "Digital Object Title #{@now}"
      overrides.each { |key, value| row[key] = value }
      import_digital_object_csv(columns, explanations, row)
    end

    def invalid_boolean_overrides(column)
      overrides = { column => REJECTED_BOOLEAN }
      case column
      when /\Anote_(\d+)_publish\z/
        index = Regexp.last_match(1)
        overrides["note_#{index}_type"] = "bibliography"
        overrides["note_#{index}_label"] = "Label"
        overrides["note_#{index}_content"] = "Content"
      when /\Afile_version_(\d+)_(publish|is_representative)\z/
        index = Regexp.last_match(1)
        leaf = Regexp.last_match(2)
        overrides["file_version_#{index}_file_uri"] = "http://example.com/invalid-#{index}"
        if leaf == "publish"
          overrides["file_version_#{index}_is_representative"] = "NO"
        else
          overrides["file_version_#{index}_publish"] = "NO"
        end
      end
      overrides
    end

    it "accepts the upstream true tokens for every Digital Object boolean" do
      aggregate_failures do
        TRUE_TOKENS.each do |token|
          BOOLEAN_COLUMNS.each do |column|
            value = boolean_value(column, token)
            expect(value).to eq(true),
              "#{column} with #{token.inspect} normalized to #{value.inspect}"
          end
        end
      end
    end

    it "accepts the upstream false tokens for every Digital Object boolean" do
      aggregate_failures do
        FALSE_TOKENS.each do |token|
          BOOLEAN_COLUMNS.each do |column|
            value = boolean_value(column, token)
            expect(value).to eq(false),
              "#{column} with #{token.inspect} normalized to #{value.inspect}"
          end
        end
      end
    end

    it "leaves blank Digital Object booleans unset" do
      aggregate_failures do
        BLANK_TOKENS.each do |token|
          BOOLEAN_COLUMNS.each do |column|
            value = boolean_value(column, token)
            expect(value).to be_nil,
              "#{column} with #{token.inspect} normalized to #{value.inspect}"
          end
        end
      end
    end

    it "raises a column-specific BulkImportException for an unrecognized boolean" do
      raising_columns = BOOLEAN_COLUMNS - %w[digital_object_publish restrictions]
      aggregate_failures do
        raising_columns.each do |column|
          expect { boolean_value(column, REJECTED_BOOLEAN) }.to raise_error(BulkImportException) { |error|
            expect(error.message).to include(column)
            expect(error.message).to include(REJECTED_BOOLEAN)
          }
        end
      end
    end

    it "persists an upstream true token the lenient helper rejects" do
      report = import_boolean_row(
        "digital_object_publish" => "YES",
        "restrictions" => "YES",
        "note_9_type" => "bibliography",
        "note_9_label" => "Strict note",
        "note_9_publish" => "YES",
        "note_9_content" => "Strict note content",
        "file_version_2_file_uri" => "http://example.com/publish",
        "file_version_2_publish" => "YES",
        "file_version_2_is_representative" => "NO",
        "file_version_9_file_uri" => "http://example.com/representative",
        "file_version_9_publish" => "NO",
        "file_version_9_is_representative" => "YES",
        "user_defined_boolean_1" => "YES",
        "user_defined_boolean_2" => "YES",
        "user_defined_boolean_3" => "YES",
        "collection_management_rights_determined" => "YES"
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])

      created = DigitalObject.where(:title => "Digital Object Title #{@now}").all
      expect(created.count).to eq(1)
      digital_object = ::DigitalObject.to_jsonmodel(created.first.id)
      publish_version = digital_object.file_versions.find { |fv| fv["file_uri"] == "http://example.com/publish" }
      representative_version = digital_object.file_versions.find { |fv| fv["file_uri"] == "http://example.com/representative" }

      aggregate_failures do
        expect(digital_object["publish"]).to eq(true)
        expect(digital_object["restrictions"]).to eq(true)
        expect(digital_object.notes.first["publish"]).to eq(true)
        expect(publish_version["publish"]).to eq(true)
        expect(publish_version["is_representative"]).to eq(false)
        expect(representative_version["is_representative"]).to eq(true)
        expect(representative_version["publish"]).to eq(true)
        expect(digital_object.user_defined["boolean_1"]).to eq(true)
        expect(digital_object.user_defined["boolean_2"]).to eq(true)
        expect(digital_object.user_defined["boolean_3"]).to eq(true)
        expect(digital_object.collection_management["rights_determined"]).to eq(true)
      end
    end

    it "reports each unrecognized Digital Object boolean as a per-row error" do
      aggregate_failures do
        BOOLEAN_COLUMNS.each do |column|
          title = "Digital Object Title #{@now} #{column}"
          report = import_boolean_row(invalid_boolean_overrides(column).merge(
            "digital_object_title" => title
          ))
          message = report.rows[0].errors.join("\n")

          expect(report.terminal_error).to be_nil
          expect(message).to include(column), message.inspect
          expect(message).to include(REJECTED_BOOLEAN), message.inspect
          expect(DigitalObject.where(:title => title).count).to eq(0)
        end
      end
    end
  end

  context "exact File Version file_size_bytes" do
    # Numeric cell values are stringified before a CSV or XLSX row is built.
    # Calling file_versions directly keeps integer and float inputs visible
    # to File Version construction.
    def file_version_with_size(index, size)
      importer = ImportDigitalObjects.new(nil, "csv", @current_user, {}, nil)
      importer.instance_variable_set(:@row_hash, {
        "file_version_#{index}_file_uri" => "http://example.com/size-#{index}",
        "file_version_#{index}_file_size_bytes" => size,
      })
      importer.file_versions.first
    end

    it "returns an Integer for string, numeric, and integral-decimal sizes" do
      aggregate_failures do
        ["42", 42, 42.0, "42.0", "4.2e1"].each do |value|
          size = file_version_with_size(1, value)[:file_size_bytes]
          expect(size).to eq(42), "#{value.inspect} produced #{size.inspect}"
          expect(size).to be_a(Integer), "#{value.inspect} produced #{size.class}"
        end
      end
    end

    it "preserves a blank file size as nil" do
      expect(file_version_with_size(1, nil)[:file_size_bytes]).to be_nil
    end

    it "rejects fractional, malformed, and nonfinite file sizes" do
      aggregate_failures do
        ["42.5", 42.5, "invalid", "NaN", "Infinity", Float::NAN, Float::INFINITY].each do |value|
          expect { file_version_with_size(1, value) }.to raise_error(BulkImportException)
        end
      end
    end

    it "names the high-index column and rejected value when a file size is invalid" do
      expect { file_version_with_size(9, "42.5") }.to raise_error(BulkImportException) { |error|
        expect(error.message).to include("file_version_9_file_size_bytes")
        expect(error.message).to include("42.5")
      }
    end

    it "does not create a digital object when a file size is invalid" do
      csv_data = CSV.read(TEMPLATES_DIR + "/bulk_import_DO_template.csv")
      columns = csv_data[0].dup
      explanations = csv_data[1].dup
      column = "file_version_9_file_size_bytes"
      ["file_version_9_file_uri", column].each do |header|
        columns << header
        explanations << header
      end

      row = {}
      columns.each { |header| row[header] = nil }
      title = "Digital Object Title #{@now} invalid file size"
      row["res_uri"] = @resource.uri
      row["ao_uri"] = @archival_object.uri
      row["digital_object_title"] = title
      row["file_version_9_file_uri"] = "http://example.com/invalid-size"
      row[column] = "42.5"

      report = import_digital_object_csv(columns, explanations, row)
      message = report.rows[0].errors.join("\n")

      aggregate_failures do
        expect(report.terminal_error).to be_nil
        expect(message).to include(column), message.inspect
        expect(message).to include("42.5"), message.inspect
        expect(DigitalObject.where(:title => title).count).to eq(0)
      end
    end
  end
end
