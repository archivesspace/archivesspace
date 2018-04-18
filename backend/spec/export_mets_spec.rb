require_relative 'export_spec_helper'

# Background: These specs are the result of an attempt to interpret
# mappings included in documentation for the Archivists' Toolkit. 
# Where it was  possible to do so, they have been transposed from a 
# file downloaded from:
# http://archiviststoolkit.org/sites/default/files/ATexports_2008_10_08.xls

describe "Exported METS document" do

  before(:all) do
    $old_repo_id = $repo_id
    @repo = create(:json_repo)
    $repo_id = @repo.id

    JSONModel.set_repository($repo_id)

    use_statements = []

    10.times {
      use_statements << generate(:use_statement)
    }

    # ensure one duplicate value
    use_statements << use_statements.last.clone

    @file_versions = use_statements.map {|us| build(:json_file_version, :use_statement => us)}

    @digital_object = create(:json_digital_object,
                             :file_versions => @file_versions[0..5])

    @components = []
    # a child with a file version
    @components << create(:json_digital_object_component,
                          :digital_object => {:ref => @digital_object.uri},
                          :file_versions => @file_versions[6..7])

    # a grandchild with no file version
    @components << create(:json_digital_object_component,
                          :digital_object => {:ref => @digital_object.uri},
                          :parent => {:ref => @components[0].uri})

    # a great-grandchild with a file version
    @components << create(:json_digital_object_component,
                         :digital_object => {:ref => @digital_object.uri},
                         :parent => {:ref => @components[1].uri},
                         :file_versions => @file_versions[8..-1])

    @mets = get_mets(@digital_object)
    @dc_mets = get_mets(@digital_object, "dc")

    # puts "SOURCE: #{@digital_object.inspect}\n"
    # puts "RESULT: #{@mets.to_xml}\n"
  end

  after(:all) do
    [@digital_objects, @components].flatten.each do |rec|
      next if rec.nil?
      rec.delete
    end


    $repo_id = $old_repo_id
    JSONModel.set_repository($repo_id)
  end

  it "has the correct namespaces" do
    @mets.should have_namespaces({
                                   "xmlns" => "http://www.loc.gov/METS/",
                                   "xmlns:mods"=> "http://www.loc.gov/mods/v3",
                                   "xmlns:dc"=> "http://purl.org/dc/elements/1.1/",
                                   "xmlns:xlink" => "http://www.w3.org/1999/xlink",
                                   "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance"
                                 })
  end


  it "has the correct schema location" do
    @mets.should have_schema_location "http://www.loc.gov/standards/mets/mets.xsd"
  end


  describe "metsHdr" do

    it "has a CREATEDATE attribute" do
      @mets.should have_tag "metsHdr[@CREATEDATE]"
    end


    it "has an agent statement" do
      @mets.should have_tag "metsHdr/agent[@ROLE='CREATOR'][@TYPE='ORGANIZATION']/name" => @repo.name

      @mets.should have_tag "metsHdr/agent[@ROLE='CREATOR'][@TYPE='ORGANIZATION']/note" => @repo.url
      @mets.should have_tag "metsHdr/agent[@ROLE='CREATOR'][@TYPE='ORGANIZATION']/note" => "Produced by ArchivesSpace"
    end
  end


  describe "dmdSec" do

    # TODO: Describe MODS and DC Mappings / Choice
    it "creates a dmdSec for the top-level digital object" do
      @mets.should have_tag "dmdSec[@ID='#{@digital_object.id}']/mdWrap/xmlData/mods:mods"
      @mets.should have_tag "dmdSec/mdWrap[@MDTYPE='MODS']"
      @mets.should_not have_tag "dmdSec/mdWrap[not(@MDTYPE)]"
    end


    it "doesn't traverse the tree to build out relatedItem tags" do
      @mets.should_not have_tag "mods:mods/mods:relatedItem"
    end


    it "creates a dmdSec for each component" do
      @components.each do |rec|
        @mets.should have_tag "dmdSec[@ID='#{rec.id}']"
      end
    end
  end

  describe "dmdSec - DC" do
    it "creates a DC dmdSec for the top-level digital object if DC is chosen" do
      @dc_mets.should have_tag "dmdSec[@ID='#{@digital_object.id}']/mdWrap/xmlData/dc:dc"
      @dc_mets.should have_tag "dmdSec/mdWrap[@MDTYPE='DC']"
      @dc_mets.should_not have_tag "dmdSec/mdWrap[@MDTYPE='MODS']"
    end

    it "creates a DC dmdSec for each component" do
      @components.each do |rec|
        @dc_mets.should have_tag "dmdSec[@ID='#{rec.id}']/mdWrap[@MDTYPE='DC']"
      end
    end
  end


  describe "fileSec" do

    it "creates one fileGrp for every unique use_statement value in the set of file_versions" do 
      use_statement_count = @file_versions.map {|fv| fv.use_statement}.uniq.count

      @mets.should have_tag("fileSec/fileGrp[#{use_statement_count}]")
      @mets.should_not have_tag("fileSec/fileGrp[#{use_statement_count + 1}]")
    end


    it "creates one file for every file_version in the set" do
      @file_versions.each do |file_version|
        us = I18n.t("enumerations.file_version_use_statement.#{file_version['use_statement']}")
        @mets.should have_tag "fileGrp[@USE='#{us}']/file/FLocat[@xlink:href='#{file_version.file_uri}']"
      end
    end


    it "maps the digital object ID to the GROUPID of the file" do
      [@digital_object, @components[0]].each do |dob|
        @mets.should have_tag "fileGrp/file[@GROUPID=#{dob.id}]"
      end
    end
  end


  describe "structMap logical" do

    it "maps the component hierarchy to nested <div> tags" do
      @mets.should have_tag("structMap[@TYPE='logical']/div[@ORDER='1'][@LABEL='#{@digital_object.title}']")
      @mets.should have_tag("structMap[@TYPE='logical']/div/div/div/div[@LABEL='#{@components.last.title}']")
    end


    it "creates a fptr tag for each file version" do
      count = @components.last.file_versions.count
      @mets.should have_tag("structMap[@TYPE='logical']/div/div/div/div/fptr[#{count}]")
      @mets.should_not have_tag("structMap[@TYPE='logical']/div/div/div/div/fptr[#{count + 1}]")
    end
  end


  describe "structMap physical" do

    it "creates a <div> hierarchy that ignores components without file_version elements" do
      # one div should drop out of the hierarchy
      @mets.should have_tag("structMap[@TYPE='physical']/div/div/div[@LABEL='#{@components.last.title}']")
      @mets.should_not have_tag("structMap[@TYPE='physical']/div/div/div/div")
    end
  end
end
