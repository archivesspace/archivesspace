require 'spec_helper'
require 'converter_spec_helper'

require_relative '../app/converters/marcxml_converter'

describe 'MARCXML converter' do

  def my_converter
    MarcXMLConverter
  end

  describe "Basic MARCXML to ASPACE mappings" do
    def test_doc_1
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
                  <subfield code="x">SF XII</subfield>
                  <subfield code="3">SF 3</subfield>
              </datafield>

          </record>
     </collection>
END

      get_tempfile_path(src)
    end


    before(:all) do
      parsed = convert(test_doc_1)
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
      @subjects[0]['terms'][0]['term'].should eq("SF 3")
      @subjects[0]['terms'][1]['term'].should eq("SF A")
      @subjects[0]['terms'][2]['term'].should eq("SF D")
      @subjects[0]['terms'][3]['term'].should eq("SF X")
      @subjects[0]['terms'][4]['term'].should eq("SF XII")
    end

    it "maps field 040 subfield e to resource.finding_aid_description_rules" do
      @resource['finding_aid_description_rules'].should eq("dacs")
    end


    describe "MARC import mappings" do


      def convert_test_file
        test_file = File.expand_path("../app/exporters/examples/marc/at-tracer-marc-1.xml", File.dirname(__FILE__))
        parsed = convert(test_file)

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
            self.select {|p|
              if name.match(/(.+),\s*(.+)/)
                (p['names'][0]['primary_name'] == $1) && (p['names'][0]['rest_of_name'] == $2)
              else
                p['names'][0]['primary_name'] == name
              end
            }
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
        @notes = @resource['notes'].map { |note| note_content(note) }
      end

      before(:all) do
        convert_test_file
      end

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

      it "maps datafield[@tag='600' or @tag='700']/subfield[@code='d'] to agent_(family|person).names[].dates" do
        @people.select{|p| p['names'][0]['dates'] == 'PNames-Dates-AT'}.count.should eq(3)
      end

      it "prepends and maps datafield[@tag='600']/subfield[@code='g'] to agent_(family|person).names[].qualifier" do
        @people.select{|p| p['names'][0]['qualifier'].match(/Miscellaneous information: PNames-Qualifier-AT\./)}.count.should eq(3)
      end

      it "maps datafield[@tag='110' or @tag='610' or @tag='710'] to agent_corporate_entity" do
        @corps.count.should eq(4)
      end

      it "maps datafield[@tag='110' or @tag='610' or @tag='710'] to agent_corporate_entity with source 'ingest'" do
        @corps.select {|f| f['names'][0]['source'] == 'ingest'}.count.should eq(3)
      end

      it "maps datafield[@tag='610']/subfield[@code='2'] to agent_corporate_entity.names[].source" do
        @corps.select {|f| f['names'][0]['source'] == 'NACO Authority File'}.count.should eq(1)
      end

      it "maps datafield[@tag='610'] to agent_corporate_entity linked as 'subject'" do
        links = @resource['linked_agents'].select {|a| @corps.map{|c| c['uri']}.include?(a['ref'])}
        links.select {|l| l['role'] == 'subject'}.count.should eq(1)
      end

      it "maps datafield[@tag='110'][subfield[@code='e']='Creator (cre)'] and datafield[@tag='710'][subfield[@code='e']='source'] or no $e/$4 to agent_corporate_entity linked as 'creator'" do
        links = @resource['linked_agents'].select {|a| @corps.map{|c| c['uri']}.include?(a['ref'])}
        links.select {|l| l['role'] == 'creator'}.count.should eq(3)
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

      it "maps datafield[@tag='110' or @tag='710'] with no $e or $4 to creator agent_corporate_entity" do
        creator = @corps.select{|c| c['names'][0]['primary_name'] == 'DNames-PrimaryName-AT'}
        creator.length.should eq(1)
        link = @resource['linked_agents'].select{|a| a['ref'] == creator[0]['uri']}
        link.length.should eq(1)
        link[0]['role'].should eq('creator')
      end

      it "maps datafield[@tag='245'] to resource.title using template '$a : $b [$h] $k , $n , $p , $s / $c' " do
        @resource['title'].should eq("Resource--Title-AT")
      end

      it "maps datafield[@tag='245']/subfield[@code='f' or @code='g'] to resources.dates[]" do
        @resource['dates'][0]['expression'].should eq("Resource-Date-Expression-AT-1960 - 1970")
      end

      it "maps datafield[@tag='300'] to resource.extents[].container_summary using template '$3: $a ; $b, $c ($e, $f, $g)'" do
        @resource['extents'][0]['container_summary'].should eq("5.0 Linear feet (Resource-ContainerSummary-AT)")
        @resource['extents'][0]['number'].should eq("5.0")
        @resource['extents'][0]['extent_type'].should eq("Linear feet")
      end

      it "maps datafield[@tag='260'] to resource.notes[] using template '$a'" do
        @notes.should include('1889-1945')
      end

      it "maps datafield[@tag='351'] to resource.notes[] using template '$3: $a. $b. $c'" do
        @notes.should include('Resource-Arrangement-Note Resource-FilePlan-AT.')
      end

      it "maps datafield[@tag='500'] to resource.notes[] using template '$3: $a'" do
        @notes.should include('Material Specific Details:Resource-MaterialSpecificDetails-AT')
      end

      it "maps datafield[@tag='505'] to resource.notes[] using template '$a'" do
        @notes.should include('CumulativeIndexFindingAidsNote-AT')
      end

      it "maps datafield[@tag='506'] to resource.notes[] using template '$a'" do
        @notes.should include('Resource-ConditionsGoverningAccess-AT.')
      end

      it "maps datafield[@tag='520'] to resource.notes[] using template '$3:  $a. ($u) [line break] $b.'" do
        @notes.should include('Resource-Abstract-AT.')
      end

      it "maps datafield[@tag='524'] to resource.notes[] using template '$3: $a. $2.'" do
        @notes.should include('Resource-PreferredCitation-AT.')
      end

      it "maps datafield[@tag='535'] to resource.notes[] using template 'Indicator 1 [Holder of originals | Holder of duplicates]: $3--$a. $b, $c. $d ($g).'" do
        @notes.should include('Indicator 1 Holder of originals: Resource-ExistenceLocationOriginals-AT.')
      end

      it "maps datafield[@tag='540'] to resource.notes[] using template '$3: $a. $b. $c. $d ($u).'" do
        @notes.should include('Resource-ConditionsGoverningUse-AT.')
      end

      it "maps datafield[@tag='541'] to resource.notes[] using template '#3: Source of acquisition--$a. Address--$b. Method of acquisition--$c; Date of acquisition--$d. Accession number--$e: Extent--$n; Type of unit--$o. Owner--$f. Purchase price--$h.'" do
        @notes.should include('Source of acquisition--Resource-ImmediateSourceAcquisition.')
      end

      it "maps datafield[@tag='544'] to resource.notes[] using template 'Indicator 1 [ Associated Materials | Related Materials]--$3: Title--$t. Custodian--$a: Address--$b, Country--$c. Provenance--$e. Note--$n.'" do
        @notes.should include('Custodian--Resource-RelatedArchivalMaterials-AT.')
      end

      it "maps datafield[@tag='545'] to resource.notes[] using template '$a ($u). [Line break] $b.'" do
        @notes.should include('Resource-BiographicalHistorical-AT.')
      end

      it "maps datafield[@tag='546'] to resource.notes[] using template '$3: $a ($b).'" do
        @notes.should include('Resource-LanguageMaterials-AT.')
      end

      it "maps datafield[@tag='561'] to resource.notes[] using template '$3: $a.'" do
        @notes.should include('Resource--CustodialHistory-AT.')
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

  describe "Importing Name Authority Files" do
    it "can import a name authority record" do
      john_davis = File.expand_path("../app/exporters/examples/marc/authority_john_davis.xml",
                                    File.dirname(__FILE__))

      converter = MarcXMLConverter.for_subjects_and_agents_only(john_davis)
      converter.run
      json = JSON(IO.read(converter.get_output_path))
      # we should only get one agent record
      json.count.should eq(1)

      agent = json.first
      agent['publish'].should be_truthy

      agent['dates_of_existence'].count.should eq(1)
      agent['dates_of_existence'][0]['expression'].should eq('18990101-19611201')
      agent['dates_of_existence'][0]['begin'].should eq('1899')
      agent['dates_of_existence'][0]['end'].should eq('1961')

      agent['notes'].count.should eq(1)
      agent['notes'][0]['subnotes'][0]['content'].should eq(
        'Biographical or historical data. Expansion ... Uniform Resource Identifier'
      )

      agent['names'][0]['name_order'].should eq("inverted")
      agent['names'][0]['authority_id'].should eq('n88218900')
      agent['names'][0]['authorized'].should be_truthy
      agent['names'][0]['is_display_name'].should be_truthy
      agent['names'][0]['source'].should eq('naf')
      agent['names'][0]['rules'].should eq('aacr')
      agent['names'][0]['primary_name'].should eq("Davis")
      agent['names'][0]['rest_of_name'].should eq("John W.")
      agent['names'][0]['fuller_form'].should eq("John William")
      agent['names'][0]['dates'].should eq("1873-1955")

      # Unauthorized names are added too
      agent['names'][1]['name_order'].should eq("inverted")
      agent['names'][1]['authority_id'].should be_nil
      agent['names'][1]['authorized'].should be_falsey
      agent['names'][1]['source'].should eq('naf')
      agent['names'][1]['rules'].should eq('aacr')
      agent['names'][1]['is_display_name'].should be_falsey
      agent['names'][1]['primary_name'].should eq("Davis")
      agent['names'][1]['rest_of_name'].should eq("John William")
    end
  end

  describe "Importing Subject Authority Files" do
    it "can import a subject authority record" do
      cyberpunk_file = File.expand_path("../app/exporters/examples/marc/authority_cyberpunk.xml",
                                    File.dirname(__FILE__))

      converter = MarcXMLConverter.for_subjects_and_agents_only(cyberpunk_file)
      converter.run
      json = JSON(IO.read(converter.get_output_path))
      # we should only get one subject record
      json.count.should eq(1)

      subject = json.first
      subject['publish'].should be_truthy
      subject['authority_id'].should eq('no2006087900')
      subject['source'].should eq("Library of Congress Subject Headings")
      subject['scope_note'].should eq('Works on cyberpunk in the genre Science Fiction. May be combined with geographic name in the form Cyberpunk fiction-Japan.')
      subject['terms'].count.should eq(1)
      subject['terms'][0]['term'].should eq('Cyberpunk')
    end

    it "can import a subject authority record with lcgft source" do
      lcgft_file = File.expand_path("../app/exporters/examples/marc/gf2014026450.xml",
                                    File.dirname(__FILE__))

      converter = MarcXMLConverter.for_subjects_and_agents_only(lcgft_file)
      converter.run
      json = JSON(IO.read(converter.get_output_path))
      # we should only get one subject record
      json.count.should eq(1)

      subject = json.first
      subject['source'].should eq("lcgft")
    end
  end

  describe "008 string handling" do
    let (:test_doc) {
      src = <<marc
<?xml version="1.0" encoding="UTF-8" ?>
<marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
<marc:record><marc:leader>00943nasaa2200253Ia 4500</marc:leader>
<marc:controlfield tag="001">32415731</marc:controlfield>
<marc:controlfield tag="008">950503s1934    fr                  fre d</marc:controlfield>

<marc:datafield tag="245" ind1="1" ind2="0">
<marc:subfield code="a">Letters :</marc:subfield>
<marc:subfield code="b">Paris, to Kelver Hartley, Paris,</marc:subfield>
<marc:subfield code="f">1934 Nov. 1-Dec. 25 </marc:subfield>
</marc:datafield>

<marc:datafield tag="300" ind1=" " ind2=" ">
<marc:subfield code="a">2 items (2 leaves) ;</marc:subfield>
<marc:subfield code="c">20 cm. and smaller </marc:subfield>
</marc:datafield>
</marc:record>
</marc:collection>

marc
      get_tempfile_path(src)
    }

    it "doesn't try to set an end date if the controlfield has blank values" do
      parsed = convert(test_doc)
      @resource = parsed.last
      @resource['dates'][0]['end'].should be_nil
    end
  end


  describe "Name Order handling" do
    def name_order_test_doc
      src = <<ROTFL
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<collection xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd" xmlns="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <record>
    <leader>00000npc a2200000 u 4500</leader>
    <controlfield tag="008">130109i19601970xx                  eng d</controlfield>

    <datafield tag="100" ind1="1">
      <subfield code="a">a1, foo</subfield>
      <subfield code="b">b1</subfield>
      <subfield code="c">c1</subfield>
      <subfield code="d">d1</subfield>
      <subfield code="e">e1</subfield>
      <subfield code="f">f1</subfield>
    </datafield>
    <datafield tag="100" ind1="0">
      <subfield code="a">a2</subfield>
      <subfield code="b">b2</subfield>
      <subfield code="c">c2</subfield>
      <subfield code="d">d2</subfield>
      <subfield code="e">e2</subfield>
      <subfield code="f">f2</subfield>
    </datafield>
    <datafield tag="600" ind1="1">
      <subfield code="a">a3</subfield>
      <subfield code="b">b3</subfield>
      <subfield code="c">c3</subfield>
      <subfield code="d">d3</subfield>
      <subfield code="e">e3</subfield>
      <subfield code="f">f3</subfield>
    </datafield>
    <datafield tag="600" ind1="0">
      <subfield code="a">a4</subfield>
      <subfield code="b">b4</subfield>
      <subfield code="c">c4</subfield>
      <subfield code="d">d4</subfield>
      <subfield code="e">e4</subfield>
      <subfield code="f">f4</subfield>
    </datafield>
    <datafield tag="700" ind1="1">
      <subfield code="a">a5</subfield>
      <subfield code="b">b5</subfield>
      <subfield code="c">c5</subfield>
      <subfield code="d">d5</subfield>
      <subfield code="e">e5</subfield>
      <subfield code="f">f5</subfield>
    </datafield>
    <datafield tag="700" ind1="0">
      <subfield code="a">a6</subfield>
      <subfield code="b">b6</subfield>
      <subfield code="c">c6</subfield>
      <subfield code="d">d6</subfield>
      <subfield code="e">e6</subfield>
      <subfield code="f">f6</subfield>
    </datafield>
  </record>
</collection>
ROTFL

      get_tempfile_path(src)
    end

    before(:all) do
      converter = MarcXMLConverter.for_subjects_and_agents_only(name_order_test_doc)
      converter.run
      json = JSON(IO.read(converter.get_output_path))
      @people = json.select{|r| r['jsonmodel_type'] == 'agent_person'}

      names = @people.map {|person| person['names'][0] }
      @names = names.sort_by{|name| name['primary_name'] }
    end

    it "imports name_person subrecords with the correct name_order" do
      @names.map{|name| name['name_order']}.should eq(%w(inverted direct inverted direct inverted direct))
    end

    it "splits primary_name and rest_of_name" do
      @names[0]['primary_name'].should eq('a1')
      @names[0]['rest_of_name'].should eq('foo')
    end
  end


  describe "Date de-duplication" do
    let(:date_dupes_test_doc) {
      src = <<OMFG
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim"
                 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                 xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
  <marc:record>
    <marc:leader>00874cbd a2200253 a 4500</marc:leader>
    <marc:controlfield tag="001">1161022 </marc:controlfield>
    <marc:controlfield tag="005">20020626205047.0</marc:controlfield>
    <marc:controlfield tag="008">920324s19801980kyu eng d</marc:controlfield>
    <marc:datafield tag="040" ind1=" " ind2=" ">
      <marc:subfield code="a">RC</marc:subfield>
      <marc:subfield code="e">appm</marc:subfield>
    </marc:datafield>
    <marc:datafield tag="110" ind1="2" ind2=" ">
      <marc:subfield code="a">University of Louisville.</marc:subfield>
      <marc:subfield code="b">University Personnel Services.</marc:subfield>
    </marc:datafield>
    <marc:datafield tag="245" ind1="0" ind2="0">
      <marc:subfield code="a">Applicant files,</marc:subfield>
      <marc:subfield code="f">1980.</marc:subfield>
    </marc:datafield>
    <marc:datafield tag="300" ind1=" " ind2=" ">
      <marc:subfield code="a">5.00</marc:subfield>
      <marc:subfield code="f">linear feet.</marc:subfield>
    </marc:datafield>
  </marc:record>
</marc:collection>
OMFG

      get_tempfile_path(src)
    }

    before(:each) do
      json = convert(date_dupes_test_doc)
      @resource = json.last
    end

    it "will combine the data in 245f and controlfield 008 into a single date" do
      @resource['dates'].count.should eq(1)
      date = @resource['dates'][0]
      date['expression'].should eq('1980.')
      date['date_type'].should eq('single')
      date['begin'].should eq('1980')
      date['end'].should eq('1980')
    end
  end


  describe "Namespace handling" do

    let (:collection_doc) {
      src = <<MARC
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <foo:collection xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd" xmlns:foo="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <foo:record>
    <foo:controlfield tag="008">920324s19801980kyu eng d</foo:controlfield>
      <foo:datafield tag="245" ind2=" " ind1="1">
        <foo:subfield code="a">SF A</foo:subfield>
      </foo:datafield>
      <foo:datafield tag="300" ind2=" " ind1=" ">
        <foo:subfield code="a">5.0 Linear feet</foo:subfield>
        <foo:subfield code="f">Resource-ContainerSummary-AT</foo:subfield>
      </foo:datafield>
    </foo:record>
  </foo:collection>
MARC

      get_tempfile_path(src)
    }

    let (:record_doc) {
      src = <<MARC
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <foo:record xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd" xmlns:foo="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <leader>00000npm a2200000 u 4500</leader>
    <foo:controlfield tag="008">920324s19801980kyu eng d</foo:controlfield>
    <foo:datafield tag="245" ind2=" " ind1="1">
      <foo:subfield code="a">SF A</foo:subfield>
    </foo:datafield>
    <foo:datafield tag="300" ind2=" " ind1=" ">
      <foo:subfield code="a">5.0 Linear feet</foo:subfield>
      <foo:subfield code="f">Resource-ContainerSummary-AT</foo:subfield>
    </foo:datafield>
  </foo:record>
MARC
      get_tempfile_path(src)
    }

    it "ignores namespaces declared at the record node" do
      parsed = convert(record_doc)
      @resource = parsed.last
      @resource.should_not be_nil
      @resource['level'].should == 'item'
      @resource['title'].should_not be_nil
    end

    it "ignores namespaces declared at the collection node" do
      parsed = convert(collection_doc)
      @resource = parsed.last
      @resource.should_not be_nil
      @resource['title'].should_not be_nil
    end
  end

  describe "Subclassing and reconfiguring" do

    def test_doc
      src = <<MARC
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <record xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd" xmlns="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <datafield tag="245" ind2=" " ind1="1">
      <subfield code="a">SF A</subfield>
    </datafield>
  </record>
MARC
      get_tempfile_path(src)
    end

    let (:subclass) {
      class CramXMLConverter < MarcXMLConverter
        def self.import_types(*args)
          {:name => 'cramxml', :description => "cram records in"}
        end


        def self.instance_for(type, input_file)
          if type == 'cramxml'
            self.new(input_file)
          end
        end
      end

      CramXMLConverter.configure do |config|
        config['/record'][:map]['self::record'] = Proc.new {|resource, node|
          if !resource.title
            resource.title = "TITLE"
          end

          if resource.dates.nil? || resource.dates.empty?
            resource.dates << ASpaceImport::JSONModel(:date).from_hash({:expression => "1945", :label => "creation", "date_type" => "single"})
          end
          
          if resource.extents.nil? || resource.extents.empty?
            resource.extents << ASpaceImport::JSONModel(:extent).from_hash({:portion => 'whole', :number => '1', :extent_type => 'linear_feet'})
          end

          if resource.id_0.nil? or resource.id.empty?
            resource.id_0 = "ID"
          end
        }
      end

      CramXMLConverter
    }

    it "lets itself be subclassed and reconfigured" do

      # regular converter should produce an invalid record
      converter = MarcXMLConverter.new(test_doc)
      expect { converter.run }.to raise_error(JSONModel::ValidationException)

      # our cram converter should produce a valid record
      subconverter = subclass.new(test_doc)
      expect { subconverter.run }.to_not raise_error

      # regular converter should still produce an invalid record
      converter = MarcXMLConverter.new(test_doc)
      expect { converter.run }.to raise_error(JSONModel::ValidationException)
    end
  end

  # It might happen that a converter mapping targets a property that doesn't
  # exist, especially if a mapping is reused for different record types.
  describe "Handling bad mappings" do

    def test_doc
      src = <<MARC
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <record xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd" xmlns="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <datafield tag="245" ind2=" " ind1="1">
      <subfield code="a">SF A</subfield>
    </datafield>
    <datafield tag="9999" ind2=" " ind1="1">
      <subfield code="a">SF A</subfield>
    </datafield>
  </record>
MARC
      get_tempfile_path(src)
    end

    let (:subconverter) {
      class BadMarcXMLAccessionConverter < MarcXMLConverter
        def self.import_types(*args)
          {:name => 'marc2accession', :description => "make accessions from marc"}
        end


        def self.instance_for(type, input_file)
          if type == 'marc2accession'
            self.new(input_file)
          end
        end
      end

      BadMarcXMLAccessionConverter.configure do |config|
        config['/record'] = {
          :obj => :accession,
          :map => {
            'self::record' => Proc.new {|accession, node|
              if !accession.title
                accession.title = "TITLE"
              end

              if accession.extents.nil? || accession.extents.empty?
                accession.extents << ASpaceImport::JSONModel(:extent).from_hash({:portion => 'whole', :number => '1', :extent_type => 'linear_feet'})
              end

              if accession.id_0.nil? or accession.id.empty?
                accession.id_0 = "ID"
              end
            },
            'datafield[@tag="9999"]' => {
              :obj => :note_singlepart,
              :rel => :notes, # Accessions don't take notes!
              :map => {
                "self::datafield" => -> note, node {
                  note.send('label=', "my note")
                  note.type = 'odd'
                  note.content = 'my note content'
                }
              }
            }
          }
        }

      end

      BadMarcXMLAccessionConverter
    }

    it "raises a ConverterMappingError" do

      # regular converter should produce an invalid record
      converter = subconverter.new(test_doc)
      expect {
        converter.run
        json = JSON(IO.read(converter.get_output_path))
        puts json.inspect

      }.to raise_error(Converter::ConverterMappingError, "The converter maps 'datafield[@tag=\"9999\"]' to a bad target (property 'notes' on record_type 'accession')." )

    end
  end
end
