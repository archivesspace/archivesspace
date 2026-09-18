# test ingest
require "spec_helper"
require_relative "../app/lib/bulk_import/import_digital_objects.rb"

require 'rubyXL/convenience_methods/cell'

describe "Import Digital Objects" do
  BULK_FIXTURES_DIR = File.join(File.dirname(__FILE__), "fixtures", "bulk_import")
  # Templates are canonical in frontend/public/bulk_import_templates/; pointing there directly so specs always use the current version
  TEMPLATES_DIR = File.join(File.dirname(__FILE__), "../", "../", "frontend", "public", "bulk_import_templates")

  def columns_with_second_file_version(columns, explanations)
    fv1 = columns.each_index.select { |i| columns[i].to_s =~ /\Afile_version_.*_1\z/ }
    at = fv1.max + 1
    cols = columns.dup.insert(at, *fv1.map { |i| columns[i].sub(/_1\z/, "_2") })
    expl = explanations.dup.insert(at, *fv1.map { |i| explanations[i].to_s.sub("(1)", "(2)") })
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
    digital_object_row['portion'] = 'part'
    digital_object_row['number'] = "Extent Number 1 #{@now}"
    digital_object_row['extent_type'] = 'photographic_prints'
    digital_object_row['container_summary'] = "Extent Container Summary 1 #{@now}"
    digital_object_row['physical_details'] = "Extent Physical Details 1 #{@now}"
    digital_object_row['dimensions'] = "Extent Dimensions 1 #{@now}"

    # Extent 2
    digital_object_row['portion_2'] = 'whole'
    digital_object_row['number_2'] = "Extent Number 2 #{@now}"
    digital_object_row['extent_type_2'] = 'cassettes'
    digital_object_row['container_summary_2'] = "Extent Container Summary 2 #{@now}"
    digital_object_row['physical_details_2'] = "Extent Physical Details 2 #{@now}"
    digital_object_row['dimensions_2'] = "Extent Dimensions 2 #{@now}"

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

    extent_1 = digital_object_created.extents[0]
    expect(extent_1).to include(
      'number' => "Extent Number 1 #{@now}",
      'container_summary' => "Extent Container Summary 1 #{@now}",
      'physical_details' => "Extent Physical Details 1 #{@now}",
      'dimensions' => "Extent Dimensions 1 #{@now}",
      'portion' => 'part',
      'extent_type' => 'photographic_prints'
    )

    extent_2 = digital_object_created.extents[1]
    expect(extent_2).to include(
      'number' => "Extent Number 2 #{@now}",
      'container_summary' => "Extent Container Summary 2 #{@now}",
      'physical_details' => "Extent Physical Details 2 #{@now}",
      'dimensions' => "Extent Dimensions 2 #{@now}",
      'portion' => 'whole',
      'extent_type' => 'cassettes'
    )
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
    digital_object_row['subject_record_id_1'] = subject.id

    # Subject 2
    digital_object_row['subject_term_2'] = "Subject Term #{@now}"
    digital_object_row['subject_type_2'] = 'genre_form'
    digital_object_row['subject_source_2'] = 'local'

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

    original_agent_person_count = AgentPerson.count

    # Assign data to csv row, in the same a way user would write them
    digital_object_row = {}
    columns.each do |column|
      digital_object_row[column] = nil
    end
    digital_object_row['res_uri'] = @resource.uri
    digital_object_row['ao_uri'] = @archival_object.uri
    digital_object_row['digital_object_publish'] = 'TRUE'
    digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"

    # Agent Person 1
    digital_object_row['people_agent_record_id_1'] = agent_person.id

    # NOTE The following works but relates to person to family
    # digital_object_row['families_agent_record_id_1'] = agent_person.id

    # Agent Person 2
    digital_object_row['people_agent_header_2'] = "Agent Person Title 1 #{@now}"
    digital_object_row['people_agent_role_2'] = "Creator"

    # Agent Person 3
    digital_object_row['people_agent_header_3'] = "Agent Person Title 2 #{@now}"
    digital_object_row['people_agent_role_3'] = "Creator"

    # Agent Family 1
    digital_object_row['families_agent_header_1'] = "Agent Family Title 1 #{@now}"
    digital_object_row['families_agent_role_1'] = "Creator"

    # Agent Corporate Entity 1
    digital_object_row['corporate_entities_agent_header_1'] = "Agent Corporate Entity Title 1 #{@now}"
    digital_object_row['corporate_entities_agent_role_1'] = "Creator"

    # Agent Corporate Entity 3 to be ommited, because 2 is empty
    digital_object_row['corporate_entities_agent_header_3'] = "Agent Corporate Entity Title 3 #{@now}"
    digital_object_row['corporate_entities_agent_role_3'] = "Creator"

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
    end.to change { AgentPerson.count }.by 2

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

    linked_agent_person_1 = JSONModel(:agent_person).find_by_uri(digital_object_created.linked_agents[0]['ref'])
    expect(linked_agent_person_1.title).to eq agent_person.title
    expect(linked_agent_person_1.linked_agent_roles).to eq ['creator']

    linked_agent_person_2 = JSONModel(:agent_person).find_by_uri(digital_object_created.linked_agents[1]['ref'])
    expect(linked_agent_person_2.title).to eq "Agent Person Title 1 #{@now}"
    expect(linked_agent_person_2.linked_agent_roles).to eq ['creator']

    linked_agent_person_3 = JSONModel(:agent_person).find_by_uri(digital_object_created.linked_agents[2]['ref'])
    expect(linked_agent_person_3.title).to eq "Agent Person Title 2 #{@now}"
    expect(linked_agent_person_3.linked_agent_roles).to eq ['creator']

    linked_agent_corporate_entity_1 = JSONModel(:agent_corporate_entity).find_by_uri(digital_object_created.linked_agents[3]['ref'])
    expect(linked_agent_corporate_entity_1.title).to eq "Agent Corporate Entity Title 1 #{@now}"
    expect(linked_agent_corporate_entity_1.linked_agent_roles).to eq ['creator']

    linked_agent_family_1 = JSONModel(:agent_family).find_by_uri(digital_object_created.linked_agents[4]['ref'])
    expect(linked_agent_family_1.title).to eq "Agent Family Title 1 #{@now}"
    expect(linked_agent_family_1.linked_agent_roles).to eq ['creator']
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
    digital_object_row['note_type'] = 'bibliography'
    digital_object_row['note_label'] = "Bibliography Note Label #{@now}"
    digital_object_row['note_publish'] = 'TRUE'
    digital_object_row['note_content'] = "Bibliography Note content #{@now}"
    # Notes 2
    digital_object_row['note_type_2'] = 'accessrestrict'
    digital_object_row['note_label_2'] = "Digital Object Note Label #{@now}"
    digital_object_row['note_publish_2'] = '1'
    digital_object_row['note_content_2'] = "Digital Object Note content #{@now}"

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
    expect(digital_object_created.notes.count).to eq 2
    expect(digital_object_created.notes[0]).to include(
      'jsonmodel_type' => 'note_bibliography',
      'content' => ["Bibliography Note content #{@now}"],
      'items' => [],
      'label' => "Bibliography Note Label #{@now}",
      'type' => 'bibliography',
      'publish' => true
    )
    expect(digital_object_created.notes[1]).to include(
      'jsonmodel_type' => 'note_digital_object',
      'content' => ["Digital Object Note content #{@now}"],
      'label' => "Digital Object Note Label #{@now}",
      'type' => 'accessrestrict',
      'publish' => true
    )
  end

  it 'successfully creates and assigns a digital object to an existing archival object with dates' do
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
    # Date 1
    digital_object_row['dates_label'] = 'creation'
    digital_object_row['date_type'] = 'inclusive'
    digital_object_row['begin'] = '2024-01-01'
    digital_object_row['end'] = '2024-02-01'
    digital_object_row['date_certainty'] = 'approximate'
    # Date 2
    digital_object_row['dates_label_2'] = 'broadcast'
    digital_object_row['date_type_2'] = 'bulk'
    digital_object_row['begin_2'] = '2022-01-01'
    digital_object_row['end_2'] = '2022-02-01'
    digital_object_row['date_certainty_2'] = 'inferred'

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
    )

    digital_object_created = JSONModel(:digital_object).find(digital_objects_created[0].id)
    expect(digital_object_created.dates.count).to eq 2
    expect(digital_object_created.dates[0]).to include(
      'begin' => '2024-01-01',
      'end' => '2024-02-01',
      'date_type' => 'inclusive',
      'label' => 'creation',
      'certainty' => 'approximate'
    )
    expect(digital_object_created.dates[1]).to include(
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
    columns = csv_data[0] + ['lang_material_language_2', 'lang_material_script_2']
    column_explanations = csv_data[1] + ['Digital Object Language(2)', 'Digital Object Script(2)']

    digital_object_row = {}
    columns.each { |column| digital_object_row[column] = nil }
    digital_object_row['res_uri'] = @resource.uri
    digital_object_row['ao_uri'] = @archival_object.uri
    digital_object_row['digital_object_title'] = "Digital Object Title #{@now}"
    digital_object_row['lang_material_language_1'] = 'eng'
    digital_object_row['lang_material_script_1'] = 'Latn'
    digital_object_row['lang_material_language_2'] = 'fre'
    digital_object_row['lang_material_script_2'] = 'Latn'

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
        digital_object_row['file_version_file_uri_1'] = "uri"
        digital_object_row['file_version_use_statement_1'] = "application-pdf"

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

        find_index = column_names.find_index('file_version_file_uri_1')
        sheet[5][find_index].change_contents('file-uri')

        find_index = column_names.find_index('file_version_use_statement_1')
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
        digital_object_row['file_version_file_uri_1'] = "rep-file-uri"
        digital_object_row['file_version_use_statement_1'] = "INVALID_REP_USE_STATEMENT"

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

        find_index = column_names.find_index('file_version_file_uri_1')
        sheet[5][find_index].change_contents('file-uri')

        find_index = column_names.find_index('file_version_use_statement_1')
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
        digital_object_row['file_version_file_uri_1'] = "uri"
        digital_object_row['file_version_file_format_name_1'] = "aiff"

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

        find_index = column_names.find_index('file_version_file_uri_1')
        sheet[5][find_index].change_contents('file-uri')

        find_index = column_names.find_index('file_version_file_format_name_1')
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
        digital_object_row['file_version_file_uri_1'] = "rep-file-uri"
        digital_object_row['file_version_file_format_name_1'] = "INVALID_REP_FILE_FORMAT"

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

        find_index = column_names.find_index('file_version_file_uri_1')
        sheet[5][find_index].change_contents('rep-file-uri')

        find_index = column_names.find_index('file_version_file_format_name_1')
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
        digital_object_row['file_version_file_uri_1'] = "http://example.com/av1"
        digital_object_row['file_version_is_representative_1'] = "true"
        digital_object_row['file_version_use_statement_1'] = "image-service"

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
        digital_object_row['file_version_file_uri_1'] = "http://example.com/rep"
        digital_object_row['file_version_is_representative_1'] = "true"
        digital_object_row['file_version_use_statement_1'] = "image-service"
        digital_object_row['file_version_file_uri_2'] = "http://example.com/nonrep"
        digital_object_row['file_version_use_statement_2'] = "image-thumbnail"

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
        digital_object_row['file_version_file_uri_1'] = "uri-1"
        digital_object_row['file_version_use_statement_1'] = "INVALID_ONE"
        digital_object_row['file_version_file_uri_2'] = "uri-2"
        digital_object_row['file_version_use_statement_2'] = "INVALID_TWO"

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
        digital_object_row['file_version_use_statement_1'] = "image-service"

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

    it 'does not flag a repeatable column with a higher index than the template lists (file_version_file_uri_2)' do
      csv_data = CSV.read(TEMPLATES_DIR + "/bulk_import_DO_template.csv")
      columns, column_explanations = columns_with_second_file_version(csv_data[0], csv_data[1])
      csv_filename, csv_path = build_do_csv(columns, column_explanations) do |row|
        row['file_version_file_uri_1'] = "http://example.com/1"
        row['file_version_file_uri_2'] = "http://example.com/2"
      end

      report = run_guard_import(csv_filename, csv_path)

      expect(report.terminal_error).to be_nil
    end
  end
end
