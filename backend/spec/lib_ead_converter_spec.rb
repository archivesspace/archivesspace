# -*- coding: utf-8 -*-
require 'spec_helper'
require 'converter_spec_helper'

require_relative '../app/converters/ead_converter'

describe 'EAD converter' do
  def my_converter
    EADConverter
  end

  context 'when ead contains unitdate without date type' do
    let (:test_doc) {
      src = <<~ANEAD
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
              <unitdate normal="1907/1911" era="ce" calendar="gregorian">1907-1911</unitdate>
              <physdesc>
                <extent>5.0 Linear feet</extent>
                <extent>Resource-ContainerSummary-AT</extent>
              </physdesc>
            </did>
          </archdesc>
        <dsc>
        <c id="1" level="file">
          <unittitle>oh well<unitdate normal="1907/1911" era="ce" calendar="gregorian">1907-1911</unitdate></unittitle>
          <container id="cid1" type="Box" label="Text (B@RC0D3  )">1</container>
          <container parent="cid1" type="Folder" ></container>
        </c>
        </dsc>
        </ead>
      ANEAD

      get_tempfile_path(src)
    }

    it 'automatically parses and assigns date type to date' do
      converter = EADConverter.new(test_doc)

      converter.run

      parsed = JSON(File.read(converter.get_output_path))
      expect(parsed.length).to eq(3)
      resource = parsed.find do |entry|
        entry['jsonmodel_type'] == 'resource'
      end

      expect(resource['dates'].length).to eq 1
      expect(resource['dates'][0]['date_type']).to eq 'inclusive'

      archival_object = parsed.find do |entry|
        entry['jsonmodel_type'] == 'archival_object'
      end

      expect(archival_object['dates'].length).to eq 1
      expect(archival_object['dates'][0]['date_type']).to eq 'inclusive'
    end
  end

  context 'when ead contains unitdate with an invalid date type' do
    let (:test_doc) {
      src = <<~ANEAD
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
              <unitdate type="INVALID" normal="1907/1911" era="ce" calendar="gregorian">1907-1911</unitdate>
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
            <controlaccess><persname rules="dacs" source='local' authfilenumber='thesame'>Art, Makah</persname></controlaccess>
          </c>
        </c>
        </dsc>
        </ead>
      ANEAD

      get_tempfile_path(src)
    }

    it 'raises error when no date type is provided' do
      converter = EADConverter.new(test_doc)

      expect do
        converter.run
      end.to raise_error do |error|
        expect(error).to be_a EADConverterInvalidDateTypeError
        expect(error.message).to eq 'Invalid date type provided: INVALID; must be one of: ["bulk", "inclusive", "single"].'
      end
    end
  end

  let (:test_doc_1) {
    src = <<~ANEAD
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
            <unitdate type="inclusive" normal="1907/1911" era="ce" calendar="gregorian">1907-1911</unitdate>
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
          <controlaccess><persname rules="dacs" source='local' authfilenumber='thesame'>Art, Makah</persname></controlaccess>
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

    expect(parsed.length).to eq(6)
    expect(parsed.find {|r| r['ref_id'] == '1'}['instances'][0]['sub_container']['type_2']).to eq('Folder')
  end

  it "should find a top_container barcode in a container label" do
    converter = EADConverter.new(test_doc_1)
    converter.run
    parsed = JSON(IO.read(converter.get_output_path))

    expect(parsed.find {|r| r['ref_id'] == '1'}['instances'][0]['instance_type']).to eq('text')
    expect(parsed.find {|r|
      r['uri'] == parsed.find {|r| r['ref_id'] == '1'}['instances'][0]['sub_container']['top_container']['ref']
    }['barcode']).to eq('B@RC0D3')
  end

  it "should remove unitdate from unittitle" do
    converter = EADConverter.new(test_doc_1)
    converter.run
    parsed = JSON(IO.read(converter.get_output_path))

    expect(parsed.length).to eq(6)
    expect(parsed.find {|r| r['ref_id'] == '1'}['title']).to eq('oh well')
    expect(parsed.find {|r| r['ref_id'] == '1'}['dates'][0]['expression']).to eq("1907-1911")

  end

  it "should be link to existing agents with authority_id" do

    json = build( :json_agent_person,
                     :names => [build(:json_name_person,
                     'authority_id' => 'thesame',
                     'source' => 'local'
                     )])

    agent = AgentPerson.create_from_json(json)

    converter = EADConverter.new(test_doc_1)
    converter.run
    parsed = JSON(IO.read(converter.get_output_path))

    # these lines are ripped out of StreamingImport
    new_agent_json = parsed.find { |r| r['jsonmodel_type'] == 'agent_person' }
    record = JSONModel(:agent_person).from_hash(new_agent_json, true, false)
    new_agent = AgentPerson.ensure_exists(record, nil)


    expect(agent).to eq(new_agent)
  end


  describe "EAD Import Mappings" do
    def test_file
      File.expand_path("./examples/ead/at-tracer.xml", File.dirname(__FILE__))
    end

    before(:all) do
      parsed = convert(test_file)

      @corps = parsed.select {|rec| rec['jsonmodel_type'] == 'agent_corporate_entity'}
      @families = parsed.select {|rec| rec['jsonmodel_type'] == 'agent_family'}
      @people = parsed.select {|rec| rec['jsonmodel_type'] == 'agent_person'}
      @subjects = parsed.select {|rec| rec['jsonmodel_type'] == 'subject'}
      @digital_objects = parsed.select {|rec| rec['jsonmodel_type'] == 'digital_object'}
      @top_containers = parsed.select {|rec| rec['jsonmodel_type'] == 'top_container'}

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
          expect(v['parent']['ref']).to eq(@archival_objects[parent_key]['uri'])
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
      expect(get_subnotes_by_type(get_note(@archival_objects['12'], 'ref53'), 'note_chronology')[0]['items'][0]['event_date']).to eq('1895')

      expect(get_subnotes_by_type(get_note(@archival_objects['12'], 'ref53'), 'note_chronology')[0]['items'][1]['event_date']).to eq('1995')

      #   IF nested in <publicationstmt>
      expect(@resource['finding_aid_date']).to eq('Resource-FindingAidDate-AT')

      #   ELSE
    end

    it "maps '<physdesc>' correctly" do
      # <extent> tag mapping
      #   IF value starts with a number followed by a space and can be parsed
      expect(@resource['extents'][0]['number']).to eq("5.0")
      expect(@resource['extents'][0]['extent_type']).to eq("Linear feet")

      #   ELSE
      expect(@resource['extents'][0]['container_summary']).to eq("Resource-ContainerSummary-AT")


      # further physdesc tags - dimensions and physfacet tags are mapped appropriately
      expect(@resource['extents'][0]['dimensions']).to eq("Resource-Dimensions-AT")
      expect(@resource['extents'][0]['physical_details']).to eq("Resource-PhysicalFacet-AT")

      # physdesc altrender mapping
      expect(@resource['extents'][0]['portion']).to eq("part")
    end


    it "maps '<unitdate>' correctly" do
      expect(@resource['dates'][0]['expression']).to eq("Bulk, 1960-1970")
      expect(@resource['dates'][0]['date_type']).to eq("bulk")

      expect(@resource['dates'][1]['expression']).to eq("Resource-Title-AT")
      expect(@resource['dates'][1]['date_type']).to eq("inclusive")
    end

    it "maps '<unitid>' correctly" do
      #   IF nested in <archdesc><did>
      expect(@resource["id_0"]).to eq("Resource.ID.AT")

      #   IF nested in <c><did>
    end

    it "maps '<unittitle>' correctly" do
      #   IF nested in <archdesc><did>
      expect(@resource["title"]).to eq('Resource--<title render="italic">Title</title>-AT')
      #   IF nested in <c><did>
      expect(@archival_objects['12']['title']).to eq("Resource-C12-AT")
    end


    # FINDING AID ELEMENTS
    it "maps '<author>' correctly" do
      expect(@resource['finding_aid_author']).to eq('Finding aid prepared by Resource-FindingAidAuthor-AT')
    end

    it "maps '<descrules>' correctly" do
      expect(@resource['finding_aid_description_rules']).to eq('Describing Archives: A Content Standard')
    end

    it "maps '<eadid>' correctly" do
      expect(@resource['ead_id']).to eq('Resource-EAD-ID-AT')
    end

    it "maps '<eadid @url>' correctly" do
      expect(@resource['ead_location']).to eq('Resource-EAD-Location-AT')
    end

    it "maps '<editionstmt>' correctly" do
      expect(@resource['finding_aid_edition_statement']).to eq("Resource-FindingAidEdition-AT")
    end

    it "maps '<seriesstmt>' correctly" do
      expect(@resource['finding_aid_series_statement']).to eq("Resource-FindingAidSeries-AT")
    end

    it "maps '<sponsor>' correctly" do
      expect(@resource['finding_aid_sponsor']).to eq('Resource-Sponsor-AT')
    end

    it "maps '<subtitle>' correctly" do
    end

    it "maps '<titleproper>' correctly" do
      expect(@resource['finding_aid_title']).to eq("Resource-FindingAidTitle-AT <num>Resource.ID.AT</num>")
    end

    it "maps '<titleproper type=\"filing\">' correctly" do
      expect(@resource['finding_aid_filing_title']).to eq('Resource-FindingAidFilingTitle-AT')
    end

    it "maps '<langusage>' correctly" do
      expect(@resource['finding_aid_language_note']).to eq('Resource-FindingAidLanguage-AT')
    end

    it "maps '<langusage><language>' correctly" do
      expect(@resource['finding_aid_language']).to eq('und')
    end

    it "maps '<revisiondesc>' correctly" do
      expect(@resource['revision_statements'][0]['description']).to eq("Resource-FindingAidRevisionDescription-AT")
      expect(@resource['revision_statements'][0]['date']).to eq("Resource-FindingAidRevisionDate-AT")
    end

    # NAMES
    it "maps '<corpname>' correctly" do
      #   IF nested in <origination>
      c1 = @corps.find {|corp| corp['names'][0]['primary_name'] == "CNames-PrimaryName-AT. CNames-Subordinate1-AT. CNames-Subordiate2-AT. (CNames-Number-AT) (CNames-Qualifier-AT)"}
      expect(c1).not_to be_nil

      linked1 = @resource['linked_agents'].find {|a| a['ref'] == c1['uri']}
      expect(linked1['role']).to eq('creator')

      #   IF nested in <controlaccess>
      c2 = @corps.find {|corp| corp['names'][0]['primary_name'] == "CNames-PrimaryName-AT. CNames-Subordinate1-AT. CNames-Subordiate2-AT. (CNames-Number-AT) (CNames-Qualifier-AT) -- Archives"}
      expect(c2).not_to be_nil

      linked2 = @resource['linked_agents'].find {|a| a['ref'] == c2['uri']}
      expect(linked2['role']).to eq('subject')

      #   Respect audience attribute as set in at-tracer.xml
      expect(c1['publish']).to be_falsey
      expect(c2['publish']).to be_truthy
      #   IF @rules != NULL ==> name_corporate_entity.rules
      expect([c1, c2].map {|c| c['names'][0]['rules']}.uniq).to eq(['dacs'])
      #   IF @source != NULL ==> name_corporate_entity.source
      expect([c1, c2].map {|c| c['names'][0]['source']}.uniq).to eq(['naf'])
      #   IF @authfilenumber != NULL
      #   IF @role != NULL ==> name_corporate_entity.relator
      expect(linked1['relator']).to eq('Creator (cre)')
    end

    it "maps '<famname>' correctly" do
      #   IF nested in <origination> OR <controlaccess>
      uris = @archival_objects['06']['linked_agents'].map {|l| l['ref'] } & @families.map {|f| f['uri'] }
      links = @archival_objects['06']['linked_agents'].select {|l| uris.include?(l['ref']) }
      fams = @families.select {|f| uris.include?(f['uri']) }

      #   IF nested in <origination>
      n1 = fams.find {|f| f['uri'] == links.find {|l| l['role'] == 'creator' }['ref'] }['names'][0]['family_name']
      expect(n1).to eq("FNames-FamilyName-AT, FNames-Prefix-AT, FNames-Qualifier-AT")
      #   IF nested in <controlaccess>
      n2 = fams.find {|f| f['uri'] == links.find {|l| l['role'] == 'subject' }['ref'] }['names'][0]['family_name']
      expect(n2).to eq("FNames-FamilyName-AT, FNames-Prefix-AT, FNames-Qualifier-AT -- Pictorial works")

      #   Respect audience attribute as set in at-tracer.xml
      expect(fams.find {|f| f['uri'] == links.find {|l| l['role'] == 'creator' }['ref'] }['publish']).to be_falsey
      expect(fams.find {|f| f['uri'] == links.find {|l| l['role'] == 'subject' }['ref'] }['publish']).to be_truthy
      #   IF @rules != NULL
      expect(fams.map {|f| f['names'][0]['rules']}.uniq).to eq(['aacr'])
      #   IF @source != NULL
      expect(fams.map {|f| f['names'][0]['source']}.uniq).to eq(['naf'])
      #   IF @authfilenumber != NULL
      #   IF @role != NULL ==> name_family.relator
      expect(links[0]['relator']).to eq('Creator (cre)')
    end

    it "maps '<persname>' correctly" do
      #   IF nested in <origination>
      expect(@archival_objects['01']['linked_agents'].find {|l| @people.map {|p| p['uri'] }.include?(l['ref'])}['role']).to eq('creator')
      #   IF nested in <controlaccess>
      expect(@archival_objects['06']['linked_agents'].reverse.find {|l| @people.map {|p| p['uri'] }.include?(l['ref'])}['role']).to eq('subject')

      #   If audience attribute is not present in at-tracer.xml, default to unpublished
      expect(@people.map {|p| p['publish']}.uniq).to eq([false])
      #   IF @rules != NULL
      expect(@people.map {|p| p['names'][0]['rules']}.uniq).to eq(['local'])
      #   IF @source != NULL
      expect(@people.map {|p| p['names'][0]['source']}.uniq).to eq(['local'])
      #   IF @authfilenumber != NULL
      #   IF @role != NULL ==> name_person.relator
      expect(@archival_objects['06']['linked_agents'].reverse.find {|l| @people.map {|p| p['uri'] }.include?(l['ref'])}['relator']).to eq('Donor (dnr)')
    end

      # SUBJECTS
    it "maps '<function>' correctly" do
      #   IF nested in <controlaccess>
      subject = @subjects.find {|s| s['terms'][0]['term_type'] == 'function'}
      [@resource, @archival_objects["06"], @archival_objects["12"]].each do |a|
      expect(a['subjects'].select {|s| s['ref'] == subject['uri']}.count).to eq(1)
    end
      #   @source
      expect(subject['source']).to eq('local')
      #   ELSE
      #   IF @authfilenumber != NULL
    end

    it "maps '<genreform>' correctly" do
      #   IF nested in <controlaccess>
      subject = @subjects.find {|s| s['terms'][0]['term_type'] == 'genre_form'}
      [@resource, @archival_objects["06"], @archival_objects["12"]].each do |a|
        expect(a['subjects'].select {|s| s['ref'] == subject['uri']}.count).to eq(1)
      end
      #   @source
      expect(subject['source']).to eq('local')
      #   ELSE
      #   IF @authfilenumber != NULL
    end

    it "maps '<geogname>' correctly" do
      #   IF nested in <controlaccess>
      subject = @subjects.find {|s| s['terms'][0]['term_type'] == 'geographic'}
      [@resource, @archival_objects["06"], @archival_objects["12"]].each do |a|
        expect(a['subjects'].select {|s| s['ref'] == subject['uri']}.count).to eq(1)
      end
      #   @source
      expect(subject['source']).to eq('local')
      #   ELSE
      #   IF @authfilenumber != NULL
    end

    it "maps '<occupation>' correctly" do
      subject = @subjects.find {|s| s['terms'][0]['term_type'] == 'occupation'}
      [@resource, @archival_objects["06"], @archival_objects["12"]].each do |a|
        expect(a['subjects'].select {|s| s['ref'] == subject['uri']}.count).to eq(1)
      end
      #   @source
      expect(subject['source']).to eq('local')
      #   ELSE
      #   IF @authfilenumber != NULL
    end

    it "maps '<subject>' correctly" do
      #   IF nested in <controlaccess>
      subject = @subjects.find {|s| s['terms'][0]['term_type'] == 'topical'}
      [@resource, @archival_objects["06"], @archival_objects["12"]].each do |a|
      expect(a['subjects'].select {|s| s['ref'] == subject['uri']}.count).to eq(1)
    end
      #   @source
      expect(subject['source']).to eq('local')
      #   ELSE
      #   IF @authfilenumber != NULL
    end

    it "maps '<title>' correctly" do
      #   IF nested in <controlaccess>
      subject = @subjects.find {|s| s['terms'][0]['term_type'] == 'uniform_title'}
      [@resource, @archival_objects["06"], @archival_objects["12"]].each do |a|
      expect(a['subjects'].select {|s| s['ref'] == subject['uri']}.count).to eq(1)
    end
      #   @source
      expect(subject['source']).to eq('local')
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
      expect(note_content(get_note_by_type(@resource, 'abstract'))).to eq("Resource-Abstract-AT")
    end

    it "maps '<accessrestrict>' correctly" do
      nc = get_notes_by_type(@resource, 'accessrestrict').map {|note|
        note_content(note)
      }.flatten

      expect(nc[0]).to eq("Resource-ConditionsGoverningAccess-AT")
      expect(nc[1]).to eq("<legalstatus>Resource-LegalStatus-AT</legalstatus>")
    end

    it "maps '<accruals>' correctly" do
      expect(note_content(get_note_by_type(@resource, 'accruals'))).to eq("Resource-Accruals-AT")
    end

    it "maps '<acqinfo>' correctly" do
      expect(note_content(get_note_by_type(@resource, 'acqinfo'))).to eq("Resource-ImmediateSourceAcquisition")
    end

    it "maps '<altformavail>' correctly" do
      expect(note_content(get_note_by_type(@resource, 'altformavail'))).to eq("Resource-ExistenceLocationCopies-AT")
    end

    it "maps '<appraisal>' correctly" do
      expect(note_content(get_note_by_type(@resource, 'appraisal'))).to eq("Resource-Appraisal-AT")
    end

    it "maps '<arrangement>' correctly" do
      expect(note_content(get_note_by_type(@resource, 'arrangement'))).to eq("Resource-Arrangement-Note")
    end

    it "maps '<bioghist>' correctly" do
      expect(@archival_objects['06']['notes'].find {|n| n['type'] == 'bioghist'}['persistent_id']).to eq('ref50')
      expect(@archival_objects['12']['notes'].find {|n| n['type'] == 'bioghist'}['persistent_id']).to eq('ref53')
      expect(@resource['notes'].select {|n| n['type'] == 'bioghist'}.map {|n| n['persistent_id']}.sort).to eq(['ref47', 'ref7'])
    end

    it "maps '<custodhist>' correctly" do
      expect(note_content(get_note_by_type(@resource, 'custodhist'))).to eq("Resource--CustodialHistory-AT")
    end

    it "maps '<dimensions>' correctly" do
      expect(note_content(get_note_by_type(@resource, 'dimensions'))).to eq("Resource-Dimensions-AT")
    end

    it "maps '<fileplan>' correctly" do
      expect(note_content(get_note_by_type(@resource, 'fileplan'))).to eq("Resource-FilePlan-AT")
    end

    it "maps '<langmaterial>' with single '<language>' correctly" do
      expect(@archival_objects['06']['lang_materials'][0]['language_and_script']['language']).to eq('eng')
    end

    it "maps '<langmaterial>' with many '<language>'s correctly" do
      expect(@archival_objects['04']['lang_materials'][0]['language_and_script']['language']).to eq('eng')
      expect(@archival_objects['04']['lang_materials'][1]['language_and_script']['language']).to eq('ger')

      langmaterial = get_note_by_type(@archival_objects['04']['lang_materials'][2], 'langmaterial')
      expect(note_content(langmaterial)).to eq('Materials in English and German.')
    end

    it "doesn't create a language for an ao without a '<langmaterial>'" do
      expect(@archival_objects['09']['lang_materials']).to be_empty
    end

    it "maps '<legalstatus>' correctly" do
      expect(note_content(get_note_by_type(@resource, 'legalstatus'))).to eq("Resource-LegalStatus-AT")
    end

    it "maps '<materialspec>' correctly" do
      expect(get_note_by_type(@resource, 'materialspec')['persistent_id']).to eq("ref22")
    end

    it "maps '<note>' correctly" do
      #   IF nested in <archdesc> OR <c>

      #   ELSE, IF nested in <notestmnt>
      expect(@resource['finding_aid_note']).to eq("Resource-FindingAidNote-AT\n\nResource-FindingAidNote-AT2\n\nResource-FindingAidNote-AT3\n\nResource-FindingAidNote-AT4")
    end

    it "maps '<odd>' correctly" do
      expect(@resource['notes'].select {|n| n['type'] == 'odd'}.map {|n| n['persistent_id']}.sort).to eq(%w(ref45 ref44 ref15).sort)
    end

    it "maps '<originalsloc>' correctly" do
      expect(get_note_by_type(@resource, 'originalsloc')['persistent_id']).to eq("ref13")
    end

    it "maps '<otherfindaid>' correctly" do
      expect(get_note_by_type(@resource, 'otherfindaid')['persistent_id']).to eq("ref23")
    end

    it "maps '<physfacet>' correctly" do
      expect(note_content(get_note_by_type(@resource, 'physfacet'))).to eq("Resource-PhysicalFacet-AT")
    end

    it "maps '<physloc>' correctly" do
      expect(get_note_by_type(@resource, 'physloc')['persistent_id']).to eq("ref21")
    end

    it "maps '<phystech>' correctly" do
      expect(get_note_by_type(@resource, 'phystech')['persistent_id']).to eq("ref24")
    end

    it "maps '<prefercite>' correctly" do
      expect(get_note_by_type(@resource, 'prefercite')['persistent_id']).to eq("ref26")
    end

    it "maps '<processinfo>' correctly" do
      expect(get_note_by_type(@resource, 'processinfo')['persistent_id']).to eq("ref27")
    end

    it "maps '<relatedmaterial>' correctly" do
      expect(get_note_by_type(@resource, 'relatedmaterial')['persistent_id']).to eq("ref28")
    end

    it "maps '<scopecontent>' correctly" do
      expect(get_note_by_type(@resource, 'scopecontent')['persistent_id']).to eq("ref29")
      expect(@archival_objects['01']['notes'].find {|n| n['type'] == 'scopecontent'}['persistent_id']).to eq("ref43")
    end

    it "maps '<separatedmaterial>' correctly" do
      expect(get_note_by_type(@resource, 'separatedmaterial')['persistent_id']).to eq("ref30")
    end

    it "maps '<userestrict>' correctly" do
      expect(get_note_by_type(@resource, 'userestrict')['persistent_id']).to eq("ref9")
    end

    # Structured Notes
    it "maps '<bibliography>' correctly" do
      #     IF nested in <archdesc>  OR <c>
      expect(@resource['notes'].find {|n| n['jsonmodel_type'] == 'note_bibliography'}['persistent_id']).to eq("ref6")
      expect(@archival_objects['06']['notes'].find {|n| n['jsonmodel_type'] == 'note_bibliography'}['persistent_id']).to eq("ref48")
      expect(@archival_objects['12']['notes'].find {|n| n['jsonmodel_type'] == 'note_bibliography'}['persistent_id']).to eq("ref51")
      #     <head>
      expect(@archival_objects['06']['notes'].find {|n| n['persistent_id'] == 'ref48'}['label']).to eq("Resource--C06-Bibliography")
      #     <p>
      expect(@archival_objects['06']['notes'].find {|n| n['persistent_id'] == 'ref48'}['content'][0]).to eq("Resource--C06--Bibliography--Head")
      #     <bibref>
      expect(@archival_objects['06']['notes'].find {|n| n['persistent_id'] == 'ref48'}['items'][0]).to eq("c06 bibItem2")
      expect(@archival_objects['06']['notes'].find {|n| n['persistent_id'] == 'ref48'}['items'][1]).to eq("c06 bibItem1")
      #     other nested and inline elements
    end

    it "maps '<index>' correctly" do
      #   IF nested in <archdesc>  OR <c>
      ref52 = get_note(@archival_objects['12'], 'ref52')
      expect(ref52['jsonmodel_type']).to eq('note_index')
      #     <head>
      expect(ref52['label']).to eq("Resource-c12-Index")
      #     <p>
      expect(ref52['content'][0]).to eq("Resource-c12-index-note")
      #     <indexentry>
      #         <name>

      #         <persname>

      #         <famname>
      expect(ref52['items'].find {|i| i['type'] == 'family'}['value']).to eq('Bike 2')
      #         <corpname>
      expect(ref52['items'].find {|i| i['type'] == 'corporate_entity'}['value']).to eq('Bike 3')
      #         <subject>

      #         <function>

      #         <occupation>

      #         <genreform>
      expect(ref52['items'].find {|i| i['type'] == 'genre_form'}['value']).to eq('Bike 1')
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
      expect(get_subnotes_by_type(ref53, 'note_chronology')[0]['items'][0]['events'][0]).to eq('first date')
      expect(get_subnotes_by_type(ref53, 'note_chronology')[0]['items'][1]['events'][0]).to eq('second date')

      #         <eventgrp><event>
      ref50 = get_subnotes_by_type(get_note(@archival_objects['06'], 'ref50'), 'note_chronology')[0]
      item = ref50['items'].find {|i| i['event_date'] && i['event_date'] == '1895'}
      expect(item['events'].sort).to eq(['Event1', 'Event2'])
      #         other nested and inline elements
    end

    # WHEN @type = deflist OR @type = NULL AND <defitem> present
    it "maps '<list>' correctly" do
      ref47 = get_note(@resource, 'ref47')
      note_dl = ref47['subnotes'].find {|n| n['jsonmodel_type'] == 'note_definedlist'}
      #     <head>
      expect(note_dl['title']).to eq("Resource-BiogHist-structured-top-part3-listDefined")
      #     <defitem>	WHEN <list> @type = deflist
      #         <label>
      expect(note_dl['items'].map {|i| i['label']}.sort).to eq(['MASI SLP', 'Yeti Big Top', 'Intense Spider 29'].sort)
      #         <item>
      expect(note_dl['items'].map {|i| i['value']}.sort).to eq(['2K', '2500 K', '4500 K'].sort)
      # ELSE WHEN @type != deflist AND <defitem> not present
      ref44 = get_note(@resource, 'ref44')
      note_ol = get_subnotes_by_type(ref44, 'note_orderedlist')[0]
      #     <head>
      expect(note_ol['title']).to eq('Resource-GeneralNoteMULTIPARTLISTTitle-AT')
      #     <item>
      expect(note_ol['items'].sort).to eq(['Resource-GeneralNoteMULTIPARTLISTItem1-AT', 'Resource-GeneralNoteMULTIPARTLISTItem2-AT'])
    end

    # CONTAINER INFORMATION
    # Up to three container elements can be imported per <c>.
    # The Asterisks in the target element field below represents the numbers "1", "2", or "3" depending on which <container> tag the data is coming from

    it "maps '<container>' correctly" do
      instance = @archival_objects['02']['instances'][0]
      expect(instance['instance_type']).to eq('text')
      sub = instance['sub_container']
      expect(sub['type_2']).to eq('Folder')
      expect(sub['indicator_2']).to eq('2')

      top = @top_containers.select {|t| t['uri'] == sub['top_container']['ref']}.first
      expect(top['type']).to eq('Box')
      expect(top['indicator']).to eq('2')
    end

    # DAO's
    it "maps '<dao>' correctly" do
      expect(@digital_objects.length).to eq(12)
      links = @archival_objects['01']['instances'].select {|i| i.has_key?('digital_object')}.map {|i| i['digital_object']['ref']}
      expect(links.sort).to eq(@digital_objects.map {|d| d['uri']}.sort)
      #   @titles
      expect(@digital_objects.map {|d| d['title']}.include?("DO.Child2Title-AT")).to be_truthy
      #   @role
      uses = @digital_objects.map {|d| d['file_versions'].map {|f| f['use_statement']}}.flatten
      expect(uses.uniq.sort).to eq(["Image-Service", "Image-Master", "Image-Thumbnail"].sort)
      #   @href
      uris = @digital_objects.map {|d| d['file_versions'].map {|f| f['file_uri']}}.flatten
      expect((uris.include?('DO.Child1URI2-AT'))).to be_truthy
      #   @actuate
      expect(@digital_objects.select {|d| d['file_versions'][0]['xlink_actuate_attribute'] == 'onRequest'}.length).to eq(9)
      #   @show
      expect(@digital_objects.select {|d| d['file_versions'][0]['xlink_show_attribute'] == 'new'}.length).to eq(3)
    end

    # FORMAT & STRUCTURE
    it "maps '<archdesc>' correctly" do
      #   @level	IF != NULL
      expect(@resource['level']).to eq("collection")
      #   ELSE
      #   @otherlevel
    end

    it "maps '<c>' correctly" do
      #   @level	IF != NULL
      expect(@archival_objects['04']['level']).to eq('file')
      #   ELSE
      #   @otherlevel
      #   @id
      expect(@archival_objects['05']['ref_id']).to eq('ref34')
    end
  end

  describe "Mapping '<unitid>' without altering content" do
    def test_doc
      src = <<~ANEAD
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
      @resource = parsed.find {|r| r['jsonmodel_type'] == 'resource'}
      @components = parsed.select {|r| r['jsonmodel_type'] == 'archival_object'}
    end

    it "captures unitid content verbatim" do
      expect(@resource["id_0"]).to eq("Resource_ID/AT-thing.stuff")
    end
  end

  describe "Mapping the EAD @audience attribute" do
    def test_doc
      src = <<~ANEAD
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
      @resource = parsed.find {|r| r['jsonmodel_type'] == 'resource'}
      @components = parsed.select {|r| r['jsonmodel_type'] == 'archival_object'}
    end

    it "uses archdesc/@audience to set resource publish property" do
      expect(@resource['publish']).to be_falsey
    end

    it "uses c/@audience to set component publish property" do
      expect(@components[0]['publish']).to be_falsey
      expect(@components[1]['publish']).to be_truthy
    end
  end

  describe "@audience is mapped on <ead> as well as <archdesc>" do
    def test_doc
      src = <<~ANEAD
        <ead audience="internal">
          <archdesc level="collection">
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
      @resource = parsed.find {|r| r['jsonmodel_type'] == 'resource'}
      @components = parsed.select {|r| r['jsonmodel_type'] == 'archival_object'}
    end

    it "uses archdesc/@audience to set resource publish property" do
      expect(@resource['publish']).to be_falsey
    end

    it "uses c/@audience to set component publish property" do
      expect(@components[0]['publish']).to be_falsey
      expect(@components[1]['publish']).to be_truthy
    end
  end


  describe "Non redundant mapping" do
    def test_doc
      src = <<~ANEAD
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
      @resource = parsed.find {|r| r['jsonmodel_type'] == 'resource'}
      @component = parsed.find {|r| r['jsonmodel_type'] == 'archival_object'}
    end

    it "only maps <language> content to one place" do
      expect(@resource['lang_materials'][0]['language_and_script']['language']).to eq 'eng'
      expect(@resource['lang_materials'].map {|l| l['notes']}.compact.reject {|e|  e == [] }).to be_empty

      expect(@component['lang_materials'][0]['language_and_script']['language']).to eq 'eng'
      expect(@component['lang_materials'].map {|l| l['notes']}.compact.reject {|e|  e == [] }).to be_empty
    end

    it "maps <head> tag to note label, but not to note content" do
      n = get_note_by_type(@resource, 'accruals')
      expect(n['label']).to eq('foo')
      expect(note_content(n)).not_to match(/foo/)
    end

  end

  # https://www.pivotaltracker.com/story/show/65722286
  describe "Mapping the unittitle tag" do
    def test_doc
      src = <<~ANEAD
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
      resource = json.find {|r| r['jsonmodel_type'] == 'resource'}
      expect(resource['title']).to eq("一般行政文件 [2]")
    end

  end


  describe "Mapping the langmaterial tag" do
    def lang_doc1
      src = <<~ANEAD
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

    def lang_doc2
      src = <<~ANEAD
        <ead>
          <archdesc level="collection" audience="internal">
            <did>
              <unittitle>Title</unittitle>
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

    it 'should map the langcode to language, and the language text to a note' do
      json = convert(lang_doc1)
      resource = json.select {|rec| rec['jsonmodel_type'] == 'resource'}.last
      expect(resource['lang_materials'][0]['language_and_script']['language']).to eq('eng')

      langmaterial = get_note_by_type(resource['lang_materials'][1], 'langmaterial')
      expect(note_content(langmaterial)).to eq('English')
    end

    it "creates a language when no '<langmaterial>' at resource level" do
      json = convert(lang_doc2)
      resource = json.select {|rec| rec['jsonmodel_type'] == 'resource'}.last
      expect(resource['lang_materials'][0]['language_and_script']['language']).to eq('und')
    end
  end


  describe "extent and physdesc mapping logic" do
    def doc1
      src = <<~ANEAD
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
      src = <<~ANEAD
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
      src = <<~ANEAD
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
      expect(@resource1['extents'].count).to eq(2)
      expect(@resource2['extents'].count).to eq(1)
    end

    it "puts additional extent records in extent.container_summary" do
      expect(@resource2['extents'][0]['container_summary']).to eq('1 record carton')
    end

    it "maps a physdec node to a note unless it only contains extent tags" do
      expect(get_notes_by_type(@resource1, 'physdesc').length).to eq(0)
      expect(get_notes_by_type(@resource2, 'physdesc').length).to eq(0)
      expect(get_notes_by_type(@resource3, 'physdesc').length).to eq(1)
    end

  end

  describe "DAO and DAOGROUPS" do
     before(:all) do
       test_file = File.expand_path("./examples/ead/ead-dao-test.xml", File.dirname(__FILE__))
       parsed = convert(test_file)

       @digital_objects = parsed.select {|rec| rec['jsonmodel_type'] == 'digital_object'}
       @notes = @digital_objects.inject([]) { |c, rec| c + rec["notes"] }
       @resources = parsed.select {|rec| rec['jsonmodel_type'] == 'resource'}
       @resource = @resources.last
       @archival_objects = parsed.select {|rec| rec['jsonmodel_type'] == 'archival_object'}
       @file_versions = @digital_objects.inject([]) { |c, rec| c + rec["file_versions"] }
     end

     it "should make all the digital, archival objects and resources" do
       expect(@digital_objects.length).to eq(5)
       expect(@archival_objects.length).to eq(8)
       expect(@resources.length).to eq(1)
       expect(@file_versions.length).to eq(11)
     end

     it "should honor xlink:show and xlink:actuate from arc elements" do
       expect(@file_versions[0..2].map {|fv| fv['xlink_actuate_attribute']}).to eq(%w|onLoad onRequest onLoad|)
       expect(@file_versions[0..2].map {|fv| fv['xlink_show_attribute']}).to eq(%w|new embed new|)
     end

     it "should turn all the daodsc into notes" do
       expect(@notes.length).to eq(3)
       notes_content = @notes.inject([]) { |c, note| c + note["content"] }
       expect(notes_content).to include('<p>first daogrp</p>')
       expect(notes_content).to include('<p>second daogrp</p>')
       expect(notes_content).to include('<p>dao no grp</p>')
     end
   end

  describe "EAD With frontpage" do
    before(:all) do
      test_file = File.expand_path("./examples/ead/vmi.xml", File.dirname(__FILE__))

      @parsed = convert(test_file)
      @resource = @parsed.select {|rec| rec['jsonmodel_type'] == 'resource'}.last
      @archival_objects = @parsed.select {|rec| rec['jsonmodel_type'] == 'archival_object'}
    end

    it "shouldn't overwrite the finding_aid_title/titleproper from frontpage" do
      expect(@resource["finding_aid_title"]).to eq("Proper Title")
      expect(@resource["finding_aid_title"]).not_to eq("TITLEPAGE titleproper")
    end

    it "should not have any of the titlepage content" do
      expect(@parsed.to_s).not_to include("TITLEPAGE")
    end

    it "should have instances grouped by their container @id/@parent relationships" do
      instances = @archival_objects.first["instances"]
      expect(instances.length).to eq(3)

      expect(instances[1]['sub_container']['type_2']).to eq('Folder')
      expect(instances[1]['sub_container']['indicator_2']).to eq('3')
      expect(instances[2]['sub_container']['type_2']).to eq('Cassette')
      expect(instances[2]['sub_container']['indicator_2']).to eq('4')
      expect(instances[2]['sub_container']['type_3']).to eq('Cassette')
      expect(instances[2]['sub_container']['indicator_3']).to eq('5')
    end
  end

  # See https://archivesspace.atlassian.net/browse/AR-1134
  describe "Mapping physdesc tags" do
    def test_doc
      src = <<~ANEAD
        <ead>
          <archdesc level="collection" audience="internal">
            <did>
              <unittitle>一般行政文件 [2]</unittitle>
              <unitid>Resource.ID.AT</unitid>
              <unitdate type="inclusive" normal="1907/1911" era="ce" calendar="gregorian">1907-1911</unitdate>
              <physdesc>
                <extent>5.0 Linear feet</extent>
                <extent>Resource-ContainerSummary-AT</extent>
              </physdesc>
            </did>
          </archdesc>
        <dsc>
        <c level="file">
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
      expect(@record['extents'].length).to eq(1)
    end

    it "should not create any notes from physdesc data" do
      expect(@record['notes'].length).to eq(0)
    end

    it "should map physdesc/dimensions to extent.dimensions" do
      expect(@record['extents'][0]['dimensions']).to eq('8 x 10 inches')
    end

    it "should map physdesc/physfacet to extent.physical_details" do
      expect(@record['extents'][0]['physical_details']).to eq('gelatin silver')
    end

    let (:records_with_extents) {
      records = convert(File.join(File.dirname(__FILE__), 'fixtures', 'ead_with_extents.xml'))
      Hash[records.map {|rec| [rec['title'], rec]}]
    }

    it "maps no extent, single dimensions, single physfacet to notes" do
      rec = records_with_extents.fetch('No extent, single dimensions, single physfacet')

      expect(rec['extents']).to be_empty
      expect(rec['notes'][0]['content']).to eq(['gelatin silver'])
      expect(rec['notes'][1]['subnotes'][0]['content']).to eq('8 x 10 inches')
    end

    it "maps single extent and single dimensions to extent record" do
      rec = records_with_extents.fetch('Test single extent and single dimensions')

      expect(rec['extents'].length).to eq(1)
      expect(rec['extents'][0]['extent_type']).to eq('photograph')
      expect(rec['extents'][0]['dimensions']).to eq('8 x 10 inches')
    end

    it "maps single extent and single physfacet to extent record" do
      rec = records_with_extents.fetch('Test single extent and single physfacet')

      expect(rec['extents'].length).to eq(1)
      expect(rec['extents'][0]['extent_type']).to eq('photograph')
      expect(rec['extents'][0]['number']).to eq('1')
      expect(rec['extents'][0]['portion']).to eq('whole')
      expect(rec['extents'][0]['physical_details']).to eq('gelatin silver')
    end

    it "maps single extent, single dimensions, single physfacet to extent record" do
      rec = records_with_extents.fetch('Test single extent, single dimensions, single physfacet')

      expect(rec['extents'].length).to eq(1)
      expect(rec['extents'][0]['extent_type']).to eq('photograph')
      expect(rec['extents'][0]['number']).to eq('1')
      expect(rec['extents'][0]['portion']).to eq('whole')
      expect(rec['extents'][0]['physical_details']).to eq('gelatin silver')
      expect(rec['extents'][0]['dimensions']).to eq('8 x 10 inches')
    end

    it "maps single extent and two physfacet to extent record" do
      rec = records_with_extents.fetch('Test single extent and two physfacet')

      expect(rec['extents'].length).to eq(1)
      expect(rec['extents'][0]['extent_type']).to eq('photograph')
      expect(rec['extents'][0]['number']).to eq('1')
      expect(rec['extents'][0]['portion']).to eq('whole')
      expect(rec['extents'][0]['physical_details']).to eq('black and white; gelatin silver')
    end

    it "maps single extent and two dimensions to extent record" do
      rec = records_with_extents.fetch('Test single extent and two dimensions')

      expect(rec['extents'].length).to eq(1)
      expect(rec['extents'][0]['extent_type']).to eq('photograph')
      expect(rec['extents'][0]['number']).to eq('1')
      expect(rec['extents'][0]['portion']).to eq('whole')
      expect(rec['extents'][0]['dimensions']).to eq('8 x 10 inches (photograph); 11 x 14 inches (support)')
    end

    it "maps text physdesc element to note" do
      rec = records_with_extents.fetch('Physdesc only')

      expect(rec['extents']).to be_empty
      expect(rec['notes']).not_to be_empty
      expect(rec['notes'][0]['content']).to eq(["1 photograph: 8 x 10 inches (photograph) 11 x 14 inches (support)"])
    end

  end

  # See https://archivesspace.atlassian.net/browse/AR-1373
  describe "Mapping note tags" do
    def test_doc
      src = <<~ANEAD
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
                 <unitdate type="inclusive">1900-1901</unitdate>
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
      expect(@resource['notes'].select {|n|
        n['type'] == 'odd' && n['subnotes'][0]['content'] == 'COLLECTION LEVEL NOTE INSIDE DID'
      }).not_to be_empty
    end


    it "should create a note for a <note> tag outside a <did> for a collection" do
      expect(@resource['notes'].select {|n|
        n['type'] == 'odd' && n['subnotes'][0]['content'] == 'Collection level note outside did'
      }).not_to be_empty
    end


    it "should not create collection notes for <note> tags in components" do
      expect(@resource['notes'].select {|n| n['type'] == 'odd'}.length).to eq(2)
    end


    it "should not create 'odd' notes for notestmt/note tags" do
      expect(@resource['notes'].select {|n|
        n['type'] == 'odd' && n['subnotes'][0]['content'] == 'A notestmt note'
      }).to be_empty
    end


    it "should create a note for a <note> tag inside a <did> for a component" do
      expect(@series['notes'].select {|n|
        n['type'] == 'odd' && n['subnotes'][0]['content'] == 'Component Note text inside did'
      }).not_to be_empty

      expect(@file['notes'].select {|n|
        n['type'] == 'odd' && n['subnotes'][0]['content'] == 'Component note text inside did'
      }).not_to be_empty
    end


    it "should create a note for a <note> tag outside a <did> for a component" do
      expect(@file['notes'].select {|n|
        n['type'] == 'odd' && n['subnotes'][0]['content'] == 'Component note text outside did'
      }).not_to be_empty
    end

  end

  describe 'Mapping revision statement publish' do
    def test_doc
      src = <<~ANEAD
        <?xml version="1.0" encoding="utf-8"?>
        <ead xmlns="urn:isbn:1-931666-22-9" xmlns:xlink="http://www.w3.org/1999/xlink"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd">
          <eadheader countryencoding="iso3166-1" dateencoding="iso8601" langencoding="iso639-2b"
            repositoryencoding="iso15511">
            <eadid/>
            <filedesc>
              <titlestmt>
                <titleproper>Resource with one unpublished revision
                    statement<num>unpub.revision.statement</num></titleproper>
              </titlestmt>
              <publicationstmt>
                <publisher>Your Name Here Special Collections</publisher>
              </publicationstmt>
            </filedesc>
            <profiledesc>
              <creation>This finding aid was produced using ArchivesSpace on <date>2019-04-02 15:41:55
                  +0000</date>.</creation>
            </profiledesc>
            <revisiondesc>
              <change audience="internal">
                <date>Unpublished revision date</date>
                <item>Unpublished revision description</item>
              </change>
              <change>
                <date>Published revision date</date>
                <item>Published revision description</item>
              </change>
            </revisiondesc>
          </eadheader>
          <archdesc level="collection">
            <did>
              <langmaterial>
                <language langcode="eng">English</language>
              </langmaterial>
              <repository>
                <corpname>Your Name Here Special Collections</corpname>
              </repository>
              <unittitle>Resource with one unpublished revision statement</unittitle>
              <unitid>unpub.revision.statement</unitid>
              <physdesc altrender="whole">
                <extent altrender="materialtype spaceoccupied">1 Cassettes</extent>
              </physdesc>
              <unitdate type="inclusive" normal="2019-04-11/2019-04-11">2019-04-11</unitdate>
            </did>
            <dsc/>
          </archdesc>
        </ead>
      ANEAD

      get_tempfile_path(src)
    end

    before(:all) do
      parsed = convert(test_doc)
      @revision_statements = parsed.select {|r| r['jsonmodel_type'] == 'resource' }.first['revision_statements']
    end

    it "creates an unpublished revision statement for a <change> tag with audience=internal" do
      rs = @revision_statements[0]
      expect(rs['description']).to eq("Unpublished revision description")
      expect(rs['publish']).to be_falsey
    end

    it "creates a publihed revision statement for a <change> tag without audience=internal" do
      rs = @revision_statements[1]
      expect(rs['description']).to eq("Published revision description")
      expect(rs['publish']).to be_truthy
    end
  end

  describe "ARKs" do
    def test_doc
      src = <<~ANEAD
        <?xml version="1.0" encoding="utf-8"?>
        <ead xmlns="urn:isbn:1-931666-22-9" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd">
            <eadheader countryencoding="iso3166-1" dateencoding="iso8601" langencoding="iso639-2b" repositoryencoding="iso15511">
                <eadid url="http://archivesspace.org/ark:/12345/96944aa7-7d78-4be3-b013-9d196d7e8725">Testing</eadid>
            </eadheader>
            <archdesc level="collection">
                <did>
                    <langmaterial>
                        <language langcode="eng">English</language>
                    </langmaterial>
                    <repository>
                        <corpname>My Special Collections</corpname>
                    </repository>
                    <unittitle>ARK test resource</unittitle>
                    <unitid>arktestrecord12345</unitid>
                    <unitid type="ark">
                        <extref xlink:href="http://archivesspace.org/ark:/12345/96944aa7-7d78-4be3-b013-9d196d7e8725"/>
                    </unitid>
                    <unitid type="ark-superseded">
                        <extref xlink:href="http://archivesspace.org/ark:/12345/3e578efe-a432-4d12-8c40-fd62c9e6e3e9"/>
                    </unitid>
                    <physdesc altrender="whole">
                        <extent altrender="materialtype spaceoccupied">1 Cassettes</extent>
                    </physdesc>
                    <unitdate type="inclusive" normal="2021-09-14/2021-09-30">2021-09-14</unitdate>
                </did>
                <dsc>
                    <c id="1" level="file">
                        <unittitle>a thing</unittitle>
                        <unitid type="ark">
                            <extref xlink:href="http://archivesspace.org/ark:/12345/11256ebb-4377-4ad2-aa9f-6a1638bef028"/>
                        </unitid>
                        <unitid type="ark-superseded">
                            <extref xlink:href="http://archivesspace.org/ark:/12345/b4a11bcc-0b1e-4a83-b8f7-cac7a821e1e8"/>
                        </unitid>
                    </c>
                </dsc>
            </archdesc>
        </ead>
      ANEAD

      get_tempfile_path(src)
    end

    before(:all) do
      @pre_arks_enabled = AppConfig[:arks_enabled]
      @pre_arks_allow_external_arks = AppConfig[:arks_allow_external_arks]

      AppConfig[:arks_enabled] = true
      AppConfig[:arks_allow_external_arks] = true

      parsed = convert(test_doc)
      @resource = parsed.select {|r| r['jsonmodel_type'] == 'resource' }.first
      @child = parsed.select {|r| r['level'] == 'file' }.first
    end

    after(:all) do
      AppConfig[:arks_enabled] = @pre_arks_enabled
      AppConfig[:arks_allow_external_arks] = @pre_arks_allow_external_arks
    end

    it "imported to resource" do
      expect(@resource['import_current_ark']).to eq('http://archivesspace.org/ark:/12345/96944aa7-7d78-4be3-b013-9d196d7e8725')
      expect(@resource['import_previous_arks']).to eq(['http://archivesspace.org/ark:/12345/3e578efe-a432-4d12-8c40-fd62c9e6e3e9'])
    end

    it "imported to archival object" do
      expect(@child['import_current_ark']).to eq('http://archivesspace.org/ark:/12345/11256ebb-4377-4ad2-aa9f-6a1638bef028')
      expect(@child['import_previous_arks']).to eq(['http://archivesspace.org/ark:/12345/b4a11bcc-0b1e-4a83-b8f7-cac7a821e1e8'])
    end

    it "should not be included as an external id" do
      expect(@resource['external_ids']).to be_empty
      expect(@child['external_ids']).to be_empty
    end

    it "should not be included as the component_id" do
      expect(@resource['component_id']).to_not eq('http://archivesspace.org/ark:/12345/96944aa7-7d78-4be3-b013-9d196d7e8725')
      expect(@child['component_id']).to_not eq('http://archivesspace.org/ark:/12345/11256ebb-4377-4ad2-aa9f-6a1638bef028')
    end
  end

end
