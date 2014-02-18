require_relative 'export_spec_helper'


def get_mets(rec)
  get_xml("/repositories/#{$repo_id}/digital_objects/mets/#{rec.id}.xml")
end


describe "Exported METS document" do

  before(:all) do

    use_statements = []

    while use_statements.count == use_statements.uniq.count
      use_statements << generate(:use_statement)
    end

    @file_versions = use_statements.map {|us| build(:json_file_version, :use_statement => us)}

    @digital_object = create(:json_digital_object,
                             :file_versions => @file_versions)


    @digital_object_components = {}

    @digital_object = create(:json_digital_object)

    create(:json_digital_object_component,
           :digital_object => {:ref => @digital_object.uri},
           :parent => {:ref => create(:json_digital_object_component,
                                      :digital_object => {:ref => @digital_object.uri},
                                      :parent => {:ref => create(:json_digital_object_component,
                                                                 :digital_object => {:ref => @digital_object.uri},
                                                                 :file_versions => [build(:json_file_version)]).uri}
                                      ).uri}
           )




    10.times {
      parent = [true, false].sample ? @digital_object_components.keys[rand(@digital_object_components.keys.length)] : nil
      d = create(:json_digital_object_component,  :digital_object => {:ref => @digital_object.uri},
                 :parent => parent ? {:ref => parent} : nil,
                 )

      @digital_object_components[d.uri] = d
    }

    @mets = get_mets(@digital_object)

    puts "SOURCE: #{@digital_object.inspect}\n"
    puts "RESULT: #{@mets.to_xml}\n"
  end

  it "has the correct namespaces" do
    @mets.should have_namespaces({
                                   "xmlns" => "http://www.loc.gov/METS/",
                                   "xmlns:mods"=> "http://www.loc.gov/mods/v3",
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
      @mets.should have_tag "metsHdr/agent[@ROLE='CREATOR'][@TYPE='ORGANIZATION']/name" => $repo.name
      @mets.should have_tag "metsHdr/agent[@ROLE='CREATOR'][@TYPE='ORGANIZATION']/note" => $repo.url
      @mets.should have_tag "metsHdr/agent[@ROLE='CREATOR'][@TYPE='ORGANIZATION']/note" => "Produced by ArchivesSpace"
    end
  end


  describe "dmdSec" do

    # TODO: Describe MODS and DC Mappings / Choice
    it "creates a dmdSec for the top-level digital object" do
      @mets.should have_tag "dmdSec[@ID='#{@digital_object.id}']"
      @mets.should have_tag "dmdSec/mdWrap[@MDTYPE='MODS']"
      @mets.should_not have_tag "dmdSec/mdWrap[!@MDTYPE]"
    end


    it "creates a dmdSec for each component" do
      @digital_object_components.each do |uri, rec|
        @mets.should have_tag "dmdSec[@id='#{rec.id}']"
      end
    end
  end


  describe "fileSec" do

    it "creates one fileGrp for every unique use_statement value in the set of file_versions" do 
      use_statement_count = @file_versions.map {|fv| fv.use_statement}.uniq

      @mets.should have_tag("fileSec/fileGrp[#{use_statement_count}]")
      @mets.should_not have_tag("fileSec/fileGrp[#{use_statement_count + 1}]")
    end


    it "creates one file for every file_version in the set" do
      @file_versions.each do |file_version|
        us = I18n.t("enumerations.file_version_use_statement.#{use_statement}")
        @mets.should have_tag "fileGrp[@USE='#{us}']/file[@ID='#{file_version.id}']/FLocat[@xlink:href='#{file_version.file_uri}']"
      end
    end
  end


  describe "structMap logical" do

    it "maps the component hierarchy to nested <div> tags" do
      @mets.should have_tag("structMap[@TYPE='logical']/div/div/div/div")
    end
  end


  describe "structMap physical" do

    it "creates a <div> hierarchy that ignores components without file_version elements" do
      @mets.should have_tag("structMap[@TYPE='physical']/div/div")
      @mets.should_not have_tag("structMap[@TYPE='physical']/div/div/div")
    end
  end
end

