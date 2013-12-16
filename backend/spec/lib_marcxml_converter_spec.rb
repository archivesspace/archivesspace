require 'spec_helper'
require_relative '../app/converters/marcxml_converter.rb'

describe 'MARCXML converter' do

  let (:test_doc_1) {
    src = <<END
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <collection xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd" xmlns="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <record>
              <leader>00000npc a2200000 u 4500</leader>
              <controlfield tag="008">130109i19601970xx                  eng d</controlfield>
              <datafield tag="040" ind2=" " ind1=" ">
                  <subfield code="a">Repositories.Agency Code-AT</subfield>
                  <subfield code="b">eng</subfield>
                  <subfield code="c">Repositories.Agency Code-AT</subfield>
                  <subfield code="e">dacs</subfield>
              </datafield>
              <datafield tag="041" ind2=" " ind1="0">
                  <subfield code="a">eng</subfield>
              </datafield>
              <datafield tag="099" ind2=" " ind1=" ">
                  <subfield code="a">Resource.ID.AT</subfield>
              </datafield>
              <datafield tag="245" ind2=" " ind1="1">
                  <subfield code="a">SF A</subfield>
                  <subfield code="c">SF C</subfield>
                  <subfield code="h">SF H</subfield>
                  <subfield code="n">SF N</subfield>
              </datafield>
              <datafield tag="300" ind2=" " ind1=" ">
                  <subfield code="a">5.0 Linear feet</subfield>
                  <subfield code="f">Resource-ContainerSummary-AT</subfield>
              </datafield>
              <datafield tag="342" ind2="5" ind1="1">
                  <subfield code="i">SF I</subfield>
                  <subfield code="p">SF P</subfield>
                  <subfield code="q">SF Q</subfield>
              </datafield>
              <datafield tag="510" ind2=" " ind1="2">
                  <subfield code="3">SF 3</subfield>
                  <subfield code="c">SF C</subfield>
                  <subfield code="x">SF X</subfield>
              </datafield>
              <datafield tag="630" ind2=" " ind1="2">
                  <subfield code="d">SF D</subfield>
                  <subfield code="f">SF F</subfield>
                  <subfield code="x">SF X</subfield>
                  <subfield code="2">SF 2</subfield>
              </datafield>
              <datafield tag="691" ind2=" " ind1="2">
                  <subfield code="d">SF D</subfield>
                  <subfield code="a">SF A</subfield>
                  <subfield code="x">SF X</subfield>
                  <subfield code="3">SF 3</subfield>
              </datafield>

          </record>
     </collection>
END

    tmp = Tempfile.new("doc1")
    tmp.write(src)
    tmp.close
    tmp.path
  }


  before(:all) do
    converter = MarcXMLConverter.new(test_doc_1)
    converter.run
    parsed = JSON.parse(IO.read(converter.get_output_path))
    @resource = parsed.last
    @subjects = parsed.select{|r| r['jsonmodel_type'] == 'subject'}

  end


  it "maps field 245 to resource['title']" do
    @resource['title'].should eq("SF A : [SF H] SF N / SF C")
  end

  it "maps field 342 to resource['notes']" do
    note = @resource['notes'].find{|n| n['type'] == 'odd'}
    note['subnotes'][0]['content'].should eq("False easting--SF I; Zone identifier--SF P; Ellipsoid name--SF Q")
    note['label'].should eq("Geospatial Reference Dimension: Vertical coordinate system--Geodetic model")
  end

  # "Indicator 1 {@ind1} --$3: $a : $b : $c ($x)"
  it "maps field 510 to resource['notes']" do
    note = @resource['notes'].find{|n| n['jsonmodel_type'] == 'note_bibliography'}
    note['content'][0].should eq("Indicator 1 Coverage is selective -- SF 3: SF C (SF X)")
  end

  it "maps field 630 to resource['subjects']" do
    @subjects[1]['terms'].map {|t| t['term_type']}.sort.should eq(%w(uniform_title topical).sort)
  end

  it "maps field 69* to resource['subjects']" do
    @subjects[0]['terms'][0]['term'].should eq("SF 3--SF A--SF D--SF X")
  end

  it "maps field 040 subfield e to resource.finding_aid_description_rules" do
    @resource['finding_aid_description_rules'].should eq("dacs")
  end


  describe "MARC import mappings" do


    def convert_test_file
      converter = MarcXMLConverter.new(File.expand_path("../../migrations/examples/marc/at-tracer-marc-1.xml", File.dirname(__FILE__)))
      converter.run
      parsed = JSON(IO.read(converter.get_output_path))

      @corps = parsed.select {|rec| rec['jsonmodel_type'] == 'agent_corporate_entity'}
      @families = parsed.select {|rec| rec['jsonmodel_type'] == 'agent_family'}

      @families.instance_eval do
        def by_name(name)
          self.select {|f| f['names'][0]['family_name'] == name}
        end

        def uris_for_name(name)
          by_name(name).map {|f| f['uri']}
        end
      end

      @people = parsed.select {|rec| rec['jsonmodel_type'] == 'agent_person'}
      @people.instance_eval do
        def by_name(name)
          self.select {|p| p['names'][0]['primary_name'] == name}
        end

        def uris_for_name(name)
          by_name(name).map {|f| f['uri']}
        end

        def by_num(id)
          @people.find {|p| p['test_id'] == id}
        end
      end

      @subjects = parsed.select {|rec| rec['jsonmodel_type'] == 'subject'}

      @resource = parsed.select {|rec| rec['jsonmodel_type'] == 'resource'}.last
      @notes = @resource['notes']
    end

    before(:all) do
      convert_test_file
    end

    # Tag ind1  ind2  Subfield code   Object  Property
    # 008
    #         The 008 is a string of values derived from the fixed fields of the MARC record.  Each fixed field value has a zero-indexed absolute position on in the string.
    # Positions 0-5 represent the date the record was created.
    # Position 6 is a single alpha character representing the date type.
    # Positions 7-14 represent the date information (two four digit dates in most cases).
    # Positions 35-37 represent a three-letter language code taken from the MARC Code List for Languages. Three fill characters ('|||' or 3 spaces) may be used if no attempt was made to code the language.
    #
    # For example, given the 008 string:
    # 880812s1967    xxu                 eng d
    #
    # This represents a single date with the year 1967 and a resource in English (code 'eng').
    #
    #       position 6  IF position 6 = 'i', date.date_type is "inclusive"  date  date_type
    #         IF position 6 = 'k', date.date_type is "bulk"
    #         IF position 6 = 's', date.date_type is "single"
    #       positions 7-10    date  begin
    #       positions 11-14   date  end
    #       positions 35-37   resource  language
    # Sample "130109i19601970xx                  eng d"
    it "maps field 008 correctly" do
      @resource['language'].should eq('eng')
      date = @resource['dates'].find {|d| d['date_type'] == 'inclusive' && d['begin'] == '1960' && d['end'] == '1970'}
      date.should_not be_nil
    end

    it "maps datafield[@tag='600'] to agent_family and agent_person linked as 'subject'" do
      links = @resource['linked_agents'].select {|a| @families.uris_for_name('FNames-FamilyName-AT').include?(a['ref'])}
      links.select {|l| l['role'] == 'subject'}.count.should eq(1)

      links = @resource['linked_agents'].select {|a| @people.uris_for_name('PNames-Primary-AT, PNames-RestOfName-AT').include?(a['ref'])}
      links.select {|l| l['role'] == 'subject'}.count.should eq(1)
    end

    it "maps datafield[@tag='700'][@ind1='1'][@subfield[@code='e']='Donor (dnr)'] to agent_person linked as 'source'" do
      links = @resource['linked_agents'].select {|a| @people.uris_for_name('PNames-Primary-AT, PNames-RestOfName-AT').include?(a['ref'])}
      links.select {|l| l['role'] == 'source'}.count.should eq(1)
    end

    it "maps datafield[@tag='700'][@ind1='1'][@subfield[@code='e']] to agent_person linked as 'creator'" do
      links = @resource['linked_agents'].select {|a| @people.uris_for_name('PNames-Primary-AT, PNames-RestOfName-AT').include?(a['ref'])}
      links.select {|l| l['role'] == 'creator'}.count.should eq(1)
    end

    it "maps datafield[@tag='600']/subfield[@code='2'] to agent_(family|person).names[].source" do
      @families.select {|f| f['names'][0]['source'] == 'NACO Authority File'}.count.should eq(1)
    end

    it "maps datafield[@tag='600' or @tag='700']/subfield[@code='b'] to agent_(family|person).names[].number" do
      @people.select{|p| p['names'][0]['number'] == 'PName-Number-AT'}.count.should eq(3)
    end

    it "maps datafield[@tag='600' or @tag='700']/subfield[@code='c'] to agent_person.names[].title or agent_family.names[].qualifier" do
      @people.select{|p| p['names'][0]['title'] == 'PNames-Prefix-AT, PNames-Title-AT, PNames-Suffix-AT'}.count.should eq(3)
      @families.select{|f| f['names'][0]['qualifier'].match(/^FNames-Prefix-AT/)}.count.should eq(3)
    end

    it "maps datafield[@tag='600' or @tag='700']/subfield[@code='d'] to agent_(family|person).names[].use_dates[].expression" do
      @people.select{|p| p['names'][0]['use_dates'][0]['expression'] == 'PNames-Dates-AT'}.count.should eq(3)
    end

    it "prepends and maps datafield[@tag='600']/subfield[@code='g'] to agent_(family|person).names[].qualifier" do
      @people.select{|p| p['names'][0]['qualifier'].match(/Miscellaneous information: PNames-Qualifier-AT\./)}.count.should eq(3)
    end

    it "maps datafield[@tag='110' or @tag='610' or @tag='710'] to agent_corporate_entity" do
      @corps.count.should eq(3)
    end

    it "maps datafield[@tag='110' or @tag='610' or @tag='710'] to agent_corporate_entity with source 'ingest'" do
      @corps.select {|f| f['names'][0]['source'] == 'ingest'}.count.should eq(2)
    end

    it "maps datafield[@tag='610']/subfield[@code='2'] to agent_corporate_entity.names[].source" do
      @corps.select {|f| f['names'][0]['source'] == 'NACO Authority File'}.count.should eq(1)
    end

    it "maps datafield[@tag='610'] to agent_corporate_entity linked as 'subject'" do
      links = @resource['linked_agents'].select {|a| @corps.map{|c| c['uri']}.include?(a['ref'])}
      links.select {|l| l['role'] == 'subject'}.count.should eq(1)
    end

    it "maps datafield[@tag='110'][subfield[@code='e']='Creator (cre)'] and datafield[@tag='710'][subfield[@code='e']='source'] to agent_corporate_entity linked as 'creator'" do
      links = @resource['linked_agents'].select {|a| @corps.map{|c| c['uri']}.include?(a['ref'])}
      links.select {|l| l['role'] == 'creator'}.count.should eq(2)
    end

    it "maps datafield[@tag='610' or @tag='110' or @tag='710']/subfield[@tag='a'] to agent_corporate_entity.names[].primary_name" do
      @corps.select{|c| c['names'][0]['primary_name'] == 'CNames-PrimaryName-AT'}.count.should eq(3)
    end

    it "maps datafield[@tag='610' or @tag='110' or @tag='710']/subfield[@tag='b'][1] to agent_corporate_entity.names[].subordinate_name_1" do
      @corps.select{|c| c['names'][0]['subordinate_name_1'] == 'CNames-Subordinate1-AT'}.count.should eq(3)
    end

    it "maps datafield[@tag='610' or @tag='110' or @tag='710']/subfield[@tag='b'][2] to agent_corporate_entity.names[].subordinate_name_2" do
      # not a typo, per the tracer DB:
      @corps.select{|c| c['names'][0]['subordinate_name_2'] == 'CNames-Subordiate2-AT'}.count.should eq(3)
    end

    it "maps datafield[@tag='610' or @tag='110' or @tag='710']/subfield[@tag='b'] to linked_agent_corporate_entity.relator" do
      links = @resource['linked_agents'].select {|a| @corps.map{|c| c['uri']}.include?(a['ref'])}
      links.map {|l| l['relator']}.compact.sort.should eq(['source','Creator (cre)'].sort)
    end

    it "prepends and maps datafield[@tag='110' or @tag='610' or @tag='710']/subfield[@code='g'] to agent_corporate_entity.names[].qualifier" do
      @corps.select{|p| p['names'][0]['qualifier'] == "Miscellaneous information: CNames-Qualifier-AT."}.count.should eq(3)
    end

    it "maps datafield[@tag='110' or @tag='610' or @tag='710']/subfield[@code='n'] to agent_corporate_entity.names[].number" do
      @corps.select{|p| p['names'][0]['number'] == 'CNames-Number-AT'}.count.should eq(3)
    end

    it "maps datafield[@tag='245'] to resource.title using template '$a : $b [$h] $k , $n , $p , $s / $c' " do
      @resource['title'].should eq("Resource--Title-AT")
    end

    it "maps datafield[@tag='245']/subfield[@code='f' or @code='g'] to resources.dates[]" do
      @resource['dates'][1]['expression'].should eq("Resource-Date-Expression-AT-1960 - 1970")
    end

    it "maps datafield[@tag='300'] to resource.extents[].container_summary using template '$3: $a ; $b, $c ($e, $f, $g)'" do
      @resource['extents'][0]['container_summary'].should eq("5.0 Linear feet (Resource-ContainerSummary-AT)")
    end

    it "maps datafield[@tag='351'] to resource.notes[] using template '$3: $a. $b. $c'" do
      note_content(@notes[0]).should eq('Resource-Arrangement-Note Resource-FilePlan-AT.')
    end

    it "maps datafield[@tag='500'] to resource.notes[] using template '$3: $a'" do
      note_content(@notes[5]).should eq('Material Specific Details:Resource-MaterialSpecificDetails-AT')
    end

    it "maps datafield[@tag='506'] to resource.notes[] using template '$3: $a, $b, $c, $d, $e, $u.'" do
      note_content(@notes[11]).should eq('Resource-ConditionsGoverningAccess-AT.')
    end

    it "maps datafield[@tag='520'] to resource.notes[] using template '$3:  $a. ($u) [line break] $b.'" do
      note_content(@notes[12]).should eq('Resource-Abstract-AT.')
      @notes[12]['label'].should eq("Summary")
    end

    it "maps datafield[@tag='524'] to resource.notes[] using template '$3: $a. $2.'" do
      note_content(@notes[14]).should eq('Resource-PreferredCitation-AT.')
    end

    it "maps datafield[@tag='535'] to resource.notes[] using template 'Indicator 1 [Holder of originals | Holder of duplicates]: $3--$a. $b, $c. $d ($g).'" do
      note_content(@notes[16]).should eq('Indicator 1 Holder of originals: Resource-ExistenceLocationOriginals-AT.')
    end

    it "maps datafield[@tag='540'] to resource.notes[] using template '$3: $a. $b. $c. $d ($u).'" do
      note_content(@notes[17]).should eq('Resource-ConditionsGoverningUse-AT.')
    end

    it "maps datafield[@tag='541'] to resource.notes[] using template '#3: Source of acquisition--$a. Address--$b. Method of acquisition--$c; Date of acquisition--$d. Accession number--$e: Extent--$n; Type of unit--$o. Owner--$f. Purchase price--$h.'" do
      note_content(@notes[19]).should eq('Source of acquisition--Resource-ImmediateSourceAcquisition.')
    end

    it "maps datafield[@tag='544'] to resource.notes[] using template 'Indicator 1 [ Associated Materials | Related Materials]--$3: Title--$t. Custodian--$a: Address--$b, Country--$c. Provenance--$e. Note--$n.'" do
      note_content(@notes[20]).should eq('Custodian--Resource-RelatedArchivalMaterials-AT.')
    end

    it "maps datafield[@tag='545'] to resource.notes[] using template '$a ($u). [Line break] $b.'" do
      note_content(@notes[21]).should eq('Resource-BiographicalHistorical-AT.')
    end

    it "maps datafield[@tag='546'] to resource.notes[] using template '$3: $a ($b).'" do
      note_content(@notes[22]).should eq('Resource-LanguageMaterials-AT.')
      @notes[22]['label'].should eq('Language of Material')
    end

    it "maps datafield[@tag='561'] to resource.notes[] using template '$3: $a.'" do
      note_content(@notes[23]).should eq('Resource--CustodialHistory-AT.')
    end

    it "maps datafield[@tag='630'] to subject" do
      s = @subjects.select{|s| s['terms'][0]['term'] == 'Subjects--Uniform Title--AT'}
      s.count.should eq(1)
      s.last['source'].should eq('Local sources')
    end

    it "maps datafield[@tag='650'] to subject" do
      s = @subjects.select{|s| s['terms'][0]['term'] == 'Subjects--Topical Term--AT'}
      s.last['terms'][0]['term_type'].should eq('topical')
      s.count.should eq(1)
      s.last['source'].should eq('Local sources')
    end
  end

end
