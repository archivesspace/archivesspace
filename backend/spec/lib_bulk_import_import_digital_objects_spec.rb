# test ingest
require "spec_helper"
require_relative "../app/lib/bulk_import/import_digital_objects.rb"

describe "Import Digital Objects" do
  BULK_FIXTURES_DIR = File.join(File.dirname(__FILE__), "fixtures", "bulk_import")
  TEMPLATES_DIR = File.join(File.dirname(__FILE__), "../", "../", "templates")
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
    column_explenations = csv_data[1] # CSV header explanations

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
      csv << column_explenations
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
    column_explenations = csv_data[1] # CSV header explanations

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
      csv << column_explenations
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
    column_explenations = csv_data[1] # CSV header explanations

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
      csv << column_explenations
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
    column_explenations = csv_data[1] # CSV header explanations

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
      csv << column_explenations
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
    column_explenations = csv_data[1] # CSV header explanations

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
      csv << column_explenations
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

  it 'successfully creates and assigns a digital object to an existing archival object' do
    # Load Digital Object CSV template file to get columns
    csv_template_path = TEMPLATES_DIR + "/bulk_import_DO_template.csv"
    csv_data = CSV.read(csv_template_path)
    expect(csv_data.count).to eq 2

    columns = csv_data[0] # CSV headers
    column_explenations = csv_data[1] # CSV header explanation

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
      csv << column_explenations
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
end
