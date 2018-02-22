require_relative 'export_spec_helper'

# Background: These specs are the result of an attempt to interpret
# mappings included in documentation for the Archivists' Toolkit.
# Where it was  possible to do so, they have been transposed from a
# file downloaded from:
# http://archiviststoolkit.org/sites/default/files/ATexports_2008_10_08.xls

describe "Exported MODS metadata" do

  before(:all) do
    @repo_contact = build(:json_agent_contact)
    @repo_agent = build(:json_agent_corporate_entity,
                         :agent_contacts => [@repo_contact])

    @repo = build(:json_repo)

    @repo_with_agent = create(:json_repo_with_agent,
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

    @digital_object = create(:json_digital_object,
                             :linked_agents => linked_agents,
                             :subjects => linked_subjects,
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

    # puts "SOURCE: #{@digital_object.inspect}\n"
    # puts "RESULT: #{@mods.to_xml}\n"
  end


  after(:all) do
    [@agent_person, @subject_person, @subjects, @components, @digital_object].flatten.each do |rec|
      rec.delete
    end

    $repo_id = $old_repo_id
    JSONModel.set_repository($repo_id)
  end


  describe "names" do

    it "maps each name to a name tag" do
      @agent_person.names.each do |name|
        @mods.should have_tag "mods/name[@type='personal'][@authority='#{name['source']}']/namePart[@type='family']" => name['primary_name']
      end
    end


    it "creates a role for each name" do
      @mods.should have_tag "mods/name[@type='personal']/role/roleTerm[@type='text'][@authority='marcrelator']" => "creator"
    end
  end


  describe "names of subjects" do

    it "wraps agents related as subjects in a subject tag" do
      @mods.should have_tag "mods/subject/name/namePart" => @subject_person.names[0]['primary_name']
    end

  end


  describe "subjects" do

    it "maps each subject to a subject tag" do
      @subjects.each do |subject|
      @mods.should have_tag "mods/subject[@authority='#{subject['source']}']"
        subject['terms'].each do |term|
          case term['term_type']
          when 'geographic', 'cultural_context'
            @mods.should have_tag "subject/geographic" => term['term']
          when 'temporal'
            @mods.should have_tag "subject/temporal" => term['term']
          when 'uniform_title'
            @mods.should have_tag "subject/titleInfo" => term['term']
          when 'genre_form', 'style_period'
            @mods.should have_tag "subject/genre" => term['term']
          when 'occupation'
            @mods.should have_tag "subject/occupation" => term['term']
          else
            @mods.should have_tag "subject/topic" => term['term']
          end
        end
      end
    end
  end


  describe "notes" do

    it "maps each note to the right type of tag" do
      @digital_object.notes.each do |note|
        content = note_content(note)
        case note['type']
        when 'abstract', 'scopecontent'
          @mods.should have_tag "abstract" => content
        when 'bioghist', 'odd'
          @mods.should have_tag "note" => content
        when 'acquinfo'
          @mods.should have_tag "note[@type='acquisition']" => content
        when 'citation'
          @mods.should have_tag "note[@type='citation']" => content
        when 'accessrestrict'
          @mods.should have_tag "accessCondition[@type='restrictionOnAccess']" => content
        when 'userestrict'
          @mods.should have_tag "accessCondition[@type='useAndReproduction']" => content
        when 'legalstatus'
          @mods.should have_tag "accessCondition" => content
        when 'physdesc'
          @mods.should have_tag "physicalDescription/note" => content
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

      @mods.should have_tag "note[@displayLabel='Digital object made available by']" => note_content
    end
  end


  describe "related items" do

    it "maps each digital object component to a related item" do
      @mods.should have_tag "relatedItem[@type='constituent'][#{@components.count}]"
      @mods.should_not have_tag "relatedItem[@type='constituent'][#{@components.count + 1}]"
    end
  end

end
