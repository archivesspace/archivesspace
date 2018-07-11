# -*- coding: utf-8 -*-
require 'spec_helper'
require 'converter_spec_helper'

require_relative '../app/converters/ead_converter'

describe 'EAD converter' do

  def my_converter
    EADConverter
  end


  let (:test_doc_1) {
    src = <<ANEAD
<ead>
  <frontmatter>
    <titlepage>
      <titleproper>A test resource</titleproper>
    </titlepage>
  </frontmatter>
  <archdesc level="collection" audience="internal">
    <did>
      <unittitle>一般行政文件 [2]</unittitle>
      <unitid>Resource.ID.AT</unitid>
      <unitdate normal="1907/1911" era="ce" calendar="gregorian" type="inclusive">1907-1911</unitdate>
      <physdesc>
        <extent>5.0 Linear feet</extent>
        <extent>Resource-ContainerSummary-AT</extent>
      </physdesc>
    </did>
  </archdesc>
<dsc>
<c id="1" level="file">
  <unittitle>oh well<unitdate normal="1907/1911" era="ce" calendar="gregorian" type="inclusive">1907-1911</unitdate></unittitle>
  <container id="cid1" type="Box" label="Text (B@RC0D3  )">1</container>
  <container parent="cid1" type="Folder" ></container>
  <c id="2" level="file">
    <unittitle>whatever</unittitle>
    <container id="cid3" type="Box" label="Text">FOO</container>
    <controlaccess><persname rules="dacs" source='local' id='thesame'>Art, Makah</persname></controlaccess>
  </c>
</c>
</dsc>
</ead>
ANEAD

    get_tempfile_path(src)
  }



  it "should add to a sub_container when it finds a parent attribute on a container" do
    converter = EADConverter.new(test_doc_1)
    converter.run
    parsed = JSON(IO.read(converter.get_output_path))

    parsed.length.should eq(6)
    parsed.find{|r| r['ref_id'] == '1'}['instances'][0]['sub_container']['type_2'].should eq('Folder')
  end

  it "should find a top_container barcode in a container label" do
    converter = EADConverter.new(test_doc_1)
    converter.run
    parsed = JSON(IO.read(converter.get_output_path))

    parsed.find{|r| r['ref_id'] == '1'}['instances'][0]['instance_type'].should eq('text')
    parsed.find{|r|
      r['uri'] == parsed.find{|r|
        r['ref_id'] == '1'
      }['instances'][0]['sub_container']['top_container']['ref']
    }['barcode'].should eq('B@RC0D3')
  end

  it "should remove unitdate from unittitle" do
    converter = EADConverter.new(test_doc_1)
    converter.run
    parsed = JSON(IO.read(converter.get_output_path))

    parsed.length.should eq(6)
    parsed.find{|r| r['ref_id'] == '1'}['title'].should eq('oh well')
    parsed.find{|r| r['ref_id'] == '1'}['dates'][0]['expression'].should eq("1907-1911")

  end

  it "should be link to existing agents with authority_id" do

    json =    build( :json_agent_person,
                     :names => [build(:json_name_person,
                     'authority_id' => 'thesame',
                     'source' => 'local'
                     )])

    agent =    AgentPerson.create_from_json(json)

    converter = EADConverter.new(test_doc_1)
    converter.run
    parsed = JSON(IO.read(converter.get_output_path))

    # these lines are ripped out of StreamingImport
    new_agent_json = parsed.find { |r| r['jsonmodel_type'] == 'agent_person' }
    record = JSONModel(:agent_person).from_hash(new_agent_json, true, false)
    new_agent = AgentPerson.ensure_exists(record, nil)


    agent.should eq(new_agent)
  end


  describe "EAD Import Mappings" do
    def test_file
      File.expand_path("../app/exporters/examples/ead/at-tracer.xml", File.dirname(__FILE__))
    end

    before(:all) do
      parsed = convert(test_file)

      @corps = parsed.select {|rec| rec['jsonmodel_type'] == 'agent_corporate_entity'}
      @families = parsed.select {|rec| rec['jsonmodel_type'] == 'agent_family'}
      @people = parsed.select {|rec| rec['jsonmodel_type'] == 'agent_person'}
      @subjects = parsed.select {|rec| rec['jsonmodel_type'] == 'subject'}
      @digital_objects = parsed.select {|rec| rec['jsonmodel_type'] == 'digital_object'}
      @top_containers = parsed.select{|rec| rec['jsonmodel_type'] == 'top_container'}

      @archival_objects = parsed.select {|rec| rec['jsonmodel_type'] == 'archival_object'}.
                                 inject({}) {|result, a|
        a['title'].match(/C([0-9]{2})/) do |m|
          result[m[1]] = a
        end

        result
      }

      @resource = parsed.select {|rec| rec['jsonmodel_type'] == 'resource'}.last
    end


    it "creates the archival object tree correctly" do
      # check the hierarchy (don't be fooled by the system ids when this test fails - they won't match the keys)
      @archival_objects.each do |k, v|
        if k.to_i > 1
          parent_key = sprintf '%02d', k.to_i - 1
          v['parent']['ref'].should eq(@archival_objects[parent_key]['uri'])
        end
      end
    end

    # SPECIFICATION SOURCE: https://archivesspace.basecamphq.com/F158503515
    # Comments should roughly match column 1 of the spreadsheet

    # Note: Elements should be linked at the appropriate level (e.g. in the context to a Resource or Archival Object record).

    # Source element	Processing / Formatting Directions
    #  @id
    #  @target
    #  @audience	WHEN @audience = internal

    # RESOURCE
    it "maps '<date>' correctly" do
      #   IF nested in <chronitem>
      get_subnotes_by_type(get_note(@archival_objects['12'], 'ref53'), 'note_chronology')[0]['items'][0]['event_date'].should eq('1895')

      get_subnotes_by_type(get_note(@archival_objects['12'], 'ref53'), 'note_chronology')[0]['items'][1]['event_date'].should eq('1995')

      #   IF nested in <publicationstmt>
      @resource['finding_aid_date'].should eq('Resource-FindingAidDate-AT')

      #   ELSE
    end

    it "maps '<physdesc>' correctly" do
      # <extent> tag mapping
      #   IF value starts with a number followed by a space and can be parsed
      @resource['extents'][0]['number'].should eq("5.0")
      @resource['extents'][0]['extent_type'].should eq("Linear feet")

      #   ELSE
      @resource['extents'][0]['container_summary'].should eq("Resource-ContainerSummary-AT")


      # further physdesc tags - dimensions and physfacet tags are mapped appropriately
      @resource['extents'][0]['dimensions'].should eq("Resource-Dimensions-AT")
      @resource['extents'][0]['physical_details'].should eq("Resource-PhysicalFacet-AT")

      # physdesc altrender mapping
      @resource['extents'][0]['portion'].should eq("part")
    end


    it "maps '<unitdate>' correctly" do
      @resource['dates'][0]['expression'].should eq("Bulk, 1960-1970")
      @resource['dates'][0]['date_type'].should eq("bulk")

      @resource['dates'][1]['expression'].should eq("Resource-Title-AT")
      @resource['dates'][1]['date_type'].should eq("inclusive")
    end

    it "maps '<unitid>' correctly" do
      #   IF nested in <archdesc><did>
      @resource["id_0"].should eq("Resource.ID.AT")

      #   IF nested in <c><did>
    end

    it "maps '<unittitle>' correctly" do
      #   IF nested in <archdesc><did>
      @resource["title"].should eq('Resource--<title render="italic">Title</title>-AT')
      #   IF nested in <c><did>
      @archival_objects['12']['title'].should eq("Resource-C12-AT")
    end


    # FINDING AID ELEMENTS
    it "maps '<author>' correctly" do
      @resource['finding_aid_author'].should eq('Finding aid prepared by Resource-FindingAidAuthor-AT')
    end

    it "maps '<descrules>' correctly" do
      @resource['finding_aid_description_rules'].should eq('Describing Archives: A Content Standard')
    end

    it "maps '<eadid>' correctly" do
      @resource['ead_id'].should eq('Resource-EAD-ID-AT')
    end

    it "maps '<eadid @url>' correctly" do
      @resource['ead_location'].should eq('Resource-EAD-Location-AT')
    end

    it "maps '<editionstmt>' correctly" do
      @resource['finding_aid_edition_statement'].should eq("Resource-FindingAidEdition-AT")
    end

    it "maps '<seriesstmt>' correctly" do
      @resource['finding_aid_series_statement'].should eq("Resource-FindingAidSeries-AT")
    end

    it "maps '<sponsor>' correctly" do
      @resource['finding_aid_sponsor'].should eq('Resource-Sponsor-AT')
    end

    it "maps '<subtitle>' correctly" do
    end

    it "maps '<titleproper>' correctly" do
      @resource['finding_aid_title'].should eq("Resource-FindingAidTitle-AT <num>Resource.ID.AT</num>")
    end

    it "maps '<titleproper type=\"filing\">' correctly" do
      @resource['finding_aid_filing_title'].should eq('Resource-FindingAidFilingTitle-AT')
    end

    it "maps '<langusage>' correctly" do
      @resource['finding_aid_language'].should eq('Resource-FindingAidLanguage-AT')
    end

    it "maps '<revisiondesc>' correctly" do
      @resource['revision_statements'][0]['description'].should eq("Resource-FindingAidRevisionDescription-AT")
      @resource['revision_statements'][0]['date'].should eq("Resource-FindingAidRevisionDate-AT")
    end

    # NAMES
    it "maps '<corpname>' correctly" do
      #   IF nested in <origination> OR <controlaccess>
      #   IF nested in <origination>
      c1 = @corps.find {|corp| corp['names'][0]['primary_name'] == "CNames-PrimaryName-AT. CNames-Subordinate1-AT. CNames-Subordiate2-AT. (CNames-Number-AT) (CNames-Qualifier-AT)"}
      c1.should_not be_nil

      linked = @resource['linked_agents'].find {|a| a['ref'] == c1['uri']}
      linked['role'].should eq('creator')
      #   IF nested in <controlaccess>
      c2 = @corps.find {|corp| corp['names'][0]['primary_name'] == "CNames-PrimaryName-AT. CNames-Subordinate1-AT. CNames-Subordiate2-AT. (CNames-Number-AT) (CNames-Qualifier-AT) -- Archives"}
      c2.should_not be_nil

      linked = @resource['linked_agents'].find {|a| a['ref'] == c2['uri']}
      linked['role'].should eq('subject')

      #   ELSE
      #   IF @rules != NULL ==> name_corporate_entity.rules
      [c1, c2].map {|c| c['names'][0]['rules']}.uniq.should eq(['dacs'])
      #   IF @source != NULL ==> name_corporate_entity.source
        [c1, c2].map {|c| c['names'][0]['source']}.uniq.should eq(['naf'])
      #   IF @authfilenumber != NULL
    end

    it "maps '<famname>' correctly" do
      #   IF nested in <origination> OR <controlaccess>
      uris = @archival_objects['06']['linked_agents'].map {|l| l['ref'] } & @families.map {|f| f['uri'] }
      links = @archival_objects['06']['linked_agents'].select {|l| uris.include?(l['ref']) }
      fams = @families.select {|f| uris.include?(f['uri']) }

      #   IF nested in <origination>
      n1 = fams.find{|f| f['uri'] == links.find{|l| l['role'] == 'creator' }['ref'] }['names'][0]['family_name']
      n1.should eq("FNames-FamilyName-AT, FNames-Prefix-AT, FNames-Qualifier-AT")
      #   IF nested in <controlaccess>
      n2 = fams.find{|f| f['uri'] == links.find{|l| l['role'] == 'subject' }['ref'] }['names'][0]['family_name']
      n2.should eq("FNames-FamilyName-AT, FNames-Prefix-AT, FNames-Qualifier-AT -- Pictorial works")
      #   ELSE
      #   IF @rules != NULL
      fams.map{|f| f['names'][0]['rules']}.uniq.should eq(['aacr'])
      #   IF @source != NULL
      fams.map{|f| f['names'][0]['source']}.uniq.should eq(['naf'])
      #   IF @authfilenumber != NULL
    end

    it "maps '<persname>' correctly" do
      #   IF nested in <origination> OR <controlaccess>
      #   IF nested in <origination>
      @archival_objects['01']['linked_agents'].find {|l| @people.map{|p| p['uri'] }.include?(l['ref'])}['role'].should eq('creator')
      #   IF nested in <controlaccess>
      @archival_objects['06']['linked_agents'].reverse.find {|l| @people.map{|p| p['uri'] }.include?(l['ref'])}['role'].should eq('subject')
      #   ELSE
      #   IF @rules != NULL
      @people.map {|p| p['names'][0]['rules']}.uniq.should eq(['local'])
      #   IF @source != NULL
      @people.map {|p| p['names'][0]['source']}.uniq.should eq(['local'])
      #   IF @authfilenumber != NULL
    end

      # SUBJECTS
    it "maps '<function>' correctly" do
      #   IF nested in <controlaccess>
      subject = @subjects.find{|s| s['terms'][0]['term_type'] == 'function'}
        [@resource, @archival_objects["06"], @archival_objects["12"]].each do |a|
        a['subjects'].select{|s| s['ref'] == subject['uri']}.count.should eq(1)
      end
      #   @source
      subject['source'].should eq('local')
      #   ELSE
      #   IF @authfilenumber != NULL
    end

    it "maps '<genreform>' correctly" do
      #   IF nested in <controlaccess>
      subject = @subjects.find{|s| s['terms'][0]['term_type'] == 'genre_form'}
      [@resource, @archival_objects["06"], @archival_objects["12"]].each do |a|
        a['subjects'].select{|s| s['ref'] == subject['uri']}.count.should eq(1)
      end
      #   @source
      subject['source'].should eq('local')
      #   ELSE
      #   IF @authfilenumber != NULL
    end

    it "maps '<geogname>' correctly" do
      #   IF nested in <controlaccess>
      subject = @subjects.find{|s| s['terms'][0]['term_type'] == 'geographic'}
      [@resource, @archival_objects["06"], @archival_objects["12"]].each do |a|
        a['subjects'].select{|s| s['ref'] == subject['uri']}.count.should eq(1)
      end
      #   @source
      subject['source'].should eq('local')
      #   ELSE
      #   IF @authfilenumber != NULL
    end

    it "maps '<occupation>' correctly" do
      subject = @subjects.find{|s| s['terms'][0]['term_type'] == 'occupation'}
      [@resource, @archival_objects["06"], @archival_objects["12"]].each do |a|
        a['subjects'].select{|s| s['ref'] == subject['uri']}.count.should eq(1)
      end
      #   @source
      subject['source'].should eq('local')
      #   ELSE
      #   IF @authfilenumber != NULL
    end

    it "maps '<subject>' correctly" do
      #   IF nested in <controlaccess>
      subject = @subjects.find{|s| s['terms'][0]['term_type'] == 'topical'}
        [@resource, @archival_objects["06"], @archival_objects["12"]].each do |a|
        a['subjects'].select{|s| s['ref'] == subject['uri']}.count.should eq(1)
      end
      #   @source
      subject['source'].should eq('local')
      #   ELSE
      #   IF @authfilenumber != NULL
    end

      # NOTES
      # if other EAD elements that map to a note object are nested in eachother, then those notes will be treated as separate notes;
      # for example, a <scopecontent> may contain another <scopecontent>, etc.;
      # therefore, if  <scopecontent> tag contains a nested <scopecontent>, the note contents will be mapped into two separate notes of type "Scope and Contents note" in the Toolkit;
      # if, for example, an <accessrestrict> tag contains a nested <legalstatus>, the tag contents will be mapped into separate notes, one of type "accessrestict" and the part tagged as <legalstatus> as type "legalstatus".
      # if one or more <note> tags are nested, then those <note> tags will initiate separate notes with the NoteType equivalent to the parent note.
      # That is, where <accessrestrict> tag contains a nested <note>, the tag contents will be mapped  into two separate notes of type "Access Restrictions" in the Toolkit.

      # @id	ALL @id attributes on note tags map to the persistent_id property

      # Simple Notes
    it "maps '<abstract>' correctly" do
      note_content(get_note_by_type(@resource, 'abstract')).should eq("Resource-Abstract-AT")
    end

    it "maps '<accessrestrict>' correctly" do
      nc = get_notes_by_type(@resource, 'accessrestrict').map {|note|
        note_content(note)
      }.flatten

      nc[0].should eq("Resource-ConditionsGoverningAccess-AT")
      nc[1].should eq("<legalstatus>Resource-LegalStatus-AT</legalstatus>")
    end

    it "maps '<accruals>' correctly" do
      note_content(get_note_by_type(@resource, 'accruals')).should eq("Resource-Accruals-AT")
    end

    it "maps '<acqinfo>' correctly" do
      note_content(get_note_by_type(@resource, 'acqinfo')).should eq("Resource-ImmediateSourceAcquisition")
    end

    it "maps '<altformavail>' correctly" do
      note_content(get_note_by_type(@resource, 'altformavail')).should eq("Resource-ExistenceLocationCopies-AT")
    end

    it "maps '<appraisal>' correctly" do
      note_content(get_note_by_type(@resource, 'appraisal')).should eq("Resource-Appraisal-AT")
    end

    it "maps '<arrangement>' correctly" do
      note_content(get_note_by_type(@resource, 'arrangement')).should eq("Resource-Arrangement-Note")
    end

    it "maps '<bioghist>' correctly" do
      @archival_objects['06']['notes'].find{|n| n['type'] == 'bioghist'}['persistent_id'].should eq('ref50')
      @archival_objects['12']['notes'].find{|n| n['type'] == 'bioghist'}['persistent_id'].should eq('ref53')
      @resource['notes'].select{|n| n['type'] == 'bioghist'}.map{|n| n['persistent_id']}.sort.should eq(['ref47', 'ref7'])
    end

    it "maps '<custodhist>' correctly" do
      note_content(get_note_by_type(@resource, 'custodhist')).should eq("Resource--CustodialHistory-AT")
    end

    it "maps '<dimensions>' correctly" do
      note_content(get_note_by_type(@resource, 'dimensions')).should eq("Resource-Dimensions-AT")
    end

    it "maps '<fileplan>' correctly" do
      note_content(get_note_by_type(@resource, 'fileplan')).should eq("Resource-FilePlan-AT")
    end

    it "maps '<langmaterial>' correctly" do
      @archival_objects['06']['language'].should eq('eng')
    end

    it "maps '<legalstatus>' correctly" do
      note_content(get_note_by_type(@resource, 'legalstatus')).should eq("Resource-LegalStatus-AT")
    end

    it "maps '<materialspec>' correctly" do
      get_note_by_type(@resource, 'materialspec')['persistent_id'].should eq("ref22")
    end

    it "maps '<note>' correctly" do
      #   IF nested in <archdesc> OR <c>

      #   ELSE, IF nested in <notestmnt>
      @resource['finding_aid_note'].should eq("Resource-FindingAidNote-AT\n\nResource-FindingAidNote-AT2\n\nResource-FindingAidNote-AT3\n\nResource-FindingAidNote-AT4")
    end

    it "maps '<odd>' correctly" do
      @resource['notes'].select{|n| n['type'] == 'odd'}.map{|n| n['persistent_id']}.sort.should eq(%w(ref45 ref44 ref15).sort)
    end

    it "maps '<originalsloc>' correctly" do
      get_note_by_type(@resource, 'originalsloc')['persistent_id'].should eq("ref13")
    end

    it "maps '<otherfindaid>' correctly" do
      get_note_by_type(@resource, 'otherfindaid')['persistent_id'].should eq("ref23")
    end

    it "maps '<physfacet>' correctly" do
      note_content(get_note_by_type(@resource, 'physfacet')).should eq("Resource-PhysicalFacet-AT")
    end

    it "maps '<physloc>' correctly" do
      get_note_by_type(@resource, 'physloc')['persistent_id'].should eq("ref21")
    end

    it "maps '<phystech>' correctly" do
      get_note_by_type(@resource, 'phystech')['persistent_id'].should eq("ref24")
    end

    it "maps '<prefercite>' correctly" do
      get_note_by_type(@resource, 'prefercite')['persistent_id'].should eq("ref26")
    end

    it "maps '<processinfo>' correctly" do
      get_note_by_type(@resource, 'prefercite')['persistent_id'].should eq("ref26")
    end

    it "maps '<relatedmaterial>' correctly" do
      get_note_by_type(@resource, 'prefercite')['persistent_id'].should eq("ref26")
    end

    it "maps '<scopecontent>' correctly" do
      get_note_by_type(@resource, 'scopecontent')['persistent_id'].should eq("ref29")
      @archival_objects['01']['notes'].find{|n| n['type'] == 'scopecontent'}['persistent_id'].should eq("ref43")
    end

    it "maps '<separatedmaterial>' correctly" do
      get_note_by_type(@resource, 'separatedmaterial')['persistent_id'].should eq("ref30")
    end

    it "maps '<userestrict>' correctly" do
      get_note_by_type(@resource, 'userestrict')['persistent_id'].should eq("ref9")
    end

    # Structured Notes
    it "maps '<bibliography>' correctly" do
      #     IF nested in <archdesc>  OR <c>
      @resource['notes'].find{|n| n['jsonmodel_type'] == 'note_bibliography'}['persistent_id'].should eq("ref6")
      @archival_objects['06']['notes'].find{|n| n['jsonmodel_type'] == 'note_bibliography'}['persistent_id'].should eq("ref48")
      @archival_objects['12']['notes'].find{|n| n['jsonmodel_type'] == 'note_bibliography'}['persistent_id'].should eq("ref51")
      #     <head>
      @archival_objects['06']['notes'].find{|n| n['persistent_id'] == 'ref48'}['label'].should eq("Resource--C06-Bibliography")
      #     <p>
      @archival_objects['06']['notes'].find{|n| n['persistent_id'] == 'ref48'}['content'][0].should eq("Resource--C06--Bibliography--Head")
      #     <bibref>
      @archival_objects['06']['notes'].find{|n| n['persistent_id'] == 'ref48'}['items'][0].should eq("c06 bibItem2")
      @archival_objects['06']['notes'].find{|n| n['persistent_id'] == 'ref48'}['items'][1].should eq("c06 bibItem1")
      #     other nested and inline elements
    end

    it "maps '<index>' correctly" do
      #   IF nested in <archdesc>  OR <c>
      ref52 = get_note(@archival_objects['12'], 'ref52')
      ref52['jsonmodel_type'].should eq('note_index')
      #     <head>
      ref52['label'].should eq("Resource-c12-Index")
      #     <p>
      ref52['content'][0].should eq("Resource-c12-index-note")
      #     <indexentry>
      #         <name>

      #         <persname>

      #         <famname>
      ref52['items'].find{|i| i['type'] == 'family'}['value'].should eq('Bike 2')
      #         <corpname>
      ref52['items'].find{|i| i['type'] == 'corporate_entity'}['value'].should eq('Bike 3')
      #         <subject>

      #         <function>

      #         <occupation>

      #         <genreform>
      ref52['items'].find{|i| i['type'] == 'genre_form'}['value'].should eq('Bike 1')
      #         <title>

      #         <geogname>

      #         <ref>
      #     other nested and inline elements
    end


    # Mixed Content Note Parts
    it "maps '<chronlist>' correctly" do
      #     <head>
      #     <chronitem>
      #         <date>
      #         <event>
      ref53 = get_note(@archival_objects['12'], 'ref53')
      get_subnotes_by_type(ref53, 'note_chronology')[0]['items'][0]['events'][0].should eq('first date')
      get_subnotes_by_type(ref53, 'note_chronology')[0]['items'][1]['events'][0].should eq('second date')

      #         <eventgrp><event>
      ref50 = get_subnotes_by_type(get_note(@archival_objects['06'], 'ref50'), 'note_chronology')[0]
      item = ref50['items'].find{|i| i['event_date'] && i['event_date'] == '1895'}
      item['events'].sort.should eq(['Event1', 'Event2'])
      #         other nested and inline elements
    end

    # WHEN @type = deflist OR @type = NULL AND <defitem> present
    it "maps '<list>' correctly" do
      ref47 = get_note(@resource, 'ref47')
      note_dl = ref47['subnotes'].find{|n| n['jsonmodel_type'] == 'note_definedlist'}
      #     <head>
      note_dl['title'].should eq("Resource-BiogHist-structured-top-part3-listDefined")
      #     <defitem>	WHEN <list> @type = deflist
      #         <label>
      note_dl['items'].map {|i| i['label']}.sort.should eq(['MASI SLP', 'Yeti Big Top', 'Intense Spider 29'].sort)
      #         <item>
      note_dl['items'].map {|i| i['value']}.sort.should eq(['2K', '2500 K', '4500 K'].sort)
      # ELSE WHEN @type != deflist AND <defitem> not present
      ref44 = get_note(@resource, 'ref44')
      note_ol = get_subnotes_by_type(ref44, 'note_orderedlist')[0]
      #     <head>
      note_ol['title'].should eq('Resource-GeneralNoteMULTIPARTLISTTitle-AT')
      #     <item>
      note_ol['items'].sort.should eq(['Resource-GeneralNoteMULTIPARTLISTItem1-AT', 'Resource-GeneralNoteMULTIPARTLISTItem2-AT'])
    end

    # CONTAINER INFORMATION
    # Up to three container elements can be imported per <c>.
    # The Asterisks in the target element field below represents the numbers "1", "2", or "3" depending on which <container> tag the data is coming from

    it "maps '<container>' correctly" do
      instance = @archival_objects['02']['instances'][0]
      instance['instance_type'].should eq('text')
      sub = instance['sub_container']
      sub['type_2'].should eq('Folder')
      sub['indicator_2'].should eq('2')

      top = @top_containers.select{|t| t['uri'] == sub['top_container']['ref']}.first
      top['type'].should eq('Box')
      top['indicator'].should eq('2')
    end

    # DAO's
    it "maps '<dao>' correctly" do
      @digital_objects.length.should eq(12)
      links = @archival_objects['01']['instances'].select{|i| i.has_key?('digital_object')}.map{|i| i['digital_object']['ref']}
      links.sort.should eq(@digital_objects.map{|d| d['uri']}.sort)
      #   @titles
      @digital_objects.map {|d| d['title']}.include?("DO.Child2Title-AT").should be(true)
      #   @role
      uses = @digital_objects.map {|d| d['file_versions'].map {|f| f['use_statement']}}.flatten
      uses.uniq.sort.should eq(["Image-Service", "Image-Master", "Image-Thumbnail"].sort)
      #   @href
      uris = @digital_objects.map {|d| d['file_versions'].map {|f| f['file_uri']}}.flatten
      (uris.include?('DO.Child1URI2-AT')).should be(true)
      #   @actuate
      @digital_objects.select{|d| d['file_versions'][0]['xlink_actuate_attribute'] == 'onRequest'}.length.should eq(9)
      #   @show
      @digital_objects.select{|d| d['file_versions'][0]['xlink_show_attribute'] == 'new'}.length.should eq(3)
    end

    # FORMAT & STRUCTURE
    it "maps '<archdesc>' correctly" do
      #   @level	IF != NULL
      @resource['level'].should eq("collection")
      #   ELSE
      #   @otherlevel
    end

    it "maps '<c>' correctly" do
      #   @level	IF != NULL
      @archival_objects['04']['level'].should eq('file')
      #   ELSE
      #   @otherlevel
      #   @id
      @archival_objects['05']['ref_id'].should eq('ref34')
    end
  end

  describe "Mapping '<unitid>' without altering content" do
    def test_doc
      src = <<ANEAD
<ead>
  <archdesc level="collection" audience="internal">
  <did>
       <descgrp>
          <processinfo/>
      </descgrp>
      <unittitle>unitid test</unittitle>
      <unitdate normal="1907/1911" era="ce" calendar="gregorian" type="inclusive">1907-1911</unitdate>
      <unitid>Resource_ID/AT-thing.stuff</unitid>
      <physdesc>
       (folders 14–15 of 15 folders)
        <extent>5.0 Linear feet</extent>
      </physdesc>
    </did>
    <dsc>
    <c id="1" level="file" audience="internal">
      <unittitle>oh well</unittitle>
      <unitdate normal="1907/1911" era="ce" calendar="gregorian" type="inclusive">1907-1911</unitdate>
    </c>
    </dsc>
  </archdesc>
</ead>
ANEAD

      get_tempfile_path(src)
    end

    before do
      parsed = convert(test_doc)
      @resource = parsed.find{|r| r['jsonmodel_type'] == 'resource'}
      @components = parsed.select{|r| r['jsonmodel_type'] == 'archival_object'}
    end

    it "captures unitid content verbatim" do
      expect(@resource["id_0"]).to eq("Resource_ID/AT-thing.stuff")
    end
  end

  describe "Mapping the EAD @audience attribute" do
    def test_doc
      src = <<ANEAD
<ead>
  <archdesc level="collection" audience="internal">
  <did>
       <descgrp>
          <processinfo/>
      </descgrp>
      <unittitle>Resource--Title-AT</unittitle>
      <unitdate normal="1907/1911" era="ce" calendar="gregorian" type="inclusive">1907-1911</unitdate>
      <unitid>Resource.ID.AT</unitid>
      <physdesc>
       (folders 14–15 of 15 folders)
        <extent>5.0 Linear feet</extent>
        <extent>Resource-ContainerSummary-AT</extent>
      </physdesc>
    </did>
    <dsc>
    <c id="1" level="file" audience="internal">
      <unittitle>oh well</unittitle>
      <unitdate normal="1907/1911" era="ce" calendar="gregorian" type="inclusive">1907-1911</unitdate>
    </c>
    <c id="2" level="file" audience="external">
      <unittitle>whatever</unittitle>
      <container id="cid3" type="Box" label="Text">FOO</container>
    </c>
    </dsc>
  </archdesc>
</ead>
ANEAD

      get_tempfile_path(src)
    end

    before do
      parsed = convert(test_doc)
      @resource = parsed.find{|r| r['jsonmodel_type'] == 'resource'}
      @components = parsed.select{|r| r['jsonmodel_type'] == 'archival_object'}
    end

    it "uses archdesc/@audience to set resource publish property" do
      @resource['publish'].should be false
    end

    it "uses c/@audience to set component publish property" do
      @components[0]['publish'].should be false
      @components[1]['publish'].should be true
    end
  end

  describe "Non redundant mapping" do
    def test_doc
      src = <<ANEAD
<ead>
  <archdesc level="collection">
    <did>
      <unittitle>Resource--Title-AT</unittitle>
      <unitid>Resource.ID.AT</unitid>
      <unitdate normal="1907/1911" era="ce" calendar="gregorian" type="inclusive">1907-1911</unitdate>
      <physdesc>
        <extent>5.0 Linear feet</extent>
        <extent>Resource-ContainerSummary-AT</extent>
      </physdesc>
      <langmaterial>
        <language langcode="eng"/>
      </langmaterial>
    </did>
    <accruals id="ref2">
       <head>foo</head>
       <p>bar</p>
    </accruals>
    <odd id="ref44">
      <head>Resource-GeneralNoteMULTIPARTLISTLabel-AT</head>
      <list numeration="loweralpha" type="ordered">
        <head>Resource-GeneralNoteMULTIPARTLISTTitle-AT</head>
        <item>Resource-GeneralNoteMULTIPARTLISTItem1-AT</item>
        <item>Resource-GeneralNoteMULTIPARTLISTItem2-AT</item>
      </list>
    </odd>
    <dsc>
    <c id="1" level="file" audience="internal">
      <did>
        <unittitle>oh well</unittitle>
        <unitdate normal="1907/1911" era="ce" calendar="gregorian" type="inclusive">1907-1911</unitdate>
        <langmaterial>
          <language langcode="eng"/>
        </langmaterial>
      </did>
    </c>
    </dsc>
  </archdesc>
</ead>
ANEAD

      get_tempfile_path(src)
    end

    before do
      parsed = convert(test_doc)
      @resource = parsed.find{|r| r['jsonmodel_type'] == 'resource'}
      @component = parsed.find{|r| r['jsonmodel_type'] == 'archival_object'}
    end

    it "only maps <language> content to one place" do
      @resource['language'].should eq 'eng'
      get_note_by_type(@resource, 'langmaterial').should be_nil

      @component['language'].should eq 'eng'
      get_note_by_type(@component, 'langmaterial').should be_nil
    end

    it "maps <head> tag to note label, but not to note content" do
      n = get_note_by_type(@resource, 'accruals')
      n['label'].should eq('foo')
      note_content(n).should_not match(/foo/)
    end

  end

  # https://www.pivotaltracker.com/story/show/65722286
  describe "Mapping the unittitle tag" do
    def test_doc
      src = <<ANEAD
<ead>
  <archdesc level="collection" audience="internal">
    <did>
      <unittitle>一般行政文件 [2]</unittitle>
      <unitid>Resource.ID.AT</unitid>
      <unitdate normal="1907/1911" era="ce" calendar="gregorian" type="inclusive">1907-1911</unitdate>
      <physdesc>
        <extent>5.0 Linear feet</extent>
        <extent>Resource-ContainerSummary-AT</extent>
      </physdesc>
    </did>
  </archdesc>
</ead>
ANEAD

      get_tempfile_path(src)
    end

    it "maps the unittitle tag correctly" do
      json = convert(test_doc)
      resource = json.find{|r| r['jsonmodel_type'] == 'resource'}
      resource['title'].should eq("一般行政文件 [2]")
    end

  end


  describe "Mapping the langmaterial tag" do
    def test_doc
      src = <<ANEAD
<ead>
  <archdesc level="collection" audience="internal">
    <did>
      <unittitle>Title</unittitle>
      <unitid>Resource.ID.AT</unitid>
      <unitdate normal="1907/1911" era="ce" calendar="gregorian" type="inclusive">1907-1911</unitdate>
      <langmaterial>
        <language langcode="eng">English</language>
      </langmaterial>
      <physdesc>
        <extent>5.0 Linear feet</extent>
        <extent>Resource-ContainerSummary-AT</extent>
      </physdesc>
    </did>
  </archdesc>
</ead>
ANEAD

      get_tempfile_path(src)
    end

    it "should map the langcode to language, and the language text to a note" do
      json = convert(test_doc)
      resource = json.select {|rec| rec['jsonmodel_type'] == 'resource'}.last
      resource['language'].should eq('eng')

      langmaterial = get_note_by_type(resource, 'langmaterial')
      note_content(langmaterial).should eq('English')
    end
  end


  describe "extent and physdesc mapping logic" do
    def doc1
      src = <<ANEAD
<ead>
  <archdesc level="collection" audience="internal">
    <did>
      <unittitle>Title</unittitle>
      <unitid>Resource.ID.AT</unitid>
      <unitdate normal="1907/1911" era="ce" calendar="gregorian" type="inclusive">1907-1911</unitdate>
      <langmaterial>
        <language langcode="eng">English</language>
      </langmaterial>
      <physdesc altrender="whole">
        <extent altrender="materialtype spaceoccupied">1 Linear Feet</extent>
      </physdesc>
      <physdesc altrender="whole">
        <extent altrender="materialtype spaceoccupied">1 record carton</extent>
      </physdesc>
    </did>
  </archdesc>
</ead>
ANEAD

      get_tempfile_path(src)
    end

    def doc2
      src = <<ANEAD
<ead>
  <archdesc level="collection" audience="internal">
    <did>
      <unittitle>Title</unittitle>
      <unitid>Resource.ID.AT</unitid>
      <unitdate normal="1907/1911" era="ce" calendar="gregorian" type="inclusive">1907-1911</unitdate>
      <langmaterial>
        <language langcode="eng">English</language>
      </langmaterial>
      <physdesc altrender="whole">
        <extent altrender="materialtype spaceoccupied">1 Linear Feet</extent>
        <extent altrender="materialtype spaceoccupied">1 record carton</extent>
      </physdesc>
    </did>
  </archdesc>
</ead>
ANEAD

      get_tempfile_path(src)
    end

    def doc3
      src = <<ANEAD
<ead>
  <archdesc level="collection" audience="internal">
    <did>
      <unittitle>Title</unittitle>
      <unitid>Resource.ID.AT</unitid>
      <unitdate normal="1907/1911" era="ce" calendar="gregorian" type="inclusive">1907-1911</unitdate>
      <langmaterial>
        <language langcode="eng">English</language>
      </langmaterial>
      <physdesc altrender="whole">
        <extent altrender="materialtype spaceoccupied">1 Linear Feet</extent>
      </physdesc>
      <physdesc altrender="whole">
        <function>whatever</function>
      </physdesc>
    </did>
  </archdesc>
</ead>
ANEAD

      get_tempfile_path(src)
    end

    before(:all) do
      @resource1 = convert(doc1).select {|rec| rec['jsonmodel_type'] == 'resource'}.last
      @resource2 = convert(doc2).select {|rec| rec['jsonmodel_type'] == 'resource'}.last
      @resource3 = convert(doc3).select {|rec| rec['jsonmodel_type'] == 'resource'}.last
    end

    it "creates a single extent record for each physdec/extent[1] node" do
      @resource1['extents'].count.should eq(2)
      @resource2['extents'].count.should eq(1)
    end

    it "puts additional extent records in extent.container_summary" do
      @resource2['extents'][0]['container_summary'].should eq('1 record carton')
    end

    it "maps a physdec node to a note unless it only contains extent tags" do
      get_notes_by_type(@resource1, 'physdesc').length.should eq(0)
      get_notes_by_type(@resource2, 'physdesc').length.should eq(0)
      get_notes_by_type(@resource3, 'physdesc').length.should eq(1)
    end

  end

 describe "DAO and DAOGROUPS" do

   before(:all) do
      test_file = File.expand_path("../app/exporters/examples/ead/ead-dao-test.xml", File.dirname(__FILE__))
      parsed = convert(test_file)

      @digital_objects = parsed.select {|rec| rec['jsonmodel_type'] == 'digital_object'}
      @notes = @digital_objects.inject([]) { |c, rec| c + rec["notes"] }
      @resources = parsed.select {|rec| rec['jsonmodel_type'] == 'resource'}
      @resource = @resources.last
      @archival_objects = parsed.select {|rec| rec['jsonmodel_type'] == 'archival_object'}
      @file_versions = @digital_objects.inject([]) { |c, rec| c + rec["file_versions"] }
   end

    it "should make all the digital, archival objects and resources" do
      @digital_objects.length.should == 5
      @archival_objects.length.should == 8
      @resources.length.should == 1
      @file_versions.length.should == 11
    end

    it "should honor xlink:show and xlink:actuate from arc elements" do
      @file_versions[0..2].map {|fv| fv['xlink_actuate_attribute']}.should == %w|onLoad onRequest onLoad|
      @file_versions[0..2].map{|fv| fv['xlink_show_attribute']}.should == %w|new embed new|
    end

    it "should turn all the daodsc into notes" do
      @notes.length.should == 3
      notes_content = @notes.inject([]) { |c, note| c +  note["content"]  }
      notes_content.should include('<p>first daogrp</p>')
      notes_content.should include('<p>second daogrp</p>')
      notes_content.should include('<p>dao no grp</p>')
    end

  end


  describe "EAD With frontpage" do

    before(:all) do
      test_file = File.expand_path("../app/exporters/examples/ead/vmi.xml", File.dirname(__FILE__))

      @parsed = convert(test_file)
      @resource = @parsed.select {|rec| rec['jsonmodel_type'] == 'resource'}.last
      @archival_objects = @parsed.select {|rec| rec['jsonmodel_type'] == 'archival_object'}
    end

    it "shouldn't overwrite the finding_aid_title/titleproper from frontpage" do
      @resource["finding_aid_title"].should eq("Proper Title")
      @resource["finding_aid_title"].should_not eq("TITLEPAGE titleproper")
    end

    it "should not have any of the titlepage content" do
      @parsed.to_s.should_not include("TITLEPAGE")
    end

    it "should have instances grouped by their container @id/@parent relationships" do
      instances = @archival_objects.first["instances"]
      instances.length.should eq(3)

      instances[1]['sub_container']['type_2'].should eq('Folder')
      instances[1]['sub_container']['indicator_2'].should eq('3')
      instances[2]['sub_container']['type_2'].should eq('Cassette')
      instances[2]['sub_container']['indicator_2'].should eq('4')
      instances[2]['sub_container']['type_3'].should eq('Cassette')
      instances[2]['sub_container']['indicator_3'].should eq('5')
    end

  end

  # See https://archivesspace.atlassian.net/browse/AR-1134
  describe "Mapping physdesc tags" do
    def test_doc
      src = <<ANEAD
<ead>
  <archdesc level="collection" audience="internal">
    <did>
      <unittitle>一般行政文件 [2]</unittitle>
      <unitid>Resource.ID.AT</unitid>
      <unitdate normal="1907/1911" era="ce" calendar="gregorian" type="inclusive">1907-1911</unitdate>
      <physdesc>
        <extent>5.0 Linear feet</extent>
        <extent>Resource-ContainerSummary-AT</extent>
      </physdesc>
    </did>
  </archdesc>
<dsc>
<c>
 <did>
 <unittitle>DIMENSIONS test </unittitle>
 <physdesc>
   <extent>1 photograph</extent>
   <dimensions>8 x 10 inches</dimensions>
   <physfacet>gelatin silver</physfacet>
 </physdesc>
 </did>
</c>
</dsc>
</ead>
ANEAD

      get_tempfile_path(src)
    end

    before(:all) do
      parsed = convert(test_doc)
      @record = parsed.shift
    end

    it "should create an extent tag with dimensions data" do
      @record['extents'].length.should eq(1)
    end

    it "should not create any notes from physdesc data" do
      @record['notes'].length.should eq(0)
    end

    it "should map physdesc/dimensions to extent.dimensions" do
      @record['extents'][0]['dimensions'].should eq('8 x 10 inches')
    end

    it "should map physdesc/physfacet to extent.physical_details" do
      @record['extents'][0]['physical_details'].should eq('gelatin silver')
    end

    let (:records_with_extents) {
      records = convert(File.join(File.dirname(__FILE__), 'fixtures', 'ead_with_extents.xml'))
      Hash[records.map {|rec| [rec['title'], rec]}]
    }

    it "maps no extent, single dimensions, single physfacet to notes" do
      rec = records_with_extents.fetch('No extent, single dimensions, single physfacet')

      rec['extents'].should be_empty
      rec['notes'][0]['content'].should eq(['gelatin silver'])
      rec['notes'][1]['subnotes'][0]['content'].should eq('8 x 10 inches')
    end

    it "maps single extent and single dimensions to extent record" do
      rec = records_with_extents.fetch('Test single extent and single dimensions')

      rec['extents'].length.should eq(1)
      rec['extents'][0]['extent_type'].should eq('photograph')
      rec['extents'][0]['dimensions'].should eq('8 x 10 inches')
    end

    it "maps single extent and single physfacet to extent record" do
      rec = records_with_extents.fetch('Test single extent and single physfacet')

      rec['extents'].length.should eq(1)
      rec['extents'][0]['extent_type'].should eq('photograph')
      rec['extents'][0]['number'].should eq('1')
      rec['extents'][0]['portion'].should eq('whole')
      rec['extents'][0]['physical_details'].should eq('gelatin silver')
    end

    it "maps single extent, single dimensions, single physfacet to extent record" do
      rec = records_with_extents.fetch('Test single extent, single dimensions, single physfacet')

      rec['extents'].length.should eq(1)
      rec['extents'][0]['extent_type'].should eq('photograph')
      rec['extents'][0]['number'].should eq('1')
      rec['extents'][0]['portion'].should eq('whole')
      rec['extents'][0]['physical_details'].should eq('gelatin silver')
      rec['extents'][0]['dimensions'].should eq('8 x 10 inches')
    end

    it "maps single extent and two physfacet to extent record" do
      rec = records_with_extents.fetch('Test single extent and two physfacet')

      rec['extents'].length.should eq(1)
      rec['extents'][0]['extent_type'].should eq('photograph')
      rec['extents'][0]['number'].should eq('1')
      rec['extents'][0]['portion'].should eq('whole')
      rec['extents'][0]['physical_details'].should eq('black and white; gelatin silver')
    end

    it "maps single extent and two dimensions to extent record" do
      rec = records_with_extents.fetch('Test single extent and two dimensions')

      rec['extents'].length.should eq(1)
      rec['extents'][0]['extent_type'].should eq('photograph')
      rec['extents'][0]['number'].should eq('1')
      rec['extents'][0]['portion'].should eq('whole')
      rec['extents'][0]['dimensions'].should eq('8 x 10 inches (photograph); 11 x 14 inches (support)')
    end

    it "maps text physdesc element to note" do
      rec = records_with_extents.fetch('Physdesc only')

      rec['extents'].should be_empty
      rec['notes'].should_not be_empty
      rec['notes'][0]['content'].should eq(["1 photograph: 8 x 10 inches (photograph) 11 x 14 inches (support)"])
    end

  end

  # See https://archivesspace.atlassian.net/browse/AR-1373
  describe "Mapping note tags" do
    def test_doc
      src = <<ANEAD
<?xml version="1.0" encoding="UTF-8"?>
<ead xmlns:ns2="http://www.w3.org/1999/xlink" xmlns="urn:isbn:1-931666-22-9"
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xsi:schemaLocation="urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd">
   <eadheader findaidstatus="temp_record_stead" repositoryencoding="iso15511"
      countryencoding="iso3166-1" dateencoding="iso8601">
      <eadid>testimport20</eadid>
      <filedesc>
         <titlestmt>
            <titleproper>test-import1</titleproper>
            <author/>
         </titlestmt>
          <notestmt>
              <note>
                  <p>A notestmt note</p>
              </note>
          </notestmt>
      </filedesc>
      <profiledesc>
         <langusage>
            <language langcode="eng" encodinganalog="Language">English</language>
         </langusage>
      </profiledesc>
   </eadheader>
   <archdesc level="collection">
      <did>
         <note><p>COLLECTION LEVEL NOTE INSIDE DID</p></note>
         <unittitle>NOTE import test</unittitle>
         <unitid>RL.12345</unitid>
         <langmaterial>
            <language langcode="eng"/>
         </langmaterial>
         <physdesc>
            <extent>100 linear_feet</extent>
         </physdesc>
         <unitdate>1900-1901</unitdate>
      </did>
      <note><p>Collection level note outside did</p></note>
      <accessrestrict>
         <head>Access to Collection</head>
         <p>Collection is open for research; access requires at least 24 hours advance notice.</p>
      </accessrestrict>
      <arrangement>
         <head>Organization of the Collection</head>
         <p>Arragement note text</p>
      </arrangement>
      <dsc>

         <c01 level="series">
            <did>
               <unitid>1</unitid>
               <unittitle>Series 1 Title</unittitle>
               <note><p>Component Note text inside did</p></note>
            </did>
            <c02 level="subseries">
               <did>
                  <unittitle>Finished Prints</unittitle>
               </did>
               <c03 level="file">
                  <did>
                     <unittitle>File title</unittitle>
                     <note>
                        <p>Component note text inside did</p>
                     </note>
                  </did>
                  <note>
                     <p>Component note text outside did</p>
                  </note>
               </c03>
            </c02>
         </c01>
      </dsc>
   </archdesc>
</ead>
ANEAD

      get_tempfile_path(src)
    end

    before(:all) do
      parsed = convert(test_doc)
      @resource = parsed.select {|r| r['jsonmodel_type'] == 'resource' }.first
      @series = parsed.select {|r| r['level'] == 'series' }.first
      @file = parsed.select {|r| r['level'] == 'file' }.first
    end

    it "should create a note for a <note> tag inside a <did> for a collection" do
      @resource['notes'].select{|n|
        n['type'] == 'odd' && n['subnotes'][0]['content'] == 'COLLECTION LEVEL NOTE INSIDE DID'
      }.should_not be_empty
    end


    it "should create a note for a <note> tag outside a <did> for a collection" do
      @resource['notes'].select{|n|
        n['type'] == 'odd' && n['subnotes'][0]['content'] == 'Collection level note outside did'
      }.should_not be_empty
    end


    it "should not create collection notes for <note> tags in components" do
      @resource['notes'].select{|n| n['type'] == 'odd'}.length.should eq(2)
    end


    it "should not create 'odd' notes for notestmt/note tags" do
      @resource['notes'].select{|n|
        n['type'] == 'odd' && n['subnotes'][0]['content'] == 'A notestmt note'
      }.should be_empty
    end


    it "should create a note for a <note> tag inside a <did> for a component" do
      @series['notes'].select{|n|
        n['type'] == 'odd' && n['subnotes'][0]['content'] == 'Component Note text inside did'
      }.should_not be_empty

      @file['notes'].select{|n|
        n['type'] == 'odd' && n['subnotes'][0]['content'] == 'Component note text inside did'
      }.should_not be_empty
    end


    it "should create a note for a <note> tag outside a <did> for a component" do
      @file['notes'].select{|n|
        n['type'] == 'odd' && n['subnotes'][0]['content'] == 'Component note text outside did'
      }.should_not be_empty
    end

  end

end
