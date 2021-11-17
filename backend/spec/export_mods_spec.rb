require_relative 'export_spec_helper'

# Background: These specs are the result of an attempt to interpret
# mappings included in documentation for the Archivists' Toolkit.
# Where it was  possible to do so, they have been transposed from a
# file downloaded from:
# http://archiviststoolkit.org/sites/default/files/ATexports_2008_10_08.xls

describe "Exported MODS metadata" do

  before(:all) do
    as_test_user('admin', true) do
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

      @agent_corporation = create(:json_agent_corporate_entity,
                                  :names => [build(:json_name_corporate_entity,
                                      :authority_id => rand(1000000).to_s
                                    )]
                                  )

      @subject_person = create(:json_agent_person)

      @subjects = (0..7).map { create(:json_subject) }

      # ensure at least one subject will be of type 'technique' and 'function'
      @subjects[6]['term_type'] = 'technique'
      @subjects[7]['term_type'] = 'function'

      linked_agents = [{
                         :role => 'creator',
                         :ref => @agent_person.uri
                       },
                       {
                         :role => 'creator',
                         :ref => @agent_corporation.uri
                       },
                       {
                         :role => 'subject',
                         :ref => @subject_person.uri
                       }]

      linked_subjects = @subjects.map {|s| {:ref => s.uri} }

      notes = digital_object_note_set + [build(:json_note_bibliography)]

      dates = [
        {"label" => "creation", "expression" => "1970s-ish", "certainty" => "questionable", "date_type" => "bulk"},
        {"label" => "digitized", "begin" => "10-10-2018", "certainty" => "inferred", "date_type" => "bulk"},
        {"label" => "copyright", "begin" => "10-10-1998", "end" => "10-10-2008", "certainty" => "approximate", "date_type" => "bulk"},
        {"label" => "modified", "expression" => "Last week", "certainty" => "approximate", "date_type" => "bulk"},
        {"label" => "broadcast", "begin" => "04-01-2018", "date_type" => "bulk"},
        {"label" => "issued", "begin" => "05-01-2018", "date_type" => "bulk"},
        {"label" => "publication", "begin" => "06-01-2018", "date_type" => "bulk"},
        {"label" => "other", "begin" => "07-01-2018", "date_type" => "bulk"},
      ]

      @digital_object = create(:json_digital_object,
                               :linked_agents => linked_agents,
                               :subjects => linked_subjects,
                               :digital_object_type => "notated_music",
                               :lang_materials => [build(:json_lang_material),
                                                   build(:json_lang_material),
                                                   build(:json_lang_material_with_note)],
                               :dates => dates,
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


      @mods = get_mods(@digital_object)
      raise Sequel::Rollback
    end
  end


  after(:all) do
    as_test_user('admin') do
      $repo_id = $old_repo_id
      JSONModel.set_repository($repo_id)
    end
  end


  describe "names" do

    it "maps each name to a name tag" do
      @agent_person.names.each do |name|
        expect(@mods).to have_tag "mods/name[@type='personal'][@authority='#{name['source']}']/namePart[@type='family']" => name['primary_name']
      end
    end


    it "creates a role for each name" do
      expect(@mods).to have_tag "mods/name[@type='personal']/role/roleTerm[@type='text'][@authority='marcrelator']" => "creator"
    end

    it "should put authority_id and source in the name tag for corporate agents" do
      authority_id = @agent_corporation['names'][0]['authority_id']
      source       = @agent_corporation['names'][0]['source']
      expect(@mods).to have_tag "name[@type='corporate'][@valueURI='#{authority_id}'][@authority='#{source}']"
    end
  end


  describe "names of subjects" do

    it "wraps agents related as subjects in a subject tag" do
      expect(@mods).to have_tag "mods/subject/name/namePart" => @subject_person.names[0]['primary_name']
    end

  end


  describe "subjects" do

    it "maps each subject to a subject tag" do
      @subjects.each do |subject|
        expect(@mods).to have_tag "mods/subject[@authority='#{subject['source']}']"
        subject['terms'].each do |term|
          case term['term_type']
          when 'geographic', 'cultural_context'
            expect(@mods).to have_tag "subject/geographic" => term['term']
          when 'temporal'
            expect(@mods).to have_tag "subject/temporal" => term['term']
          when 'uniform_title'
            expect(@mods).to have_tag "subject/titleInfo" => term['term']
          when 'genre_form', 'style_period', 'technique', 'function'
            expect(@mods).to have_tag "subject/genre" => term['term']
          when 'occupation'
            expect(@mods).to have_tag "subject/occupation" => term['term']
          else
            expect(@mods).to have_tag "subject/topic" => term['term']
          end
        end
      end
    end
  end

  describe "dates" do
    it "maps to dateCreated (expression date)" do
      expect(@mods).to have_tag "dateCreated" => "1970s-ish"
    end

    it "maps to dateIssued (begin only)" do
      expect(@mods).to have_tag "dateIssued[@point='start']" => "04-01-2018"
      expect(@mods).to have_tag "dateIssued[@point='start']" => "05-01-2018"
      expect(@mods).to have_tag "dateIssued[@point='start']" => "06-01-2018"
    end

    it "maps to dateCaptured (begin only)" do
      expect(@mods).to have_tag "dateIssued[@point='start']" => "06-01-2018"
    end

    it "maps to copyrightDate as two tags with start and end" do
      expect(@mods).to have_tag "copyrightDate[@point='start']" => "10-10-1998"
      expect(@mods).to have_tag "copyrightDate[@point='end']" => "10-10-2008"
    end

    it "maps to dateModified (expression date)" do
      expect(@mods).to have_tag "dateModified" => "Last week"
    end

    it "maps to dateOther (begin only)" do
      expect(@mods).to have_tag "dateOther[@point='start']" => "07-01-2018"
    end

    it "should to correct qualifier tag" do
      expect(@mods).to have_tag "dateCreated[@qualifier='questionable']"
      expect(@mods).to have_tag "dateCaptured[@qualifier='inferred']"
      expect(@mods).to have_tag "copyrightDate[@qualifier='approximate']"
    end

    it "should set encoding, keyDate attributes correctly" do
      expect(@mods).to have_tag "dateCaptured[@encoding='w3cdtf'][@keyDate='yes']"
      expect(@mods).to have_tag "copyrightDate[@encoding='w3cdtf'][@keyDate='yes']"
      expect(@mods).to have_tag "dateIssued[@encoding='w3cdtf'][@keyDate='yes']"
      expect(@mods).to have_tag "dateOther[@encoding='w3cdtf'][@keyDate='yes']"

      # expression dates should not have encoding, keydate or point attrs
      expect(@mods).not_to have_tag "dateCreated[@encoding='w3cdtf']"
      expect(@mods).not_to have_tag "dateCreated[@keyDate='yes']"
      expect(@mods).not_to have_tag "dateCreated[@point]"

      expect(@mods).not_to have_tag "dateModified[@encoding='w3cdtf']"
      expect(@mods).not_to have_tag "dateModified[@keyDate='yes']"
      expect(@mods).not_to have_tag "dateModified[@point]"
    end
  end

  describe "extents" do
    it "should export extents in a physicalDescription/extent tag" do
      expect(@mods).to have_tag "physicalDescription/extent" => @digital_object['extents'][0]['number'] + " " + @digital_object['extents'][0]['extent_type']
    end

    it "should map contents of extent['dimensions'] to a note tag" do
      expect(@mods).to have_tag "physicalDescription/note[@type='dimensions'][@displayLabel='Dimensions']" => @digital_object['extents'][0]['dimensions']
    end

    it "should map contents of extent['physical_details'] to a note tag" do
      expect(@mods).to have_tag "physicalDescription/note[@type='physical_description'][@displayLabel='Physical Details']" => @digital_object['extents'][0]['physical_details']
    end
  end

  describe "mods_inner" do
    it "creates an identifier tag for the digitial object id" do
      expect(@mods).to have_tag "identifier" => @digital_object['digital_object_id']
    end

    it "creates a typeOfResource tag for the digital object type" do
      expect(@mods).to have_tag "typeOfResource" => I18n.t("enumerations.digital_object_digital_object_type." + @digital_object['digital_object_type'])
    end

    it "creates a language/languageTerm tag for each language term" do
      language_vals = @digital_object.lang_materials.map {|l| l['language_and_script']}.compact
      language_vals.each do |language|
        language = language['language']
        expect(@mods).to have_tag "language/languageTerm[@type='text'][@authority='iso639-2b']" => I18n.t("enumerations.language_iso639_2." + language)
      end
    end

    it "creates a language/languageTerm tag for each language code" do
      language_vals = @digital_object.lang_materials.map {|l| l['language_and_script']}.compact
      language_vals.each do |language|
        language = language['language']
        expect(@mods).to have_tag "language/languageTerm[@type='code'][@authority='iso639-2b']" => language
      end
    end

    it "creates a language/scriptTerm tag for each script term" do
      language_vals = @digital_object.lang_materials.map {|l| l['language_and_script']}.compact
      language_vals.each do |language|
        script = language['script']
        expect(@mods).to have_tag "language/scriptTerm[@type='text'][@authority='iso15924']" => I18n.t("enumerations.script_iso15924." + script)
      end
    end

    it "creates a language/scriptTerm tag for each script code" do
      language_vals = @digital_object.lang_materials.map {|l| l['language_and_script']}.compact
      language_vals.each do |language|
        script = language['script']
        expect(@mods).to have_tag "language/scriptTerm[@type='code'][@authority='iso15924']" => script
      end
    end

    it "creates a note tag for each language note" do
      language_notes = @digital_object.lang_materials.map {|l| l['notes']}.compact.reject {|e| e == [] }.flatten
      language_notes.each do |note|
        content = note_content(note)
        expect(@mods).to have_tag "note[@type='language']" => content
      end
    end

    it "does not create a language/languageTerm tag if language is not specified" do
      digital_object = create(:json_digital_object,
                              :lang_materials => nil,
                              :digital_object_type => "notated_music")

      mods = get_mods(digital_object)
      expect(mods).not_to have_tag "language/languageTerm"
    end
  end


  describe "notes" do

    it "maps each note to the right type of tag" do
      @digital_object.notes.each do |note|
        content = note_content(note)
        case note['type']
        when 'abstract', 'scopecontent'
          expect(@mods).to have_tag "abstract" => content
        when 'bioghist', 'odd'
          expect(@mods).to have_tag "note" => content
        when 'acquinfo'
          expect(@mods).to have_tag "note[@type='acquisition']" => content
        when 'citation'
          expect(@mods).to have_tag "note[@type='citation']" => content
        when 'accessrestrict'
          expect(@mods).to have_tag "accessCondition[@type='restrictionOnAccess']" => content
        when 'userestrict'
          expect(@mods).to have_tag "accessCondition[@type='useAndReproduction']" => content
        when 'legalstatus'
          expect(@mods).to have_tag "accessCondition" => content
        when 'physdesc'
          expect(@mods).to have_tag "physicalDescription/note[@type='physical_description'][@displayLabel='Physical Details']" => content
        when 'dimensions'
          expect(@mods).to have_tag "physicalDescription/note[@type='dimensions'][@displayLabel='Dimensions']" => content
        end
      end
    end


    it "maps repository information to a note" do
      note_content = [
                      @repo.name,
                      @repo_contact.address_1,
                      @repo_contact.address_2,
                      @repo_contact.address_3,
                      @repo_contact.city,
                      @repo_contact.region,
                      @repo_contact.post_code,
                      @repo_contact.country].compact.join(', ')
      note_content << " (#{@repo.url})" if @repo.url

      expect(@mods).to have_tag "note[@displayLabel='Digital object made available by']" => note_content
    end
  end


  describe "related items" do

    it "maps each digital object component to a related item" do
      expect(@mods).to have_tag "relatedItem[@type='constituent'][#{@components.count}]"
      expect(@mods).not_to have_tag "relatedItem[@type='constituent'][#{@components.count + 1}]"
    end
  end
end

describe "unpublished extent notes" do
  before(:all) do
    as_test_user('admin') do
      notes = unpublished_extent_note_set
      @dimension_note = notes.select {|n| n['type'] == 'dimensions' }
      @physdesc_note = notes.select {|n| n['type'] == 'physdesc' }

      @digital_object_unpub = create(:json_digital_object,
                                      :notes => notes)

      @mods = get_mods(@digital_object_unpub)
    end
  end

  after(:all) do
    as_test_user('admin') do
      $repo_id = $old_repo_id
      JSONModel.set_repository($repo_id)
    end
  end

  it "should not export extent notes if unpublished" do
    expect(@mods).not_to have_tag "physicalDescription/note[@type='dimensions'][@displayLabel='Dimensions']" => note_content(@dimension_note[0])
  end

  it "should not export physical_description note if it is unpublished" do
    expect(@mods).not_to have_tag "physicalDescription/note[@type='physical_description'][@displayLabel='Physical Details']" => note_content(@physdesc_note[0])
  end
end
