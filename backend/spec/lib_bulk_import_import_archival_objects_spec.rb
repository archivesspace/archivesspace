# test ingest
require "spec_helper"
require_relative "../app/lib/bulk_import/import_archival_objects.rb"

require 'rubyXL/convenience_methods/cell'

describe "Import Archival Objects" do
  BULK_FIXTURES_DIR = File.join(File.dirname(__FILE__), "fixtures", "bulk_import")
  TEMPLATES_DIR = File.join(File.dirname(__FILE__), "../", "../", "templates")
  before(:each) do
    @current_user = User.find(:username => "admin")
    # create the resource
    resource = JSONModel(:resource).from_hash("title" => "a resource",
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
  end

  # we don't want to test fixtures with different keys than the real templates!
  it "keeps the example fixtures up to date with the templates" do
    xlsx_fixture = BULK_FIXTURES_DIR + "/bulk_import_VFIRST01_test01.xlsx"
    xlsx_template = TEMPLATES_DIR + "/bulk_import_template.xlsx"
    xlsx_fixture = RubyXL::Parser.parse(xlsx_fixture)
    xlsx_template = RubyXL::Parser.parse(xlsx_template)

    fixture_keys = xlsx_fixture.worksheets[0][3].cells.map { |c| c.value }.compact
    template_keys = xlsx_template.worksheets[0][3].cells.map { |c| c.value }.compact
    expect(template_keys - fixture_keys).to be_empty
    expect(fixture_keys - template_keys).to be_empty

    csv_fixture = BULK_FIXTURES_DIR + "/bulk_import_VFIRST01_test01.csv"
    csv_template = TEMPLATES_DIR + "/bulk_import_template.csv"
    csv_fixture = CSV.read(csv_fixture)
    csv_template = CSV.read(csv_template)

    fixture_keys = csv_fixture.to_a.first
    template_keys = csv_template.to_a.first
    expect(template_keys - fixture_keys).to be_empty
    expect(fixture_keys - template_keys).to be_empty
  end

  it "doesn't have any duplicate keys in the template" do
    xlsx_template = TEMPLATES_DIR + "/bulk_import_template.xlsx"
    xlsx_template = RubyXL::Parser.parse(xlsx_template)

    template_keys = xlsx_template.worksheets[0][3].cells.map { |c| c.value }
    expect(template_keys.size).to eq template_keys.uniq.size
  end

  it "reads in excel spreadsheet at the resource level" do
    opts = { :repo_id => @resource[:repo_id],
             :rid => @resource[:id],
             :type => "resource",
             :filename => "bulk_import_VFIRST01_test01.xlsx",
             :filepath => BULK_FIXTURES_DIR + "/bulk_import_VFIRST01_test01.xlsx",
             :load_type => "archival_object",
             :ref_id => "",
             :aoid => "",
             :position => "" }
    importer = ImportArchivalObjects.new(opts[:filepath], "xlsx", @current_user, opts)
    report = importer.run
    expect(report.terminal_error).to eq(nil)
    expect(report.row_count).to eq(2)
    expect(report.rows[0].errors).to eq([])
    expect(report.rows[0].archival_object_display).to eq("The first series, bulk: 2010 - 2020, 2020")
    expect(report.rows[1].archival_object_display).to eq("A subseries, 2010 - 2011")

    tree = JSONModel::HTTP.get_json("#{@resource.uri}/tree/root")
    expect(tree["precomputed_waypoints"][""]["0"][0]["uri"]).to eq(report.rows[0].archival_object_id)
    subtree = JSONModel::HTTP.get_json("#{@resource.uri}/tree/node", {node_uri: report.rows[0].archival_object_id})
    expect(subtree["precomputed_waypoints"][report.rows[0].archival_object_id]["0"][0]["uri"]).to eq(report.rows[1].archival_object_id)
    dig_obj = JSONModel(:digital_object).find(
      JSONModel(:digital_object).id_for(
        JSONModel::HTTP.get_json(report.rows[0].archival_object_id)["instances"][0]["digital_object"]["ref"]
      )
    )
    expect(dig_obj.publish).to be false
  end
  it "reads in CSV spreadsheet at the resource level" do
    opts = { :repo_id => @resource[:repo_id],
             :rid => @resource[:id],
             :type => "resource",
             :filename => "bulk_import_VFIRST01_test01.csv",
             :filepath => BULK_FIXTURES_DIR + "/bulk_import_VFIRST01_test01.csv",
             :load_type => "archival_object",
             :ref_id => "",
             :aoid => "",
             :position => "" }
    importer = ImportArchivalObjects.new(opts[:filepath], "csv", @current_user, opts)
    report = importer.run
    expect(report.terminal_error).to eq(nil)
    expect(report.row_count).to eq(2)
    expect(report.rows[0].errors).to eq([])
    expect(report.rows[0].archival_object_display).to eq("The first series, bulk: 2010 - 2020, 2020")
    expect(report.rows[1].archival_object_display).to eq("A subseries, 2010 - 2011")
    tree = JSONModel::HTTP.get_json("#{@resource.uri}/tree/root")
    expect(tree["precomputed_waypoints"][""]["0"][0]["uri"]).to eq(report.rows[0].archival_object_id)
    subtree = JSONModel::HTTP.get_json("#{@resource.uri}/tree/node", {node_uri: report.rows[0].archival_object_id})
    expect(subtree["precomputed_waypoints"][report.rows[0].archival_object_id]["0"][0]["uri"]).to eq(report.rows[1].archival_object_id)

    archival_object_id = report.rows[0]['archival_object_id'].split('/').pop
    archival_object = ::ArchivalObject.where(id: archival_object_id).first
    expect(archival_object.publish).to eq 1
    expect(archival_object.restrictions_apply).to eq 1

    archival_object_id = report.rows[1]['archival_object_id'].split('/').pop
    archival_object = ::ArchivalObject.where(id: archival_object_id).first
    expect(archival_object.publish).to eq 1
    expect(archival_object.restrictions_apply).to eq 0
  end

  it 'successfully parses and transforms the boolean columns' do
    opts = { :repo_id => @resource[:repo_id],
             :rid => @resource[:id],
             :type => "resource",
             :filename => "bulk_import_VFIRST01_boolean_columns.csv",
             :filepath => BULK_FIXTURES_DIR + "/bulk_import_VFIRST01_boolean_columns.csv",
             :load_type => "archival_object",
             :ref_id => "",
             :aoid => "",
             :position => "" }
    importer = ImportArchivalObjects.new(opts[:filepath], "csv", @current_user, opts)
    report = importer.run

    expect(report.terminal_error).to eq(nil)
    expect(report.row_count).to eq(4)
    expect(report.rows[0].errors).to eq([])

    # First archival object
    archival_object_id = report.rows[0]['archival_object_id'].split('/').pop
    archival_object = ::ArchivalObject.to_jsonmodel(archival_object_id.to_i)

    expect(archival_object['publish']).to eq true
    expect(archival_object['restrictions_apply']).to eq true

    # Language
    expect(archival_object.lang_materials[0]['notes'][0]['publish']).to eq true
    expect(archival_object.lang_materials[1]['notes'][0]['publish']).to eq false

    # Digital Object
    expect(archival_object.instances.length).to eq 1
    expect(archival_object.instances[0]['instance_type']).to eq 'digital_object'
    digital_object_id = archival_object.instances[0]['digital_object']['ref'].split('/').pop
    digital_object = ::DigitalObject.to_jsonmodel(digital_object_id.to_i)
    expect(digital_object.publish).to eq false
    expect(digital_object['file_versions'][0]['publish']).to eq true
    expect(digital_object['file_versions'][1]['publish']).to eq false

    # Notes
    expect(archival_object.notes.length).to eq 17
    expect(archival_object.notes[0]['publish']).to eq true
    expect(archival_object.notes[1]['publish']).to eq false
    expect(archival_object.notes[2]['publish']).to eq true
    expect(archival_object.notes[3]['publish']).to eq true
    expect(archival_object.notes[4]['publish']).to eq false
    5.upto((archival_object.notes.length - 1)) do |x|
      expect(archival_object.notes[x]['publish']).to eq true
    end

    # Second archival object
    # Field publish is not provided for any of the records.
    # Defaults to false and inherits from archival object.
    archival_object_id = report.rows[1]['archival_object_id'].split('/').pop
    archival_object = ::ArchivalObject.to_jsonmodel(archival_object_id.to_i)

    expect(archival_object['publish']).to eq false
    expect(archival_object['restrictions_apply']).to eq false

    # Language
    expect(archival_object.lang_materials[0]['notes'][0]['publish']).to eq false
    expect(archival_object.lang_materials[1]['notes'][0]['publish']).to eq false

    # Digital Object
    expect(archival_object.instances.length).to eq 1
    expect(archival_object.instances[0]['instance_type']).to eq 'digital_object'
    digital_object_id = archival_object.instances[0]['digital_object']['ref'].split('/').pop
    digital_object = ::DigitalObject.to_jsonmodel(digital_object_id.to_i)
    expect(digital_object.publish).to eq false
    expect(digital_object['file_versions'][0]['publish']).to eq true
    expect(digital_object['file_versions'][1]['publish']).to eq false

    # Notes
    expect(archival_object.notes.length).to eq 17
    1.upto((archival_object.notes.length - 1)) do |x|
      expect(archival_object.notes[x]['publish']).to eq false
    end

    # Third archival object
    # Publish is provided and is false only for the archival object.
    # Defaults to false and inherits from archival object.
    archival_object_id = report.rows[2]['archival_object_id'].split('/').pop
    archival_object = ::ArchivalObject.to_jsonmodel(archival_object_id.to_i)

    expect(archival_object['publish']).to eq false
    expect(archival_object['restrictions_apply']).to eq false

    # Language
    expect(archival_object.lang_materials[0]['notes'][0]['publish']).to eq false
    expect(archival_object.lang_materials[1]['notes'][0]['publish']).to eq false

    # Digital Object
    expect(archival_object.instances.length).to eq 1
    expect(archival_object.instances[0]['instance_type']).to eq 'digital_object'
    digital_object_id = archival_object.instances[0]['digital_object']['ref'].split('/').pop
    digital_object = ::DigitalObject.to_jsonmodel(digital_object_id.to_i)
    expect(digital_object.publish).to eq false
    expect(digital_object['file_versions'][0]['publish']).to eq true
    expect(digital_object['file_versions'][1]['publish']).to eq false

    # Notes
    expect(archival_object.notes.length).to eq 17
    1.upto((archival_object.notes.length - 1)) do |x|
      expect(archival_object.notes[x]['publish']).to eq false
    end

    # Fourth archival object
    # Publish is provided and is true only for the archival object.
    # All records inherit true from the archival object publish.
    archival_object_id = report.rows[3]['archival_object_id'].split('/').pop
    archival_object = ::ArchivalObject.to_jsonmodel(archival_object_id.to_i)

    expect(archival_object['publish']).to eq true
    expect(archival_object['restrictions_apply']).to eq true

    # Language
    expect(archival_object.lang_materials[0]['notes'][0]['publish']).to eq true
    expect(archival_object.lang_materials[1]['notes'][0]['publish']).to eq true

    # Digital Object
    expect(archival_object.instances.length).to eq 1
    expect(archival_object.instances[0]['instance_type']).to eq 'digital_object'
    digital_object_id = archival_object.instances[0]['digital_object']['ref'].split('/').pop
    digital_object = ::DigitalObject.to_jsonmodel(digital_object_id.to_i)
    expect(digital_object.publish).to eq true
    expect(digital_object['file_versions'][0]['publish']).to eq true
    expect(digital_object['file_versions'][1]['publish']).to eq true

    # Notes
    expect(archival_object.notes.length).to eq 17
    1.upto((archival_object.notes.length - 1)) do |x|
      expect(archival_object.notes[x]['publish']).to eq true
    end
  end

  it "adds new instance types to the instance type controlled values list if missing (ANW-1777, ANW-1778)" do
    2.times do
      resource = create(:json_resource, ead_id: "tyler_001")
      opts = { :repo_id => JSONModel(:repository).id_for(resource.repository['ref']),
               :rid => resource.id,
               :type => "resource",
               :filename => "Box36UploadDIDNT_WORK_test.xlsx",
               :filepath => BULK_FIXTURES_DIR + "/Box36UploadDIDNT_WORK_test.xlsx",
               :load_type => "archival_object",
               :ref_id => "",
               :aoid => "",
               :position => "" }

      importer = ImportArchivalObjects.new(opts[:filepath], "xlsx", @current_user, opts)
      report = importer.run
      expect(report.terminal_error).to eq(nil)
      expect(report.row_count).to eq(28)
      expect(report.rows.map { |r| r.errors }.compact.flatten).to eq([])

      types_in_set = report.rows.map {|row|
        JSONModel(:archival_object).find(JSONModel(:archival_object).id_for(row.archival_object_id)).instances
      }.compact.flatten.map { |inst| inst['instance_type'] }

      expect(types_in_set.count("mixed_materials")).to eq(26)
      expect(types_in_set.count("FOO BARS")).to eq(1)
      resource.delete
    end
    enum = Enumeration.find(:name => "instance_instance_type")
    enum_values = EnumerationValue.where(enumeration_id: enum.id).map {|e| e.values[:value]}
    expect(enum_values).not_to include("Mixed Materials")
    expect(enum_values).to include("FOO BARS")
  end

  # see https://archivesspace.atlassian.net/browse/ANW-1777?focusedCommentId=39145
  it "adds unrecognized container types to the enum" do
    resource = create(:json_resource, ead_id: "9916")
    opts = { :repo_id => JSONModel(:repository).id_for(resource.repository['ref']),
             :rid => resource.id,
             :type => "resource",
             :filename => "checkingbugAug012023.xlsx",
             :filepath => BULK_FIXTURES_DIR + "/checkingbugAug012023.xlsx",
             :load_type => "archival_object",
             :ref_id => "",
             :aoid => "",
             :position => "" }

    importer = ImportArchivalObjects.new(opts[:filepath], "xlsx", @current_user, opts)
    report = importer.run
    expect(report.terminal_error).to eq(nil)
    expect(report.row_count).to eq(9)
    expect(report.rows.map { |r| r.errors }.compact.flatten).to eq([])
    container_info = report.rows.map {|r| r.info }.flatten.compact.map
    container_uris = container_info.map { |i| i.sub(/.*created:\s/, '') }
    container_strings = container_info.map { |i| i.sub(/.*\[([^\]]+)\].*/, '\1') }
    expect(container_strings).to include("carton 100")
    expect(container_strings).to include("Volume 36")
    expect(container_strings).to include("Page 36")
    expect(container_strings).to include("Distinc 1")
    enum = Enumeration.find(:name => 'container_type')
    values = EnumerationValue.filter(enumeration_id: enum.id).map {|e| e.value }
    expect(values).to include("Volume")
    expect(values).to include("Page")
    expect(values).to include("Distinc")
  end

  context 'when importing with valid already existing family agents' do
    context 'when provided file is CSV' do
      it 'creates archival object with family agents' do
        csv_template_path = TEMPLATES_DIR + "/bulk_import_template.csv"
        csv_data = CSV.read(csv_template_path)
        expect(csv_data.count).to eq 3
        columns = csv_data[0] # CSV headers
        column_explanations = csv_data[1] # CSV header explanations

        family_agent = create(:json_agent_family, {
          names: [
            build(:json_name_family, {
              family_name: 'Family Agent 1',
              dates: nil,
              prefix: nil,
              sort_name: nil,
              qualifier: nil
            })
          ]
        })

        # Assign data to csv row, in the same a way user would write them
        archival_object_row = {}
        columns.each do |column|
          archival_object_row[column] = nil
        end

        archival_object_row['res_uri'] = @resource.uri
        archival_object_row['title'] = 'Archival Object Title with Family Agent'
        archival_object_row['hierarchy'] = '1'
        archival_object_row['level'] = 'class'

        # Link to existing family agent
        archival_object_row['families_agent_record_id_1'] = family_agent.id
        archival_object_row['families_agent_role_1'] = 'source'
        archival_object_row['families_agent_relator_1'] = 'Actor'

        # Create and link to a family agent
        archival_object_row['families_agent_header_2'] = 'Family Agent 2 to be Created'
        archival_object_row['families_agent_role_2'] = 'source'
        archival_object_row['families_agent_relator_2'] = 'Actor'

        csv_string = CSV.generate(col_sep: ',') do |csv|
          csv << columns
          csv << column_explanations
          csv << archival_object_row.values
        end

        csv_filename = "bulk_import_template_#{@now}_#{SecureRandom.uuid}.csv"
        csv_path = File.join(Dir.tmpdir, csv_filename)
        File.write(csv_path, csv_string)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => csv_filename,
                 :filepath => csv_path,
                 :load_type => "archival_object",
                 :ref_id => "",
                 :aoid => "",
                 :position => "" }
        importer = ImportArchivalObjects.new(opts[:filepath], "csv", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        expect(report.rows[0].errors).to eq([])
        archival_object_id = report.rows[0]['archival_object_id'].split('/').pop
        archival_object = ::ArchivalObject.to_jsonmodel(archival_object_id.to_i)

        expect(archival_object['linked_agents'].length).to eq 2

        expect(archival_object['linked_agents'][0]['agent_family_id']).to eq family_agent.id
        expect(archival_object['linked_agents'][0]['role']).to eq 'source'
        expect(archival_object['linked_agents'][0]['relator']).to eq 'act'
        linked_agent_1 = AgentFamily.to_jsonmodel(archival_object['linked_agents'][0]['agent_family_id'].to_i)
        expect(linked_agent_1['names'][0]['sort_name']).to eq 'Family Agent 1'

        expect(archival_object['linked_agents'][1]['role']).to eq 'source'
        expect(archival_object['linked_agents'][1]['relator']).to eq 'act'
        linked_agent_2 = AgentFamily.to_jsonmodel(archival_object['linked_agents'][1]['agent_family_id'].to_i)
        expect(linked_agent_2['names'][0]['sort_name']).to eq 'Family Agent 2 to be Created'
      end
    end

    context 'when provided file is XSLX' do
      it 'creates archival object with family agents' do
        xlsx_template_path = TEMPLATES_DIR + "/bulk_import_template.xlsx"
        excel_file = RubyXL::Parser.parse(xlsx_template_path)
        sheet = excel_file['Data']

        column_names = sheet[3].cells.map(&:value)

        # Initialize an empty row
        column_names.each do |column|
          column_index = column_names.find_index(column)
          sheet.add_cell(5, column_index, nil)
        end

        family_agent = create(:json_agent_family, {
          names: [
            build(:json_name_family, {
              family_name: 'Family Agent 1',
              dates: nil,
              prefix: nil,
              sort_name: nil,
              qualifier: nil
            })
          ]
        })

        find_index = column_names.find_index('res_uri')
        sheet[5][find_index].change_contents(@resource.uri)
        find_index = column_names.find_index('title')
        sheet[5][find_index].change_contents('Archival Object Title with Family Agent')
        find_index = column_names.find_index('hierarchy')
        sheet[5][find_index].change_contents('1')
        find_index = column_names.find_index('level')
        sheet[5][find_index].change_contents('class')

        # Link to existing family agent
        find_index = column_names.find_index('families_agent_record_id_1')
        sheet[5][find_index].change_contents(family_agent.id)
        find_index = column_names.find_index('families_agent_role_1')
        sheet[5][find_index].change_contents('source')
        find_index = column_names.find_index('families_agent_relator_1')
        sheet[5][find_index].change_contents('Actor')

        # Create and link to a family agent
        find_index = column_names.find_index('families_agent_header_2')
        sheet[5][find_index].change_contents('Family Agent 2 to be Created')

        find_index = column_names.find_index('families_agent_role_2')
        sheet[5][find_index].change_contents('source')

        find_index = column_names.find_index('families_agent_relator_2')
        sheet[5][find_index].change_contents('Actor')

        xlsx_filename = "bulk_import_template_#{@now}_#{SecureRandom.uuid}.xlsx"
        xlsx_path = File.join(Dir.tmpdir, xlsx_filename)
        excel_file.save(xlsx_path)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => xlsx_filename,
                 :filepath => xlsx_path,
                 :load_type => "archival_object",
                 :ref_id => "",
                 :aoid => "",
                 :position => "" }
        importer = ImportArchivalObjects.new(opts[:filepath], "xlsx", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        expect(report.rows[0].errors).to eq([])
        archival_object_id = report.rows[0]['archival_object_id'].split('/').pop
        archival_object = ::ArchivalObject.to_jsonmodel(archival_object_id.to_i)

        expect(archival_object['linked_agents'].length).to eq 2

        expect(archival_object['linked_agents'][0]['agent_family_id']).to eq family_agent.id
        expect(archival_object['linked_agents'][0]['role']).to eq 'source'
        expect(archival_object['linked_agents'][0]['relator']).to eq 'act'
        linked_agent_1 = AgentFamily.to_jsonmodel(archival_object['linked_agents'][0]['agent_family_id'].to_i)
        expect(linked_agent_1['names'][0]['sort_name']).to eq 'Family Agent 1'

        expect(archival_object['linked_agents'][1]['role']).to eq 'source'
        expect(archival_object['linked_agents'][1]['relator']).to eq 'act'
        linked_agent_2 = AgentFamily.to_jsonmodel(archival_object['linked_agents'][1]['agent_family_id'].to_i)
        expect(linked_agent_2['names'][0]['sort_name']).to eq 'Family Agent 2 to be Created'
      end
    end
  end

  context 'when importing with invalid family agents' do
    context 'when provided file is CSV' do
      it 'creates archival object, links only valid family agents, returns errors about invalid family agents' do
        archival_object_count_before = ::ArchivalObject.count

        csv_template_path = TEMPLATES_DIR + "/bulk_import_template.csv"
        csv_data = CSV.read(csv_template_path)
        expect(csv_data.count).to eq 3
        columns = csv_data[0] # CSV headers
        column_explanations = csv_data[1] # CSV header explanations

        family_agent = create(:json_agent_family, {
          names: [
            build(:json_name_family, {
              family_name: 'Family Agent 1',
              dates: nil,
              prefix: nil,
              sort_name: nil,
              qualifier: nil
            })
          ]
        })

        # Assign data to csv row, in the same a way user would write them
        archival_object_row = {}
        columns.each do |column|
          archival_object_row[column] = nil
        end

        archival_object_row['res_uri'] = @resource.uri
        archival_object_row['title'] = 'Archival Object Title with Family Agent'
        archival_object_row['hierarchy'] = '1'
        archival_object_row['level'] = 'class'

        # Link to existing family agent
        archival_object_row['families_agent_record_id_1'] = family_agent.id
        archival_object_row['families_agent_role_1'] = 'INVALID'
        archival_object_row['families_agent_relator_1'] = 'Actor'

        # Create and link to a family agent
        archival_object_row['families_agent_header_2'] = 'Family Agent 2 to be Created'
        archival_object_row['families_agent_role_2'] = 'source'
        archival_object_row['families_agent_relator_2'] = 'Actor'

        csv_string = CSV.generate(col_sep: ',') do |csv|
          csv << columns
          csv << column_explanations
          csv << archival_object_row.values
        end

        csv_filename = "bulk_import_template_#{@now}_#{SecureRandom.uuid}.csv"
        csv_path = File.join(Dir.tmpdir, csv_filename)
        File.write(csv_path, csv_string)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => csv_filename,
                 :filepath => csv_path,
                 :load_type => "archival_object",
                 :ref_id => "",
                 :aoid => "",
                 :position => "" }
        importer = ImportArchivalObjects.new(opts[:filepath], "csv", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        expect(report.rows[0].errors).to eq(["INVALID: linked_agent_role: 'INVALID'. Must be one of: creator, source, subject", "Unable to create agent link: 'INVALID' is not a valid Role"])
        archival_object_id = report.rows[0]['archival_object_id'].split('/').pop
        archival_object = ::ArchivalObject.to_jsonmodel(archival_object_id.to_i)

        archival_object_count_after = ::ArchivalObject.count
        expect(archival_object_count_after).to eq archival_object_count_before + 1

        expect(archival_object['linked_agents'].length).to eq 1
        expect(archival_object['linked_agents'][0]['role']).to eq 'source'
        expect(archival_object['linked_agents'][0]['relator']).to eq 'act'
        linked_agent_2 = AgentFamily.to_jsonmodel(archival_object['linked_agents'][0]['agent_family_id'].to_i)
        expect(linked_agent_2['names'][0]['sort_name']).to eq 'Family Agent 2 to be Created'
      end
    end

    context 'when provided file is XSLX' do
      it 'creates archival object, links only valid family agents, returns errors about invalid family agents' do
        archival_object_count_before = ::ArchivalObject.count

        xlsx_template_path = TEMPLATES_DIR + "/bulk_import_template.xlsx"
        excel_file = RubyXL::Parser.parse(xlsx_template_path)
        sheet = excel_file['Data']

        column_names = sheet[3].cells.map(&:value)

        # Initialize an empty row
        column_names.each do |column|
          column_index = column_names.find_index(column)
          sheet.add_cell(5, column_index, nil)
        end

        family_agent = create(:json_agent_family, {
          names: [
            build(:json_name_family, {
              family_name: 'Family Agent 1',
              dates: nil,
              prefix: nil,
              sort_name: nil,
              qualifier: nil
            })
          ]
        })

        find_index = column_names.find_index('res_uri')
        sheet[5][find_index].change_contents(@resource.uri)
        find_index = column_names.find_index('title')
        sheet[5][find_index].change_contents('Archival Object Title with Family Agent')
        find_index = column_names.find_index('hierarchy')
        sheet[5][find_index].change_contents('1')
        find_index = column_names.find_index('level')
        sheet[5][find_index].change_contents('class')

        # Link to existing family agent
        find_index = column_names.find_index('families_agent_record_id_1')
        sheet[5][find_index].change_contents(family_agent.id)
        find_index = column_names.find_index('families_agent_role_1')
        sheet[5][find_index].change_contents('INVALID')
        find_index = column_names.find_index('families_agent_relator_1')
        sheet[5][find_index].change_contents('Actor')

        # Create and link to a family agent
        find_index = column_names.find_index('families_agent_header_2')
        sheet[5][find_index].change_contents('Family Agent 2 to be Created')

        find_index = column_names.find_index('families_agent_role_2')
        sheet[5][find_index].change_contents('source')

        find_index = column_names.find_index('families_agent_relator_2')
        sheet[5][find_index].change_contents('Actor')

        xlsx_filename = "bulk_import_template_#{@now}_#{SecureRandom.uuid}.xlsx"
        xlsx_path = File.join(Dir.tmpdir, xlsx_filename)
        excel_file.save(xlsx_path)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => xlsx_filename,
                 :filepath => xlsx_path,
                 :load_type => "archival_object",
                 :ref_id => "",
                 :aoid => "",
                 :position => "" }
        importer = ImportArchivalObjects.new(opts[:filepath], "xlsx", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        expect(report.rows[0].errors).to eq(["INVALID: linked_agent_role: 'INVALID'. Must be one of: creator, source, subject", "Unable to create agent link: 'INVALID' is not a valid Role"])
        archival_object_id = report.rows[0]['archival_object_id'].split('/').pop
        archival_object = ::ArchivalObject.to_jsonmodel(archival_object_id.to_i)

        archival_object_count_after = ::ArchivalObject.count
        expect(archival_object_count_after).to eq archival_object_count_before + 1

        expect(archival_object['linked_agents'].length).to eq 1
        expect(archival_object['linked_agents'][0]['role']).to eq 'source'
        expect(archival_object['linked_agents'][0]['relator']).to eq 'act'
        linked_agent_2 = AgentFamily.to_jsonmodel(archival_object['linked_agents'][0]['agent_family_id'].to_i)
        expect(linked_agent_2['names'][0]['sort_name']).to eq 'Family Agent 2 to be Created'
      end
    end
  end

  context 'when import with family valid new agents' do
    context 'when provided file is CSV' do
      it 'creates archival object and placeholder family agents' do
        archival_object_count_before = ::ArchivalObject.count

        csv_template_path = TEMPLATES_DIR + "/bulk_import_template.csv"
        csv_data = CSV.read(csv_template_path)
        expect(csv_data.count).to eq 3
        columns = csv_data[0] # CSV headers
        column_explanations = csv_data[1] # CSV header explanations

        # Assign data to csv row, in the same a way user would write them
        archival_object_row = {}
        columns.each do |column|
          archival_object_row[column] = nil
        end

        archival_object_row['res_uri'] = @resource.uri
        archival_object_row['title'] = 'Archival Object Title with Family Agent'
        archival_object_row['hierarchy'] = '1'
        archival_object_row['level'] = 'class'

        # Provide ids of family agents that do not exist.
        archival_object_row['families_agent_record_id_1'] = '1111'
        archival_object_row['families_agent_record_id_2'] = '2222'

        csv_string = CSV.generate(col_sep: ',') do |csv|
          csv << columns
          csv << column_explanations
          csv << archival_object_row.values
        end

        csv_filename = "bulk_import_template_#{@now}_#{SecureRandom.uuid}.csv"
        csv_path = File.join(Dir.tmpdir, csv_filename)
        File.write(csv_path, csv_string)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => csv_filename,
                 :filepath => csv_path,
                 :load_type => "archival_object",
                 :ref_id => "",
                 :aoid => "",
                 :position => "" }
        importer = ImportArchivalObjects.new(opts[:filepath], "csv", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        expect(report.rows[0].errors).to eq([])
        archival_object_id = report.rows[0]['archival_object_id'].split('/').pop
        archival_object = ::ArchivalObject.to_jsonmodel(archival_object_id.to_i)

        archival_object_count_after = ::ArchivalObject.count
        expect(archival_object_count_after).to eq archival_object_count_before + 1

        expect(archival_object['linked_agents'].length).to eq 2

        expect(archival_object['linked_agents'][0]['role']).to eq 'creator'
        expect(archival_object['linked_agents'][0]['relator']).to eq nil

        expect(archival_object['linked_agents'][1]['role']).to eq 'creator'
        expect(archival_object['linked_agents'][1]['relator']).to eq nil

        linked_agent_1 = AgentFamily.to_jsonmodel(archival_object['linked_agents'][0]['agent_family_id'].to_i)
        linked_agent_2 = AgentFamily.to_jsonmodel(archival_object['linked_agents'][1]['agent_family_id'].to_i)

        expect(linked_agent_1['names'][0]['sort_name']).to eq 'Agent ID 1111 NOT FOUND. This is a PLACEHOLDER'
        expect(linked_agent_2['names'][0]['sort_name']).to eq 'Agent ID 2222 NOT FOUND. This is a PLACEHOLDER'
      end
    end

    context 'when provided file is XSLX' do
      it 'creates archival object and placeholder family agents' do
        archival_object_count_before = ::ArchivalObject.count

        xlsx_template_path = TEMPLATES_DIR + "/bulk_import_template.xlsx"
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
        find_index = column_names.find_index('title')
        sheet[5][find_index].change_contents('Archival Object Title with Family Agent')
        find_index = column_names.find_index('hierarchy')
        sheet[5][find_index].change_contents('1')
        find_index = column_names.find_index('level')
        sheet[5][find_index].change_contents('class')

        find_index = column_names.find_index('families_agent_record_id_1')
        sheet[5][find_index].change_contents('1111')
        find_index = column_names.find_index('families_agent_record_id_2')
        sheet[5][find_index].change_contents('2222')

        xlsx_filename = "bulk_import_template_#{@now}_#{SecureRandom.uuid}.xlsx"
        xlsx_path = File.join(Dir.tmpdir, xlsx_filename)
        excel_file.save(xlsx_path)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => xlsx_filename,
                 :filepath => xlsx_path,
                 :load_type => "archival_object",
                 :ref_id => "",
                 :aoid => "",
                 :position => "" }
        importer = ImportArchivalObjects.new(opts[:filepath], "xlsx", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        expect(report.rows[0].errors).to eq([])
        archival_object_id = report.rows[0]['archival_object_id'].split('/').pop
        archival_object = ::ArchivalObject.to_jsonmodel(archival_object_id.to_i)

        archival_object_count_after = ::ArchivalObject.count
        expect(archival_object_count_after).to eq archival_object_count_before + 1

        expect(archival_object['linked_agents'].length).to eq 2

        expect(archival_object['linked_agents'][0]['role']).to eq 'creator'
        expect(archival_object['linked_agents'][0]['relator']).to eq nil

        expect(archival_object['linked_agents'][1]['role']).to eq 'creator'
        expect(archival_object['linked_agents'][1]['relator']).to eq nil

        linked_agent_1 = AgentFamily.to_jsonmodel(archival_object['linked_agents'][0]['agent_family_id'].to_i)
        linked_agent_2 = AgentFamily.to_jsonmodel(archival_object['linked_agents'][1]['agent_family_id'].to_i)

        expect(linked_agent_1['names'][0]['sort_name']).to eq 'Agent ID 1111 NOT FOUND. This is a PLACEHOLDER'
        expect(linked_agent_2['names'][0]['sort_name']).to eq 'Agent ID 2222 NOT FOUND. This is a PLACEHOLDER'
      end
    end
  end

  context 'when importing with valid digital object file version use statement' do
    context 'when provided file is CSV' do
      it 'successfully parses and transforms digital object file version use statement' do
        archival_object_count_before = ::ArchivalObject.count

        csv_template_path = TEMPLATES_DIR + "/bulk_import_template.csv"
        csv_data = CSV.read(csv_template_path)
        expect(csv_data.count).to eq 3
        columns = csv_data[0] # CSV headers
        column_explanations = csv_data[1] # CSV header explanations

        # Assign data to csv row, in the same a way user would write them
        archival_object_row = {}
        columns.each do |column|
          archival_object_row[column] = nil
        end

        archival_object_row['res_uri'] = @resource.uri
        archival_object_row['title'] = 'Archival Object Title with Family Agent'
        archival_object_row['hierarchy'] = '1'
        archival_object_row['level'] = 'class'

        archival_object_row['digital_object_title'] = 'Digital Object Title'

        archival_object_row['rep_file_uri'] = 'rep-file-uri'
        archival_object_row['rep_use_statement'] = 'application-pdf'

        archival_object_row['nonrep_file_uri'] = 'nonrep-file-uri'
        archival_object_row['nonrep_use_statement'] = 'audio-master' # valid controlled value

        csv_string = CSV.generate(col_sep: ',') do |csv|
          csv << columns
          csv << column_explanations
          csv << archival_object_row.values
        end

        csv_filename = "bulk_import_template_#{@now}_#{SecureRandom.uuid}.csv"
        csv_path = File.join(Dir.tmpdir, csv_filename)
        File.write(csv_path, csv_string)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => csv_filename,
                 :filepath => csv_path,
                 :load_type => "archival_object",
                 :ref_id => "",
                 :aoid => "",
                 :position => "" }
        importer = ImportArchivalObjects.new(opts[:filepath], "csv", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        expect(report.rows[0].errors).to eq([])

        archival_object_count_after = ::ArchivalObject.count
        expect(archival_object_count_after).to eq archival_object_count_before + 1

        archival_object_id = report.rows[0]['archival_object_id'].split('/').pop
        archival_object = ::ArchivalObject.to_jsonmodel(archival_object_id.to_i)

        expect(archival_object['instances'].length).to eq 1
        digitral_object_id = archival_object['instances'][0]['digital_object']['ref'].split('/').pop

        digital_object = ::DigitalObject.to_jsonmodel(digitral_object_id.to_i)

        expect(digital_object['file_versions'].length).to eq 2
        expect(digital_object['file_versions'][0]['use_statement']).to eq 'application-pdf'
        expect(digital_object['file_versions'][1]['use_statement']).to eq 'audio-master'
      end
    end

    context 'when provided file is XSLX' do
      it 'successfully parses and transforms digital object file version use statement' do
        archival_object_count_before = ::ArchivalObject.count

        xlsx_template_path = TEMPLATES_DIR + "/bulk_import_template.xlsx"
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
        find_index = column_names.find_index('title')
        sheet[5][find_index].change_contents('Archival Object Title with Digital Object')
        find_index = column_names.find_index('hierarchy')
        sheet[5][find_index].change_contents('1')
        find_index = column_names.find_index('level')
        sheet[5][find_index].change_contents('class')

        find_index = column_names.find_index('digital_object_title')
        sheet[5][find_index].change_contents('Digital Object Title')

        find_index = column_names.find_index('rep_file_uri')
        sheet[5][find_index].change_contents('file-uri')
        find_index = column_names.find_index('rep_use_statement')
        sheet[5][find_index].change_contents('application-pdf')

        find_index = column_names.find_index('nonrep_file_uri')
        sheet[5][find_index].change_contents('file-uri')
        find_index = column_names.find_index('nonrep_use_statement')
        sheet[5][find_index].change_contents('audio-master') # valid controlled value

        xlsx_filename = "bulk_import_template_#{@now}_#{SecureRandom.uuid}.xlsx"
        xlsx_path = File.join(Dir.tmpdir, xlsx_filename)
        excel_file.save(xlsx_path)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => xlsx_filename,
                 :filepath => xlsx_path,
                 :load_type => "archival_object",
                 :ref_id => "",
                 :aoid => "",
                 :position => "" }
        importer = ImportArchivalObjects.new(opts[:filepath], "xlsx", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        expect(report.rows[0].errors).to eq([])

        archival_object_count_after = ::ArchivalObject.count
        expect(archival_object_count_after).to eq archival_object_count_before + 1

        archival_object_id = report.rows[0]['archival_object_id'].split('/').pop
        archival_object = ::ArchivalObject.to_jsonmodel(archival_object_id.to_i)

        expect(archival_object['instances'].length).to eq 1
        digitral_object_id = archival_object['instances'][0]['digital_object']['ref'].split('/').pop

        digital_object = ::DigitalObject.to_jsonmodel(digitral_object_id.to_i)

        expect(digital_object['file_versions'].length).to eq 2
        expect(digital_object['file_versions'][0]['use_statement']).to eq 'application-pdf'
        expect(digital_object['file_versions'][1]['use_statement']).to eq 'audio-master'
      end
    end
  end

  context 'when importing with invalid digital object file version use statement' do
    context 'when provided file is CSV' do
      it 'creates the AO but no DOs and reports the error' do
        archival_object_count_before = ::ArchivalObject.count
        digital_object_count_before = ::DigitalObject.count

        csv_template_path = TEMPLATES_DIR + "/bulk_import_template.csv"
        csv_data = CSV.read(csv_template_path)
        expect(csv_data.count).to eq 3
        columns = csv_data[0] # CSV headers
        column_explanations = csv_data[1] # CSV header explanations

        # Assign data to csv row, in the same a way user would write them
        archival_object_row = {}
        columns.each do |column|
          archival_object_row[column] = nil
        end

        archival_object_row['res_uri'] = @resource.uri
        archival_object_row['title'] = 'Archival Object Title with Family Agent'
        archival_object_row['hierarchy'] = '1'
        archival_object_row['level'] = 'class'

        archival_object_row['digital_object_title'] = 'Digital Object Title'

        archival_object_row['rep_file_uri'] = 'rep-file-uri'
        archival_object_row['rep_use_statement'] = 'INVALID_REP_USE_STATEMENT' # invalid value, not part of the controlled list

        archival_object_row['nonrep_file_uri'] = 'nonrep-file-uri'
        archival_object_row['nonrep_use_statement'] = 'INVALID_NONREP_USE_STATEMENT'

        csv_string = CSV.generate(col_sep: ',') do |csv|
          csv << columns
          csv << column_explanations
          csv << archival_object_row.values
        end

        csv_filename = "bulk_import_template_#{@now}_#{SecureRandom.uuid}.csv"
        csv_path = File.join(Dir.tmpdir, csv_filename)
        File.write(csv_path, csv_string)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => csv_filename,
                 :filepath => csv_path,
                 :load_type => "archival_object",
                 :ref_id => "",
                 :aoid => "",
                 :position => "" }
        importer = ImportArchivalObjects.new(opts[:filepath], "csv", @current_user, opts)
        report = importer.run

        expect(report.rows[0].errors.length).to eq 3

        rep_use_statement_error = "Cannot create the digital object INVALID: file_version_use_statement: 'INVALID_REP_USE_STATEMENT'. Must be one of: application, application-pdf, audio-clip, audio-master, audio-master-edited, audio-service, image-master, image-master-edited, image-service, image-service-edited, image-thumbnail, test-data, text-codebook, text-data_definition, text-georeference, text-ocr-edited, text-ocr-unedited, text-tei-transcripted, text-tei-translated, video-clip, video-master, video-master-edited, video-service, video-streaming"

        nonrep_use_statement_error = "Cannot create the digital object INVALID: file_version_use_statement: 'INVALID_NONREP_USE_STATEMENT'. Must be one of: application, application-pdf, audio-clip, audio-master, audio-master-edited, audio-service, image-master, image-master-edited, image-service, image-service-edited, image-thumbnail, test-data, text-codebook, text-data_definition, text-georeference, text-ocr-edited, text-ocr-unedited, text-tei-transcripted, text-tei-translated, video-clip, video-master, video-master-edited, video-service, video-streaming"

        expect(report.rows[0].errors).to include(rep_use_statement_error, nonrep_use_statement_error)

        expect(::ArchivalObject.count).to eq archival_object_count_before + 1
        expect(::DigitalObject.count).to eq digital_object_count_before
      end
    end

    context 'when provided file is XSLX' do
      it 'creates the AO but no DOs and reports the error' do
        archival_object_count_before = ::ArchivalObject.count
        digital_object_count_before = ::DigitalObject.count

        xlsx_template_path = TEMPLATES_DIR + "/bulk_import_template.xlsx"
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
        find_index = column_names.find_index('title')
        sheet[5][find_index].change_contents('Archival Object Title with Digital Object')
        find_index = column_names.find_index('hierarchy')
        sheet[5][find_index].change_contents('1')
        find_index = column_names.find_index('level')
        sheet[5][find_index].change_contents('class')

        find_index = column_names.find_index('digital_object_title')
        sheet[5][find_index].change_contents('Digital Object Title')

        find_index = column_names.find_index('rep_file_uri')
        sheet[5][find_index].change_contents('rep-file-uri')
        find_index = column_names.find_index('rep_use_statement')
        sheet[5][find_index].change_contents('INVALID_REP_USE_STATEMENT')

        find_index = column_names.find_index('nonrep_file_uri')
        sheet[5][find_index].change_contents('nonrep-file-uri')
        find_index = column_names.find_index('nonrep_use_statement')
        sheet[5][find_index].change_contents('INVALID_NONREP_USE_STATEMENT')

        xlsx_filename = "bulk_import_template_#{@now}_#{SecureRandom.uuid}.xlsx"
        xlsx_path = File.join(Dir.tmpdir, xlsx_filename)
        excel_file.save(xlsx_path)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => xlsx_filename,
                 :filepath => xlsx_path,
                 :load_type => "archival_object",
                 :ref_id => "",
                 :aoid => "",
                 :position => "" }
        importer = ImportArchivalObjects.new(opts[:filepath], "xlsx", @current_user, opts)
        report = importer.run

        expect(report.rows[0].errors.length).to eq(3)
        rep_use_statement_error = "Cannot create the digital object INVALID: file_version_use_statement: 'INVALID_REP_USE_STATEMENT'. Must be one of: application, application-pdf, audio-clip, audio-master, audio-master-edited, audio-service, image-master, image-master-edited, image-service, image-service-edited, image-thumbnail, test-data, text-codebook, text-data_definition, text-georeference, text-ocr-edited, text-ocr-unedited, text-tei-transcripted, text-tei-translated, video-clip, video-master, video-master-edited, video-service, video-streaming"

        non_rep_use_statement_error = "Cannot create the digital object INVALID: file_version_use_statement: 'INVALID_NONREP_USE_STATEMENT'. Must be one of: application, application-pdf, audio-clip, audio-master, audio-master-edited, audio-service, image-master, image-master-edited, image-service, image-service-edited, image-thumbnail, test-data, text-codebook, text-data_definition, text-georeference, text-ocr-edited, text-ocr-unedited, text-tei-transcripted, text-tei-translated, video-clip, video-master, video-master-edited, video-service, video-streaming"


        expect(report.rows[0].errors).to include(rep_use_statement_error, non_rep_use_statement_error)

        archival_object_count_after = ::ArchivalObject.count
        digital_object_count_after = ::DigitalObject.count
        expect(archival_object_count_after).to eq archival_object_count_before + 1
        expect(digital_object_count_after).to eq digital_object_count_before
      end
    end
  end

  context 'when importing with valid digital object file version file format name' do
    context 'when provided file is CSV' do
      it 'successfully creates archival object with digital object file version file format name' do
        archival_object_count_before = ::ArchivalObject.count
        digital_object_count_before = ::DigitalObject.count

        csv_template_path = TEMPLATES_DIR + "/bulk_import_template.csv"
        csv_data = CSV.read(csv_template_path)
        expect(csv_data.count).to eq 3
        columns = csv_data[0] # CSV headers
        column_explanations = csv_data[1] # CSV header explanations

        # Assign data to csv row, in the same a way user would write them
        archival_object_row = {}
        columns.each do |column|
          archival_object_row[column] = nil
        end

        archival_object_row['res_uri'] = @resource.uri
        archival_object_row['title'] = 'Archival Object Title with Family Agent'
        archival_object_row['hierarchy'] = '1'
        archival_object_row['level'] = 'class'

        archival_object_row['digital_object_title'] = 'Digital Object Title'

        archival_object_row['rep_file_uri'] = 'rep-file-uri'
        archival_object_row['rep_file_format'] = 'aiff'

        archival_object_row['nonrep_file_uri'] = 'nonrep-file-uri'
        archival_object_row['nonrep_file_format'] = 'avi'

        csv_string = CSV.generate(col_sep: ',') do |csv|
          csv << columns
          csv << column_explanations
          csv << archival_object_row.values
        end

        csv_filename = "bulk_import_template_#{@now}_#{SecureRandom.uuid}.csv"
        csv_path = File.join(Dir.tmpdir, csv_filename)
        File.write(csv_path, csv_string)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => csv_filename,
                 :filepath => csv_path,
                 :load_type => "archival_object",
                 :ref_id => "",
                 :aoid => "",
                 :position => "" }
        importer = ImportArchivalObjects.new(opts[:filepath], "csv", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        expect(report.rows[0].errors).to eq([])

        archival_object_count_after = ::ArchivalObject.count
        digital_object_count_after = ::DigitalObject.count
        expect(archival_object_count_after).to eq archival_object_count_before + 1
        expect(digital_object_count_after).to eq digital_object_count_before + 1

        archival_object_id = report.rows[0]['archival_object_id'].split('/').pop
        archival_object = ::ArchivalObject.to_jsonmodel(archival_object_id.to_i)

        expect(archival_object['instances'].length).to eq 1
        digitral_object_id = archival_object['instances'][0]['digital_object']['ref'].split('/').pop

        digital_object = ::DigitalObject.to_jsonmodel(digitral_object_id.to_i)

        expect(digital_object['file_versions'].length).to eq 2
        expect(digital_object['file_versions'][0]['file_format_name']).to eq 'aiff'
        expect(digital_object['file_versions'][1]['file_format_name']).to eq 'avi'

        archival_object_count_after = ::ArchivalObject.count
        digital_object_count_after = ::DigitalObject.count
        expect(archival_object_count_after).to eq archival_object_count_before + 1
        expect(digital_object_count_after).to eq digital_object_count_before + 1
      end
    end

    context 'when provided file is XSLX' do
      it 'successfully creates archival object with digital object file version file format name' do
        archival_object_count_before = ::ArchivalObject.count
        digital_object_count_before = ::DigitalObject.count

        xlsx_template_path = TEMPLATES_DIR + "/bulk_import_template.xlsx"
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
        find_index = column_names.find_index('title')
        sheet[5][find_index].change_contents('Archival Object Title with Digital Object')
        find_index = column_names.find_index('hierarchy')
        sheet[5][find_index].change_contents('1')
        find_index = column_names.find_index('level')
        sheet[5][find_index].change_contents('class')

        find_index = column_names.find_index('digital_object_title')
        sheet[5][find_index].change_contents('Digital Object Title')

        find_index = column_names.find_index('rep_file_uri')
        sheet[5][find_index].change_contents('rep-file-uri')
        find_index = column_names.find_index('rep_file_format')
        sheet[5][find_index].change_contents('aiff')

        find_index = column_names.find_index('nonrep_file_uri')
        sheet[5][find_index].change_contents('nonrep-file-uri')
        find_index = column_names.find_index('nonrep_file_format')
        sheet[5][find_index].change_contents('avi')

        xlsx_filename = "bulk_import_template_#{@now}_#{SecureRandom.uuid}.xlsx"
        xlsx_path = File.join(Dir.tmpdir, xlsx_filename)
        excel_file.save(xlsx_path)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => xlsx_filename,
                 :filepath => xlsx_path,
                 :load_type => "archival_object",
                 :ref_id => "",
                 :aoid => "",
                 :position => "" }
        importer = ImportArchivalObjects.new(opts[:filepath], "xlsx", @current_user, opts)
        report = importer.run

        expect(report.terminal_error).to eq(nil)
        expect(report.row_count).to eq(1)
        expect(report.rows[0].errors).to eq([])

        archival_object_count_after = ::ArchivalObject.count
        digital_object_count_after = ::DigitalObject.count
        expect(archival_object_count_after).to eq archival_object_count_before + 1
        expect(digital_object_count_after).to eq digital_object_count_before + 1

        archival_object_id = report.rows[0]['archival_object_id'].split('/').pop
        archival_object = ::ArchivalObject.to_jsonmodel(archival_object_id.to_i)

        expect(archival_object['instances'].length).to eq 1
        digitral_object_id = archival_object['instances'][0]['digital_object']['ref'].split('/').pop

        digital_object = ::DigitalObject.to_jsonmodel(digitral_object_id.to_i)

        expect(digital_object['file_versions'].length).to eq 2
        expect(digital_object['file_versions'][0]['file_format_name']).to eq 'aiff'
        expect(digital_object['file_versions'][1]['file_format_name']).to eq 'avi'
      end
    end
  end

  context 'when import with invalid digital object file version file format name' do
    context 'when provided file is CSV' do
      it 'creates the archival object, does not create any digital objects and reports an error' do
        archival_object_count_before = ::ArchivalObject.count
        digital_object_count_before = ::DigitalObject.count

        csv_template_path = TEMPLATES_DIR + "/bulk_import_template.csv"
        csv_data = CSV.read(csv_template_path)
        expect(csv_data.count).to eq 3
        columns = csv_data[0] # CSV headers
        column_explanations = csv_data[1] # CSV header explanations

        # Assign data to csv row, in the same a way user would write them
        archival_object_row = {}
        columns.each do |column|
          archival_object_row[column] = nil
        end

        archival_object_row['res_uri'] = @resource.uri
        archival_object_row['title'] = 'Archival Object Title with Family Agent'
        archival_object_row['hierarchy'] = '1'
        archival_object_row['level'] = 'class'

        archival_object_row['digital_object_title'] = 'Digital Object Title'

        archival_object_row['rep_file_uri'] = 'rep-file-uri'
        archival_object_row['rep_file_format'] = 'INVALID_REP_FILE_FORMAT'

        archival_object_row['nonrep_file_uri'] = 'nonrep-file-uri'
        archival_object_row['nonrep_file_format'] = 'INVALID_NONREP_FILE_FORMAT'

        csv_string = CSV.generate(col_sep: ',') do |csv|
          csv << columns
          csv << column_explanations
          csv << archival_object_row.values
        end

        csv_filename = "bulk_import_template_#{@now}_#{SecureRandom.uuid}.csv"
        csv_path = File.join(Dir.tmpdir, csv_filename)
        File.write(csv_path, csv_string)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => csv_filename,
                 :filepath => csv_path,
                 :load_type => "archival_object",
                 :ref_id => "",
                 :aoid => "",
                 :position => "" }
        importer = ImportArchivalObjects.new(opts[:filepath], "csv", @current_user, opts)
        report = importer.run

        expect(report.rows[0].errors.length).to eq 3

        rep_file_format_error = "Cannot create the digital object INVALID: file_version_file_format_name: 'INVALID_REP_FILE_FORMAT'. Must be one of: aiff, avi, gif, jpeg, mp3, pdf, tiff, txt"
        nonrep_file_format_error = "Cannot create the digital object INVALID: file_version_file_format_name: 'INVALID_REP_FILE_FORMAT'. Must be one of: aiff, avi, gif, jpeg, mp3, pdf, tiff, txt"
        expect(report.rows[0].errors).to include(rep_file_format_error, nonrep_file_format_error)

        expect(::ArchivalObject.count).to eq archival_object_count_before + 1
        expect(::DigitalObject.count).to eq digital_object_count_before
      end
    end

    context 'when provided file is XSLX' do
      it 'creates the archival object, does not create any digital objects and reports an error' do
        archival_object_count_before = ::ArchivalObject.count
        digital_object_count_before = ::DigitalObject.count

        xlsx_template_path = TEMPLATES_DIR + "/bulk_import_template.xlsx"
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
        find_index = column_names.find_index('title')
        sheet[5][find_index].change_contents('Archival Object Title with Digital Object')
        find_index = column_names.find_index('hierarchy')
        sheet[5][find_index].change_contents('1')
        find_index = column_names.find_index('level')
        sheet[5][find_index].change_contents('class')

        find_index = column_names.find_index('digital_object_title')
        sheet[5][find_index].change_contents('Digital Object Title')

        find_index = column_names.find_index('rep_file_uri')
        sheet[5][find_index].change_contents('rep-file-uri')
        find_index = column_names.find_index('rep_file_format')
        sheet[5][find_index].change_contents('INVALID_REP_FILE_FORMAT')

        find_index = column_names.find_index('nonrep_file_uri')
        sheet[5][find_index].change_contents('nonrep-file-uri')
        find_index = column_names.find_index('nonrep_file_format')
        sheet[5][find_index].change_contents('INVALID_NONREP_FILE_FORMAT')

        xlsx_filename = "bulk_import_template_#{@now}_#{SecureRandom.uuid}.xlsx"
        xlsx_path = File.join(Dir.tmpdir, xlsx_filename)
        excel_file.save(xlsx_path)

        opts = { :repo_id => @resource[:repo_id],
                 :rid => @resource[:id],
                 :type => "resource",
                 :filename => xlsx_filename,
                 :filepath => xlsx_path,
                 :load_type => "archival_object",
                 :ref_id => "",
                 :aoid => "",
                 :position => "" }
        importer = ImportArchivalObjects.new(opts[:filepath], "xlsx", @current_user, opts)
        report = importer.run

        expect(report.rows[0].errors.length).to eq 3
        rep_file_format_error = "Cannot create the digital object INVALID: file_version_file_format_name: 'INVALID_REP_FILE_FORMAT'. Must be one of: aiff, avi, gif, jpeg, mp3, pdf, tiff, txt"
        nonrep_file_format_error = "Cannot create the digital object INVALID: file_version_file_format_name: 'INVALID_REP_FILE_FORMAT'. Must be one of: aiff, avi, gif, jpeg, mp3, pdf, tiff, txt"
        expect(report.rows[0].errors).to include(rep_file_format_error, nonrep_file_format_error)

        expect(::ArchivalObject.count).to eq archival_object_count_before + 1
        expect(::DigitalObject.count).to eq digital_object_count_before
      end
    end
  end
end
