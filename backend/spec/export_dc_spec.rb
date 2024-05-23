require_relative 'export_spec_helper'

# Background: These specs are the result of an attempt to interpret
# mappings included in documentation for the Archivists' Toolkit.
# Where it was  possible to do so, they have been transposed from a
# file downloaded from:
# http://archiviststoolkit.org/sites/default/files/ATexports_2008_10_08.xls

describe "Exported Dublin Core metadata" do

  before(:all) do
    as_test_user('admin') do
      @repo_contact = build(:json_agent_contact)
      @repo_agent = build(:json_agent_corporate_entity,
                           :agent_contacts => [@repo_contact])

      @repo = build(:json_repository)

      @repo_with_agent = create(:json_repository_with_agent,
                                :repository => @repo,
                                :agent_representation => @repo_agent)

      $old_repo_id = $repo_id
      $repo_id = @repo_with_agent.id
      JSONModel.set_repository(@repo_with_agent.id)

      names = (0..5).map { build(:json_name_person) }
      @agent_person = create(:json_agent_person,
                             :names => names)

      @subject_person = create(:json_agent_person)

      @subjects = (0..5).map { create(:json_subject) }

      linked_agents = [{
                         :role => 'creator',
                         :ref => @agent_person.uri
                       },
                       {
                         :role => 'subject',
                         :ref => @subject_person.uri
                       }]

      linked_subjects = @subjects.map {|s| {:ref => s.uri} }

      notes = digital_object_note_set + [build(:json_note_bibliography)]

      dates = (0..5).map { build(:json_date) }

      @digital_object = create(:json_digital_object,
                               :linked_agents => linked_agents,
                               :subjects => linked_subjects,
                               :dates => dates,
                               :lang_materials => [build(:json_lang_material),
                                                   build(:json_lang_material),
                                                   build(:json_lang_material_with_note)],
                               :notes => notes)

      use_statements = []

      10.times {
        use_statements << generate(:use_statement)
      }

      # ensure one duplicate value
      use_statements << use_statements.last.clone

      @file_versions = use_statements.map {|us| build(:json_file_version, :use_statement => us)}

      @components = []
      # a child with a file version
      @components << create(:json_digital_object_component,
                            :digital_object => {:ref => @digital_object.uri},
                            :file_versions => @file_versions[6..7])

      # a grandchild with no file version
      @components << create(:json_digital_object_component,
                            :digital_object => {:ref => @digital_object.uri},
                            :parent => {:ref => @components[0].uri},
                            :file_versions => @file_versions[8..-1])


      @dc = get_dc(@digital_object)

    end
  end


  after(:all) do
    as_test_user('admin') do
      @digital_object.delete
      @components.each do |c|
        c.delete
      end

      [@agent_person, @subject_person, @subjects].flatten.each do |rec|
        rec.delete
      end

      $repo_id = $old_repo_id
      JSONModel.set_repository($repo_id)
    end
  end


  it "has the correct namespaces" do
    expect(@dc).to have_namespaces({
                                   "xmlns" => "http://purl.org/dc/elements/1.1/",
                                   "xmlns:dcterms" => "http://purl.org/dc/terms/",
                                   "xmlns:xlink" => "http://www.w3.org/1999/xlink",
                                   "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance"
                                 })
  end


  it "points to the right schemas" do
    schema_locations = "http://purl.org/dc/elements/1.1/ https://dublincore.org/schemas/xmls/qdc/2006/01/06/dc.xsd http://purl.org/dc/terms/ https://dublincore.org/schemas/xmls/qdc/2006/01/06/dcterms.xsd".split(" ").sort.join(" ")
    expect(@dc.xpath("xmlns:dc", @dc.namespaces).attr("xsi:schemaLocation").value.split(" ").sort.join(" ")).to eq(schema_locations)
  end


  describe "Dublin Core mappings" do

    it "maps lang_materials['language_and_script'] to language" do
      language_vals = @digital_object.lang_materials.map {|l| l['language_and_script']}.compact
      language_vals.each do |language|
        lang_val = language['language']
        expect(@dc).to have_tag "dc/language" => lang_val
        script = language['script']
        expect(@dc).to have_tag "dc/language" => script
      end
    end


    it "maps lang_materials['notes'] to language" do
      language_notes = @digital_object.lang_materials.map {|l| l['notes']}.compact.reject {|e| e == [] }.flatten
      language_notes.each do |note|
        expect(@dc).to have_tag "dc/language" => note_content(note)
      end
    end

    it "maps to identifier" do
      pending "missing test"
      expect(false).to eq(true)
    end

    it "maps dates to date" do
      @digital_object.dates.each do |date|
        date_value = date['expression'] ? date['expression'] : [date['begin'], date['end']].compact.join(" - ")
        expect(@dc).to have_tag "dc/date" => date_value
      end
    end


    it "maps creator agent to creator" do
      @agent_person.names.each do |name|
        expect(@dc).to have_tag "dc/creator" => name['sort_name']
      end
    end


    it "maps subject agent to subject" do
      @subject_person.names.each do |name|
        expect(@dc).to have_tag "dc/subject" => name['sort_name']
      end
    end


    it "maps note of type bioghist to description" do
      bioghist_note = get_notes_by_type(@digital_object, 'bioghist')[0]
      expect(@dc).to have_tag "dc/description" => note_content(bioghist_note)
    end


    it "maps note of type prefercite to description" do
      prefercite_note = get_notes_by_type(@digital_object, 'prefercite')[0]
      expect(@dc).to have_tag "dc/description" => note_content(prefercite_note)
    end


    it "maps note of type accessrestrict to rights" do
      accessrestrict_note = get_notes_by_type(@digital_object, 'accessrestrict')[0]
      expect(@dc).to have_tag "dc/rights" => note_content(accessrestrict_note)
    end


    it "maps note of type userestrict to rights" do
      userrestrict_note = get_notes_by_type(@digital_object, 'userestrict')[0]
      expect(@dc).to have_tag "dc/rights" => note_content(userrestrict_note)
    end


    it "maps note of type dimensions to format" do
      userrestrict_note = get_notes_by_type(@digital_object, 'dimensions')[0]
      expect(@dc).to have_tag "dc/format" => note_content(userrestrict_note)
    end


    it "maps note of type physdesc to format" do
      userrestrict_note = get_notes_by_type(@digital_object, 'physdesc')[0]
      expect(@dc).to have_tag "dc/format" => note_content(userrestrict_note)
    end


    it "maps note of type originalsloc to source" do
      userrestrict_note = get_notes_by_type(@digital_object, 'originalsloc')[0]
      expect(@dc).to have_tag "dc/source" => note_content(userrestrict_note)
    end


    it "maps note of type relatedmaterial to relation" do
      userrestrict_note = get_notes_by_type(@digital_object, 'relatedmaterial')[0]
      expect(@dc).to have_tag "dc/relation" => note_content(userrestrict_note)
    end


    it "maps repository info to description" do
      repo_info = "Digital object made available by #{@repo.name} (#{@repo.url})"
      expect(@dc).to have_tag "dc/description" => repo_info
    end

  end

end
