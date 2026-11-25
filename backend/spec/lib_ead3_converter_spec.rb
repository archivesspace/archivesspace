require 'spec_helper'
require 'converter_spec_helper'
require_relative '../app/converters/ead3_converter'

describe 'EAD3Converter' do

  before(:each) do
    # We aren't interested in testing JSONModel validations here.
    # This allows us to push partially complete records through
    # the import cycle (in-memory queue > working file > final file)
    allow(JSONSchemaUtils).to receive(:parse_schema_messages).and_return(
                                msgs = {
                                  errors: {},
                                  warnings: {},
                                  attribute_types: {}
                                })
  end


  def convert_and_return_records(xml)
    converter = TestConverter.instance_for(EAD3Converter, xml)
    converter.record_batch << ASpaceImport::JSONModel(:resource).new
    converter.run
    converter.records
  end

  def convert_and_return_resource(xml)
    records = convert_and_return_records(xml)
    records.resource
  end

  def convert_and_return_archival_object(xml)
    records = convert_and_return_records(xml)
    records.archival_object
  end

  describe "<physdesc> tag handler" do
    it "converts '<physdesc label=\"WHATEVER\">' to an `extent` subrecord" do
      xml = <<~PHYSDESC
        <physdesc label="WHATEVER" encodinganalog="300">
          approximately 5,302 items
        </physdesc>
      PHYSDESC
      resource = convert_and_return_resource(xml)
      extent = resource.extents[0]
      expect(extent.number).to eq "5,302"
      expect(extent.extent_type).to eq("items")
      expect(extent.container_summary).to eq("approximately")
    end

    it "can infer an extent record from the beginning of a physdesc tag" do
      xml = <<~PHYSDESC
        <physdesc label="Extent (Graphic Images)">
        20 photographic prints: black and white, color; various sizes </physdesc>
      PHYSDESC
      resource = convert_and_return_resource(xml)
      extent = resource.extents[0]
      expect(extent.number).to eq "20"
      expect(extent.extent_type).to eq("photographic prints")
      expect(extent.physical_details).to eq("black and white, color")
    end

    it "can handle cases where there is no number in the text" do
      xml = <<~PHYSDESC
        <physdesc encodinganalog="300">Piano-vocal scores; lead sheet; lyric sheets</physdesc>
      PHYSDESC
      resource = convert_and_return_resource(xml)
      extent = resource.extents[0]
      expect(extent.number).to eq "0"
      expect(extent.extent_type).to eq("unknown")
      expect(extent.physical_details).to be_nil
    end

    it "won't make extent records for archival objects" do
      xml = <<~XML
        <root>
           <physdesc encodinganalog="300">10 things</physdesc>
           <c02 id="mferd13e492" level="item">
              <did>
                 <unittitle>Collection Finding Aid</unittitle>
                 <physdesc encodinganalog="300">1 thing</physdesc>
              </did>
           </c02>
        </root>
      XML
      records = convert_and_return_records(xml)
      expect(records.resource.extents.size).to eq 1
      expect(records.archival_object.extents.size).to eq 0
    end

    it "creates multiple extent records for strings with AND and PLUS" do
      xml = <<~PHYSDESC
        <physdesc encodinganalog="300">12 boxes plus 34 microfilm reels and 3 oversize</physdesc>
      PHYSDESC
      resource = convert_and_return_resource(xml)
      expect(resource.extents.size).to eq 3
      expect(resource.extents[0].number).to eq "12"
      expect(resource.extents[0].extent_type).to eq("boxes")
      expect(resource.extents[1].number).to eq "34"
      expect(resource.extents[1].extent_type).to eq("microfilm reels")
      expect(resource.extents[2].number).to eq "3"
      expect(resource.extents[2].extent_type).to eq("oversize")
    end

    it "can parse extent types with parenthesis" do
      xml = <<~PHYSDESC
        <physdesc label="Extent">701 items (chiefly photographic prints); 57 x 41 cm. or smaller.</physdesc>
      PHYSDESC
      resource = convert_and_return_resource(xml)
      extent = resource.extents[0]
      expect(extent.number).to eq "701"
      expect(extent.extent_type).to eq("items")
      expect(extent.physical_details).to eq("chiefly photographic prints")
      expect(extent.dimensions).to eq("57 x 41 cm. or smaller.")
    end

    it "combines the label and the tag content to populate the physical_description field" do
      xml = <<~PHYSDESC
        <___>
          <physdesc label="Extent (military papers)" encodinganalog="300">3 items</physdesc>
        </___>
      PHYSDESC
      resource = convert_and_return_resource(xml)
      extent = resource.extents[0]
      expect(extent.number).to eq "3"
      expect(extent.extent_type).to eq("items")
    end
  end

  describe "<unitdate> tag handler" do
    context "when begin date is after end date" do
      it "corrects the order of begin and end dates for any valid historical range" do
        xml = <<~UNITDATE
          <unitdate label="Incorrect Order" unitdatetype="inclusive" normal="2025/1500"
                    encodinganalog="245$f"
                    datechar="creation">2025-1500</unitdate>
        UNITDATE
        resource = convert_and_return_resource(xml)
        date = resource.dates[0]
        expect(date.begin).to eq("1500")
        expect(date.end).to eq("2025")
      end
    end

    context "when <unitdate> is well-formed" do
      it "correctly converts <unitdate> to a date subrecord" do
        xml = <<~UNITDATE
          <unitdate label="Well-formed Date" unitdatetype="inclusive" normal="1900/1950"
                    encodinganalog="245$f"
                    datechar="creation">1900-1950</unitdate>
        UNITDATE
        resource = convert_and_return_resource(xml)
        date = resource.dates[0]
        expect(date.begin).to eq("1900")
        expect(date.end).to eq("1950")
        expect(date.label).to eq("creation")
        expect(date.date_type).to eq("inclusive")
        expect(date.expression).to eq("1900-1950")
      end

      it "correctly converts dates in YYYY-MM-DD format" do
        xml = <<~UNITDATE
          <unitdate label="Well-formed Date" unitdatetype="inclusive" normal="1900-02-12/1950-02-13"
                    encodinganalog="245$f"
                    datechar="creation">1900-1950</unitdate>
        UNITDATE
        resource = convert_and_return_resource(xml)
        date = resource.dates[0]
        expect(date.begin).to eq("1900-02-12")
        expect(date.end).to eq("1950-02-13")
        expect(date.label).to eq("creation")
        expect(date.date_type).to eq("inclusive")
        expect(date.expression).to eq("1900-1950")
      end
    end

    context "when <unitdate> is not well-formed" do
      it "correctly converts dates in YYYY-MM-DD format" do
        xml = <<~UNITDATE
          <unitdate label="Well-formed Date" unitdatetype="inclusive" normal="1900-02-12/19500213"
                    encodinganalog="245$f"
                    datechar="creation">1900-1950</unitdate>
        UNITDATE
        resource = convert_and_return_resource(xml)
        date = resource.dates[0]
        expect(date.begin).to eq("1900-02-12")
        expect(date.end).to eq("1950-02-13")
        expect(date.label).to eq("creation")
        expect(date.date_type).to eq("inclusive")
        expect(date.expression).to eq("1900-1950")
      end
    end

    context "unittitle contains only a nested unitdate" do
      it "should not assign a title to the archival object" do
        xml = <<~EAD
          <c05 id="mferd82e1127" level="file">
             <did>
                <unittitle encodinganalog="245$a">
                   <date>1862-1866 </date>
                </unittitle>
                <unitdate encodinganalog="245$f" unitdatetype="inclusive">1862-1866
                </unitdate>
             </did>
          </c05>
                EAD
        records = convert_and_return_records(xml)
        archival_object = records.archival_object
        expect(archival_object.title).to be_nil
        expect(archival_object.dates[0].expression).to eq "1862-1866"
      end
    end

    context "when <unitdate> lacks an end date" do
      it "creates a date subrecord with only a begin date" do
        xml = <<~UNITDATE
          <unitdate label="Single Year" unitdatetype="single" normal="1850"
                    encodinganalog="245$f"
                    datechar="creation">1850</unitdate>
        UNITDATE
        resource = convert_and_return_resource(xml)
        date = resource.dates[0]
        expect(date.begin).to eq("1850")
        expect(date.end).to be_nil
        expect(date.label).to eq("creation")
        expect(date.date_type).to eq("inclusive")
        expect(date.expression).to eq("1850")
      end
    end

    context "when <unitdate> lacks the @normal attribute" do
      it "can still parse inclusive dates" do
        xml = <<~UNITDATE
          <unitdate encodinganalog="245$f" era="ce" calendar="gregorian">1903-1909</unitdate>
        UNITDATE
        resource = convert_and_return_resource(xml)
        date = resource.dates[0]
        expect(date.begin).to eq("1903")
        expect(date.end).to eq("1909")
        expect(date.label).to eq("creation")
        expect(date.date_type).to eq("inclusive")
        expect(date.expression).to eq("1903-1909")
      end
    end
  end

  describe "date handling" do
    it "can correct an invalid date" do
      xml = <<~EAD
        <c04 id="mferd38e17151" level="file">
           <did>
              <container localtype="box">358</container>
              <unittitle id="utid40834" encodinganalog="245$a">
                 <date localtype="inclusive" normal="2005-11-31">2005, Nov.
                  31</date>, 4 atom</unittitle>
              <unitdate unitdatetype="inclusive" encodinganalog="245$f" normal="2005-11-31">2005, Nov. 31</unitdate>
           </did>
        </c04>
              EAD
      records = convert_and_return_records(xml)
      archival_object = records.archival_object
      expect(archival_object.dates[0].begin).to eq "2005-11-30"
    end
  end

  describe "setting resource.id_0 " do
    context "when there is no <unitid> but there is a <controlnote>" do
      it "sets resource.id_0 from the <controlnote>" do
        xml = <<~EAD
           <___>
             <control>
                <filedesc>
                   <notestmt>
                    <controlnote id="lccnNote">
                  <p>Catalog Record: <ref show="new" actuate="onrequest" href="https://lccn.loc.gov/2020603131">https://lccn.loc.gov/2020603131</ref>
                  </p>
                    </controlnote>
                </notestmt>
              </filedesc>
            </control>
          </___>
        EAD
        resource = convert_and_return_resource(xml)
        expect(resource.id_0).to eq("2020603131")
      end
    end

    context "when there is a <unitid> and also a <controlnote>" do
      it "sets resource.id_0 from the <unitid>" do
        xml = <<~EAD
           <___>
             <control>
                <filedesc>
                   <notestmt>
                    <controlnote id="lccnNote">
                  <p>Catalog Record: <ref show="new" actuate="onrequest" href="https://lccn.loc.gov/2020603131">https://lccn.loc.gov/2020603131</ref>
                  </p>
                    </controlnote>
                </notestmt>
              </filedesc>
            </control>
            <archdesc>
              <did>
                <unitid>HELLO</unitid>
              </did>
            </archdesc>
          </___>
        EAD
        resource = convert_and_return_resource(xml)
        expect(resource.id_0).to eq("HELLO")
      end
    end
  end

  describe "<unitid> handling" do

    def convert(xml_string)
      full_xml = <<~XML
        <c><did>
          <unittitle>X</unittitle><unitdate>2000</unitdate>#{xml_string}
        </did></c>
                   XML
      records = convert_and_return_records(full_xml)
      records.archival_object
    end

    context "<unitid> within a <c> tag" do
      it "populates the component_id with the unitid prefixed by the unitid/@label attribute" do
        xml = <<~EAD
          <unitid label="ID" encodinganalog="590" countrycode="US" repositorycode="US-DLC">MSS84430</unitid>
               EAD
        archival_object = convert(xml)
        expect(archival_object.component_id).to eq("ID: MSS84430")
      end
    end

    context "<unitid> within a <archdesc> tag" do
      it "does not prefix the id_0 values with the unitid/@label attribute" do
        xml = <<~EAD
          <unitid label="ID No." encodinganalog="590" countrycode="US" repositorycode="US-DLC">MSS84430</unitid>
               EAD
        resource = convert_and_return_resource(xml)
        expect(resource.id_0).to eq("MSS84430")
      end
    end

    context "unitid has an id attribute with a ref_id value" do
      it "maps the id attribute to a ref_id" do
        xml = <<~XML
          <unitid id="JFK" label="Digital ID">
            <ref show="replace" actuate="onrequest" target="JFK2">mss85761_131_026</ref>
          </unitid>
                 XML
        archival_object = convert(xml)
        expect(archival_object.ref_id).to eq "JFK"


        xml = <<~XML
          <unitid id="c73-1808">73-1808</unitid>
               XML
        archival_object = convert(xml)
        expect(archival_object.ref_id).to eq "c73-1808"
      end
    end
  end

  describe "<list type='unordered'> handling" do
    it "converts list tags within a multipart note to unordered list subnotes" do
      xml = <<~EAD
          <arrangement encodinganalog="351$a" id="mferd6e376v">
             <head>Arrangement</head>
             <p> The Neil V. Rosenberg bluegrass music collection is organized in three series: </p>
             <list listtype="unordered" mark="circle">
                <item>
                   <ref show="replace" actuate="onrequest" target="ref_id10001">Series 1.
                Tennessee-Tombigbee Folklife Survey and related materials</ref>
                </item>
                <item>
                   <ref show="replace" actuate="onrequest" target="ref_id10022">Series 2.
                Correspondence and contacts</ref>
                </item>
                <item>
                   <ref show="replace" actuate="onrequest" target="ref_id10027">Series 3. Sound
                recordings</ref>
                </item>
             </list>
             <p>Filepaths and digital files can be found in afc2002009_dc001. Please see the AFC
        reference staff for access.</p>
          </arrangement>
        EAD
      resource = convert_and_return_resource(xml)
      expect(resource.notes.size).to eq 1
      expect(resource.notes[0].subnotes.size).to eq 3
      expect(resource.notes[0].subnotes[0]['content']).to eq "The Neil V. Rosenberg bluegrass music collection is organized in three series:"
      expect(resource.notes[0].subnotes[1]['items']).to eq [
                                                            "<ref actuate=\"onrequest\" show=\"replace\" target=\"ref_id10001\">Series 1. Tennessee-Tombigbee Folklife Survey and related materials</ref>",
                                                            "<ref actuate=\"onrequest\" show=\"replace\" target=\"ref_id10022\">Series 2. Correspondence and contacts</ref>",
                                                            "<ref actuate=\"onrequest\" show=\"replace\" target=\"ref_id10027\">Series 3. Sound recordings</ref>"
                                                          ]
      expect(resource.notes[0].subnotes[2]['content']).to eq "Filepaths and digital files can be found in afc2002009_dc001. Please see the AFC reference staff for access."
    end
  end

  describe "<dao> tag handling" do
    it "maps the @href attribute to the file_uri field of the digital object file version" do
      xml = <<~EAD
        <dao daotype="derived" actuate="onload" show="embed"
            href="https://hdl.loc.gov/loc.mss/ms014016.mss48595.0101">
          <descriptivenote>
            <p>Digital content available</p>
          </descriptivenote>
        </dao>
              EAD
      records = convert_and_return_records(xml)
      digital_object = records.digital_object
      expect(digital_object.file_versions.first[:file_uri]).to eq "https://hdl.loc.gov/loc.mss/ms014016.mss48595.0101"
    end

    it "uses the preceding sibling <unititle> as the digital_object title" do
      xml = <<~EAD
        <c03 id="mferd338e6409" level="file">
           <did>
              <container localtype="df"/>
              <unittitle>Bernstein, Burton to Leonard Bernstein, <date>1938 August 30</date>
              </unittitle>
              <unitdate encodinganalog="245$f">1938 August 30</unitdate>
              <dao daotype="derived" actuate="onload" show="embed"
                   href="https://www.loc.gov/item/musbernstein.100060000">
                 <descriptivenote>
                    <p>Digital content available</p>
                 </descriptivenote>
              </dao>
           </did>
        </c03>
              EAD
      records = convert_and_return_records(xml)
      digital_object = records.digital_object
      expect(digital_object.title).to eq "Bernstein, Burton to Leonard Bernstein"
    end

    it "creates digital object identifier from href" do
      xml = <<~EAD
        <dao daotype="derived" actuate="onload" show="new"  href="https://www.loc.gov/item/afc2001001.101797/">
          <descriptivenote>
            <p>Digital content available</p>
          </descriptivenote>
        </dao>
              EAD
      records = convert_and_return_records(xml)
      digital_object = records.digital_object
      expect(digital_object.digital_object_id).to eq "afc2001001.101797"
      expect(digital_object.publish).to be_truthy
    end

    it "can recognize multiple DAOs are a single digital object that appears in multiple instances" do
      xml = <<~EAD
        <snip>
        <c04 id="mferd6e44718" level="file">
           <did>
              <container localtype="box-folder">17/169</container>
              <unittitle id="ref_id11529" encodinganalog="245$a">C log (color
              photo log)</unittitle>
              <origination label="Author">
                 <name>
                    <part>American Folklife Center</part>
                 </name>
              </origination>
              <dao daotype="derived" actuate="onload" show="new"
                   href="https://hdl.loc.gov/loc.afc/afc1991023.afc1991023_17_169"
                   label="Digital content available">
                 <descriptivenote>
                    <p>afc1991023_17_169</p>
                 </descriptivenote>
              </dao>
              <physdesc encodinganalog="300" label="Extent">14 manuscript pages
              (8.5 x 14 inch or smaller)</physdesc>
           </did>
        </c04>
        <c04 id="mferd6e45072" level="file">
           <did>
              <container localtype="box-folder">17/169A</container>
              <unittitle id="ref_id11541" encodinganalog="245$a">B log
              (black-and-white photo log)</unittitle>
              <origination label="Author">
                 <name>
                    <part>American Folklife Center</part>
                 </name>
              </origination>
              <dao daotype="derived" actuate="onload" show="new"
                   href="https://hdl.loc.gov/loc.afc/afc1991023.afc1991023_17_169"
                   label="Digital content available">
                 <descriptivenote>
                    <p>afc1991023_17_169</p>
                 </descriptivenote>
              </dao>
              <physdesc encodinganalog="300" label="Extent">14 manuscript pages
              (8.5 x 14 inch or smaller)</physdesc>
              <didnote encodinganalog="500" label="Note">Black-and-white log
              starts on page 12</didnote>
           </did>
        </c04>
        </snip>
          EAD
      records = convert_and_return_records(xml)
      serialized_records = records #.final_serialization
      digital_objects = serialized_records.select { |record|
        record['jsonmodel_type'] == "digital_object"
      }
      expect(digital_objects.size).to eq 1
      expect(digital_objects[0]['title']).to eq "afc1991023_17_169"
      archival_objects = serialized_records.select { |record|
        record["jsonmodel_type"] == "archival_object"
      }
      expect(archival_objects[0]["instances"][1]["digital_object"]["ref"]).to eq digital_objects[0]["uri"]
      expect(archival_objects[1]["instances"][1]["digital_object"]["ref"]).to eq digital_objects[0]["uri"]
    end

    it "uses the descriptivenote for a title when the finalized unittitle is empty" do
      xml = <<~EAD
        <did>
           <container localtype="reel">2*</container>
           <container localtype="box">2</container>
           <unittitle encodinganalog="245$a" id="reel2">
              <date localtype="inclusive" normal="1939/1941">1939, 1941</date>
           </unittitle>
           <unitdate unitdatetype="inclusive" normal="1939/1941" encodinganalog="245$f">1939, 1941</unitdate>
           <dao daotype="derived" actuate="onload" show="embed"
                href="https://hdl.loc.gov/loc.pnp/fsahsr.002">
              <descriptivenote>
                 <p>*Digital content available (Reel 2)</p>
              </descriptivenote>
           </dao>
        </did>
              EAD
      records = convert_and_return_records(xml)
      expect(records.digital_object.title).to eq "*Digital content available (Reel 2)"
    end
  end


  describe "linked agent imports" do
    it "creates a linked agent with role 'source' for each origination tag and uses the label for the 'relator' field" do
      xml = <<~EAD
        <origination label="Creator">
          <persname encodinganalog="100" source="lcnaf">
            <part>Latty, A. Sankey (Alexander Sankey)</part>
          </persname>
        </origination>
      EAD
      resource = convert_and_return_resource(xml)
      expect(resource.linked_agents[0]["role"]).to eq "source"
      expect(resource.linked_agents[0]["relator"]).to eq "cre"
    end

    it "ensures origination tags are importing at the AO level" do
      xml = <<~EAD
        <c04 id="mferd6e42174" level="file">
           <did>
              <unitid label="Call number">AFC 1991/023: CET-015</unitid>
              <unittitle id="ref_id11447" encodinganalog="245$a">Interview</unittitle>
              <origination label="Photographer">
                 <name>
                    <part>Elaine Thatcher</part>
                 </name>
              </origination>
           </did>
        </c04>
      EAD
      records = convert_and_return_records(xml)
      archival_objects = records.archival_objects
      agent_persons = records.agent_persons
      expect(archival_objects[0].linked_agents.size).to eq 1
      expect(archival_objects[0].linked_agents[0]['ref']).to eq agent_persons[0].uri
    end
  end

  describe "<languagedeclaration> import" do
    it "maps language and script to the finding aid data section" do
      xml = <<~EAD
        <languagedeclaration>
           <language langcode="eng" encodinganalog="040$b">English</language>
           <script scriptcode="Latn">Latin</script>
        </languagedeclaration>
      EAD
      resource = convert_and_return_resource(xml)
      expect(resource.finding_aid_language).to eq "eng"
      expect(resource.finding_aid_script).to eq "Latn"
    end
  end

  describe "ref tag conversion to extref" do
    it "doesn't convert ref tags to extref when there is a target attribute" do
      xml = <<~EAD
        <notestmt>
           <controlnote id="contactNote">
              <p>Contact information: <ref actuate="onrequest" show="new" target="ref_id10001">Music</ref>
              </p>
           </controlnote>
        </notestmt>
      EAD

      resource = convert_and_return_resource(xml)
      expect(resource.finding_aid_note).to eq 'Contact information: <ref actuate="onrequest" show="new" target="ref_id10001">Music</ref>'
    end
  end

  describe "<origination> label mapping" do

    def convert(label)
      full_xml = <<~XML
        <origination label="#{label}">
          <persname>John Doe</persname>
        </origination>
                   XML
      return convert_and_return_resource(full_xml).linked_agents.first
    end

    context "when a label maps to a standard term with a MARC code" do
      it "maps a standard label like 'Creator:' to its MARC code" do
        linked_agent = convert("Creator:")
        expect(linked_agent['role']).to eq('source')
        expect(linked_agent['relator']).to eq('cre')
      end

      it "maps a messy, non-standard label like 'Related Names:' to a standard MARC code" do
        linked_agent = convert("Related Names:")
        expect(linked_agent['role']).to eq('source')
        expect(linked_agent['relator']).to eq('asn') # asn = Associated name
      end

      it "maps case-insensitively" do
        linked_agent = convert("PHOTOGRAPHER")
        expect(linked_agent['relator']).to eq('pht')
      end
    end

    context "when a label maps to a standard term without a MARC code" do
      it "uses the standardized term as the relator value" do
        linked_agent = convert("announcer")
        # There is no MARC code for 'Announcer', so it should use the term itself.
        expect(linked_agent['relator']).to eq('Announcer')
      end
    end

    context "when a label is not in the mapping hash" do
      it "uses the original label as a fallback" do
        linked_agent = convert("Principal Investigator")
        # this label isn't in our map, so it should be passed through directly.
        expect(linked_agent['relator']).to eq('Principal Investigator')
      end
    end

    context "when the origination tag has no label attribute" do
      it "results in a nil relator" do
        xml = <<~EAD
          <origination>
            <persname>An Agent</persname>
          </origination>
        EAD
        resource = convert_and_return_resource(xml)
        linked_agent = resource.linked_agents.first
      # Without a label, the custom handler shouldn't set a relator.
        expect(linked_agent['relator']).to be_nil
      end
    end
  end

  describe "Date Type Import Logic" do

    def run_date_conversion(xml_did_content)
      full_xml = "<archdesc>#{xml_did_content}</archdesc>"
      records = convert_and_return_records(xml_did_content)
      records
    end

    context "when <unitdate> is at the Resource level" do

      it "imports a <unitdate> with unitdatetype='bulk' as a Bulk date" do
        records = run_date_conversion("<did><unitdate unitdatetype='bulk' normal='1950/1960'>circa 1950-1960</unitdate></did>")

        expect(records.resource['dates'].length).to eq(1)
        expect(records.resource['dates'][0]['date_type']).to eq('bulk')
      end

      it "imports a <unitdate> with unitdatetype='inclusive' as an Inclusive date" do
        records = run_date_conversion("<did><unitdate unitdatetype='inclusive' normal='1970'>1970</unitdate></did>")

        expect(records.resource['dates'].length).to eq(1)
        expect(records.resource['dates'][0]['date_type']).to eq('inclusive')
      end

      it "defaults to an Inclusive date when the unitdatetype attribute is missing" do
        records = run_date_conversion("<did><unitdate normal='1980'>1980</unitdate></did>")
        expect(records.resource['dates'].length).to eq(1)
        expect(records.resource['dates'][0]['date_type']).to eq('inclusive')
      end

      it "is case-insensitive and correctly handles unitdatetype='Bulk' and 'Inclusive'" do
        records= run_date_conversion(
          "<did>
            <unitdate unitdatetype='Bulk' normal='1990/1995'>1990-1995</unitdate>
            <unitdate unitdatetype='Inclusive' normal='2000'>2000</unitdate>
          </did>"
        )

        expect(records.resource['dates'].length).to eq(2)
        expect(records.resource['dates'][0]['date_type']).to eq('bulk')
        expect(records.resource['dates'][1]['date_type']).to eq('inclusive')
      end
    end

    context "when <unitdate> is at the Archival Object level" do

      it "imports a <unitdate> with unitdatetype='bulk' as a Bulk date" do
        records = run_date_conversion("<dsc><c level='file'><did><unitdate unitdatetype='bulk' normal='1955/1965'>circa 1955-1965</unitdate></did></c></dsc>")
        expect(records.archival_object['dates'].length).to eq(1)
        expect(records.archival_object['dates'][0]['date_type']).to eq('bulk')
      end

      it "imports a <unitdate> with unitdatetype='inclusive' as an Inclusive date" do
        records = run_date_conversion("<dsc><c level='file'><did><unitdate unitdatetype='inclusive' normal='1975'>1975</unitdate></did></c></dsc>")
        expect(records.archival_object['dates'].length).to eq(1)
        expect(records.archival_object['dates'][0]['date_type']).to eq('inclusive')
      end

      it "defaults to an Inclusive date when the unitdatetype attribute is missing" do
        records = run_date_conversion("<dsc><c level='file'><did><unitdate normal='1985/1995'>1985-1995</unitdate></did></c></dsc>")
        expect(records.archival_object['dates'].length).to eq(1)
        expect(records.archival_object['dates'][0]['date_type']).to eq('inclusive')
      end
    end
  end

  describe "extent portion setting" do

    it "assigns extent portion 'whole' by default" do
      xml = <<~PHYSDESC
        <xml>
        <physdesc label="Extent (whole collection)" encodinganalog="300">
          2 items
        </physdesc>
        <physdesc label="Extent" encodinganalog="300">
          3 (items)
        </physdesc>
        <physdesc label="Extent" encodinganalog="300">
          3 things
        </physdesc>
        </xml>
      PHYSDESC
      resource = convert_and_return_resource(xml)
      expect(resource.extents.map {|e| e['portion'] }.uniq).to eq ["whole"]
    end
  end


  describe "container handler" do
    it "ignores empty container tags" do
      xml = <<~EAD
        <did>
          <container localtype="df"/>
        </did>
          EAD

      resource = convert_and_return_resource(xml)
      expect(resource.instances).to be_empty
    end

    it "creates an instance from a <container> tag" do
      xml = <<~EAD
        <did>
          <container localtype="box">123</container>
        </did>
          EAD

      resource = convert_and_return_resource(xml)
      expect(resource.instances.size).to eq 1
    end

    it "maps <container> correctly" do
      xml = <<~EAD
        <did>
          <container id="cid1" localtype="Box" label="Text">1</container>
          <container parent="cid1" localtype="Folder">1</container>
        </did>
               EAD

      records = convert_and_return_records(xml)
      sub_container = records.resource.instances[0]["sub_container"]
      expect(sub_container['type_2']).to eq('Folder')
      expect(sub_container["top_container"]["ref"]).to eq(records.top_container.uri)
    end

    it "maps <container> with combined type and indicator" do
      xml = <<~EAD
        <ead>
           <archdesc level="collection">
           <did>
              <unittitle>Test Resource</unittitle>
              <unitid>test-id</unitid>
              <physdesc label="extent">1 box</physdesc>
              <langmaterial><language langcode="eng">English</language></langmaterial>
              <unitdate normal="2025-09-11">2025</unitdate>
           </did>
           <dsc>
              <c level="file">
                 <did>
                 <unittitle>Test AO</unittitle>
                 <container localtype="box-folder">MSS-501/1</container>
                 </did>
              </c>
           </dsc>
           </archdesc>
        </ead>
       EAD

      records = convert_and_return_records(xml)
      archival_object = records.archival_object
      top_container = records.top_container
      sub_container = archival_object.instances[0]["sub_container"]
      expect(top_container.type).to eq "box"
      expect(top_container.indicator).to eq "MSS-501"
      expect(sub_container['type_2']).to eq('folder')
      expect(sub_container['indicator_2']).to eq('1')
      expect(sub_container["top_container"]["ref"]).to eq(top_container.uri)
    end

    it "understands implied box in sibling nodes" do
      xml = <<~EAD
        <root>
         <c02 id="mferd13e492" level="item">
            <did>
               <container localtype="box">1</container>
               <container localtype="folder">1</container>
               <unittitle>Collection Finding Aid</unittitle>
            </did>
         </c02>
         <c02 id="mferd13e503" level="file">
            <did>
               <container localtype="folder">2</container>
               <unittitle>Diskette status reports</unittitle>
            </did>
            <scopecontent>
               <p>A description of the project's electronic files, their
                          arrangement and location.</p>
            </scopecontent>
         </c02>
         <c02 id="mferd13e512" level="file">
            <did>
               <container localtype="folder">3</container>
               <unittitle>Log status reports.</unittitle>
            </did>
            <scopecontent>
               <p>Tables that note the status of individual logs for formatted
                          materials (sound recordings, graphic materials, and manuscripts) by fieldworker
                          and location (diskette, database, and printout).</p>
            </scopecontent>
         </c02>
        </root>
             EAD
      records = convert_and_return_records(xml)
      top_containers = records.top_containers
      expect(top_containers.size).to eq 1
      expect(top_containers[0].type).to eq "box"
      archival_objects = records.archival_objects
      expect(archival_objects[0].instances.size).to be 1
      sub_containers = archival_objects.map {|rec| rec.instances[0]["sub_container"] }
      expect(sub_containers.size).to eq 3
      sub_containers.each do |sc|
        expect(sc["top_container"]["ref"]).to eq top_containers[0].uri
      end
    end

    it "can understand comma separated data in container tags" do
      xml = <<~EAD
        <c04 id="mferd92e5277" level="file">
           <did>
              <container localtype="box-folder">72/5, 719/2</container>
              <unittitle encodinganalog="245$a">Long hot supper</unittitle>
           </did>
        </c04>
         EAD
      records = convert_and_return_records(xml)
      top_containers = records.top_containers
      archival_objects = records.archival_objects
      expect(top_containers.size).to eq 2
      expect(top_containers[0].type).to eq "Box"
      expect(top_containers[1].type).to eq "Box"
      expect(top_containers[0].indicator).to eq "719"
      expect(top_containers[1].indicator).to eq "72"
      expect(archival_objects[0].instances.size).to eq 2
      expect(archival_objects[0].instances[0].sub_container["top_container"]["ref"]).to eq top_containers[1].uri
      expect(archival_objects[0].instances[1].sub_container["top_container"]["ref"]).to eq top_containers[0].uri
      expect(archival_objects[0].instances[0].sub_container["type_2"]).to eq "folder"
      expect(archival_objects[0].instances[1].sub_container["type_2"]).to eq "folder"
      expect(archival_objects[0].instances[0].sub_container["indicator_2"]).to eq "5"
      expect(archival_objects[0].instances[1].sub_container["indicator_2"]).to eq "2"

      # and with a folder range:
      xml = <<~EAD
        <c04 id="mferd92e5295" level="file">
           <did>
              <container localtype="box-folder">73/3-4, 719/5</container>
              <unittitle encodinganalog="245$a">Whistle while you work</unittitle>
           </did>
        </c04>
         EAD
      records = convert_and_return_records(xml)
      top_containers = records.top_containers
      archival_objects = records.archival_objects
      expect(top_containers.size).to eq 2
      expect(top_containers[0].type).to eq "Box"
      expect(top_containers[1].type).to eq "Box"
      expect(top_containers[0].indicator).to eq "719"
      expect(top_containers[1].indicator).to eq "73"
      expect(archival_objects[0].instances.size).to eq 2
      expect(archival_objects[0].instances[0].sub_container["top_container"]["ref"]).to eq top_containers[1].uri
      expect(archival_objects[0].instances[1].sub_container["top_container"]["ref"]).to eq top_containers[0].uri
      expect(archival_objects[0].instances[0].sub_container["type_2"]).to eq "folder"
      expect(archival_objects[0].instances[1].sub_container["type_2"]).to eq "folder"
      expect(archival_objects[0].instances[0].sub_container["indicator_2"]).to eq "3-4"
      expect(archival_objects[0].instances[1].sub_container["indicator_2"]).to eq "5"
    end

    it "will not import container ranges at the series level when there are children with containers \
        but will import the range information as a physdesc note" do
      xml = <<~EAD
        <c01 id="mferd3e751" level="series">
           <did>
              <container localtype="box">1-124, 142-153</container>
              <unittitle id="ref_id10001" encodinganalog="245$a">Music, <date localtype="inclusive" normal="1934/1993">1934-1993</date>
              </unittitle>
           </did>
           <c02 id="mferd3e768" level="file">
              <did>
                 <container localtype="box/folder">97/11</container>
                 <unittitle id="ref_id10002" encodinganalog="245$a">Abigail,
                 </unittitle>
              </did>
           </c02>
        </c01>
         EAD
      records = convert_and_return_records(xml)
      top_containers = records.top_containers
      archival_objects = records.archival_objects
      expect(top_containers.size).to eq 1
      expect(top_containers[0].type).to eq "box"
      expect(top_containers[0].indicator).to eq "97"
      expect(archival_objects[1].instances.size).to eq 0
      expect(archival_objects[1].notes[0].type).to eq "physdesc"
      expect(archival_objects[1].notes[0].content[0]).to eq "Box: 1-124\nBox: 142-153"
      expect(archival_objects[0].instances.size).to eq 1
      expect(archival_objects[0].instances[0].sub_container["top_container"]["ref"]).to eq top_containers[0].uri
      expect(archival_objects[0].instances[0].sub_container["type_2"]).to eq "folder"
      expect(archival_objects[0].instances[0].sub_container["indicator_2"]).to eq "11"
    end

    it "will import container ranges at non series levels when there are no children with containers" do
      xml = <<~EAD
        <c01 id="mferd3e751" level="item">
           <did>
              <container localtype="box">1-124, 142-153</container>
              <unittitle id="ref_id10001" encodinganalog="245$a">Music, <date localtype="inclusive" normal="1934/1993">1934-1993</date>
              </unittitle>
           </did>
        </c01>
         EAD
      records = convert_and_return_records(xml)
      top_containers = records.top_containers
      archival_objects = records.archival_objects
      expect(top_containers.size).to eq 136
      expect(archival_objects[0].instances.size).to eq 136
      expect(archival_objects[0].instances.map {|i| i.sub_container["top_container"]["ref"] }.sort).to eq(top_containers.map {|tc| tc['uri'] }.sort)

      # and with some variations
      xml = <<~EAD
        <c01 id="mferd3e751" level="item">
           <did>
              <container localtype="pail">OV 1-124, OV 142-153</container>
              <unittitle id="ref_id10001" encodinganalog="245$a">Music, <date localtype="inclusive" normal="1934/1993">1934-1993</date>
              </unittitle>
           </did>
        </c01>
         EAD
      records = convert_and_return_records(xml)
      top_containers = records.top_containers
      archival_objects = records.archival_objects
      expect(top_containers.size).to eq 136
      expect(top_containers[0].indicator).to eq "OV 153"
      expect(top_containers[-1].indicator).to eq "OV 1"
      expect(archival_objects[0].instances.size).to eq 136
      expect(archival_objects[0].instances.map {|i| i.sub_container["top_container"]["ref"] }.sort).to eq(top_containers.map {|tc| tc['uri'] }.sort)

      # and another variation
      xml = <<~EAD
        <c01 id="mferd3e751" level="item">
           <did>
              <container localtype="pail">MSS1659-MSS1663</container>
              <unittitle id="ref_id10001" encodinganalog="245$a">Music, <date localtype="inclusive" normal="1934/1993">1934-1993</date>
              </unittitle>
           </did>
        </c01>
         EAD
      records = convert_and_return_records(xml)
      top_containers = records.top_containers
      archival_objects = records.archival_objects
      expect(top_containers.size).to eq 5
      expect(top_containers[0].indicator).to eq "MSS1663"
      expect(top_containers[-1].indicator).to eq "MSS1659"
      expect(archival_objects[0].instances.size).to eq 5
      expect(archival_objects[0].instances.map {|i| i.sub_container["top_container"]["ref"] }.sort).to eq(top_containers.map {|tc| tc['uri'] }.sort)
    end

    it "will import container ranges at series levels when there are no children with containers" do
      xml = <<~EAD
        <c01 id="mferd3e751" level="series">
           <did>
              <container localtype="box">1-124, 142-153</container>
              <unittitle id="ref_id10001" encodinganalog="245$a">Music, <date localtype="inclusive" normal="1934/1993">1934-1993</date>
              </unittitle>
           </did>
        </c01>
         EAD
      records = convert_and_return_records(xml)
      top_containers = records.top_containers
      expect(top_containers.size).to eq 136
    end

    it "propagates container information between parent and child objects" do
      xml = <<~EAD
         <snip>
           <c02 id="mferd76e1120" level="file">
              <did>
                 <container localtype="box">32</container>
                 <unittitle encodinganalog="245$a">Albion College, Albion, Mich.,<date encodinganalog="245$f" localtype="inclusive"> 1978-1980</date>
                 </unittitle>
                 <unitdate encodinganalog="245$f" unitdatetype="inclusive"> 1978-1980</unitdate>
              </did>
           </c02>
           <c02 id="mferd76e1131" level="file">
              <did>
                 <unittitle encodinganalog="245$a">Aluminum Co. of America, management program,
           <date encodinganalog="245$f" localtype="inclusive">1978</date>
                 </unittitle>
                 <unitdate encodinganalog="245$f" unitdatetype="inclusive">1978</unitdate>
              </did>
           </c02>
           <c02 id="mferd76e1158" level="file">
              <did>
                 <unittitle encodinganalog="245$a">American Enterprise Institute for Public Policy
        Research</unittitle>
              </did>
              <c03 id="mferd76e1162" level="file">
                 <did>
                    <unittitle encodinganalog="245$a">Administrative records</unittitle>
                 </did>
                 <c04 id="mferd76e1166" level="file">
                    <did>
                       <unittitle encodinganalog="245$a">Advisory Board</unittitle>
                    </did>
                    <c05 id="mferd76e1170" level="file">
                       <did>
                          <unittitle encodinganalog="245$a">Brandt, Karl, <date encodinganalog="245$f" localtype="inclusive">1960-1968, 1975</date>
                          </unittitle>
                          <unitdate encodinganalog="245$f" unitdatetype="inclusive">1960-1968,
                 1975</unitdate>
                       </did>
                    </c05>
                  </c04>
                </c03>
             </c02>
           </snip>
       EAD
      records = convert_and_return_records(xml)
      top_containers = records.top_containers
      archival_objects = records.archival_objects
      expect(top_containers.size).to eq 1
      expect(archival_objects.size).to eq 6
      archival_objects.each do |ao|
        expect(ao.instances.size).to eq 1
        expect(ao.instances[0].sub_container["top_container"]["ref"]).to eq top_containers[0].uri
      end
    end

    it "propagates containers with non-numerical indicators too" do
      xml = <<~EAD
        <snip>
             <c02 id="mferd139e16621" level="file">
                <did>
                   <container localtype="box">OV 4</container>
                   <unittitle encodinganalog="245$a">Madeline McDowell Breckenridge
          papers</unittitle>
                </did>
                <c03 id="mferd139e16627" level="file">
                   <did>
                      <unittitle encodinganalog="245$a">Subject file</unittitle>
                   </did>
                   <c04 id="mferd139e16631" level="file">
                      <did>
                         <unittitle encodinganalog="245$a">Women's suffrage </unittitle>
                      </did>
                   </c04>
                </c03>
             </c02>
          </snip>
       EAD
      records = convert_and_return_records(xml)
      top_containers = records.top_containers
      archival_objects = records.archival_objects
      expect(top_containers.size).to eq 1
      expect(archival_objects.size).to eq 3
      archival_objects.each do |ao|
        expect(ao.instances.size).to eq 1
        expect(ao.instances[0].sub_container["top_container"]["ref"]).to eq top_containers[0].uri
      end
    end


    it "can infer the top container from the parent archival object" do
      xml = <<~EAD
          <c02 id="mferd2e366" level="subseries">
           <did>
              <container localtype="box-folder">1/1</container>
              <unittitle encodinganalog="245$a">Magic Clippings; Part 1</unittitle>
           </did>
           <c03 id="mferd2e372" level="item">
              <did>
                 <container localtype="sleeve">1/1/a</container>
                 <unittitle encodinganalog="245$a">Ashworth, Norman. "Before Your
        Eyes."</unittitle>
              </did>
           </c03>
           <c03 id="mferd2e378" level="item">
              <did>
                 <container localtype="sleeve">1/1/a</container>
                 <unittitle encodinganalog="245$a">"Asahi Rope and Balls Trick as Performed by
        Asahi Troupe."</unittitle>
              </did>
           </c03>
          </c02>
              EAD

      records = convert_and_return_records(xml)
      top_container = records.top_container(0)
      expect(top_container.indicator).to eq("1")
      child1 = records.archival_object(0).instances[0]
      expect(child1.sub_container["top_container"]["ref"]).to eq top_container.uri
      expect(child1.sub_container["type_2"]).to eq("folder")
      expect(child1.sub_container["indicator_2"]).to eq("1")
      expect(child1.sub_container["type_3"]).to eq("sleeve")
      expect(child1.sub_container["indicator_3"]).to eq("a")
      child2 = records.archival_object(1).instances[0]
      expect(child2.sub_container["top_container"]["ref"]).to eq top_container.uri
      expect(child2.sub_container["type_2"]).to eq("folder")
      expect(child2.sub_container["indicator_2"]).to eq("1")
      expect(child2.sub_container["type_3"]).to eq("sleeve")
      expect(child2.sub_container["indicator_3"]).to eq("a")
      parent = records.archival_object(2).instances[0]
      expect(parent.sub_container["top_container"]["ref"]).to eq top_container.uri
      expect(parent.sub_container["type_2"]).to eq("folder")
      expect(parent.sub_container["indicator_2"]).to eq("1")
    end
  end

  describe "note importing" do
    it "imports head tag into note label" do
      xml = <<~EAD
        <odd>
          <head id="artists">Primary Recording Artists</head>
          <p>
          The following is a list extracted from the "Recording Artists" field of the NCTA database. See
          <ref target="accessandrestrictions">Access and Restrictions</ref>
          section for more information about the NCTA database. The list is provided to show the range of musicians and bands represented in the collection. See Appendix:
          <ref href="https://hdl.loc.gov/loc.afc/afcead.af020002.apx" actuate="onrequest" show="new">Recording Artists</ref>
          for additional performers accompanying the musicians and bands in this list, as well as instrumentation.
          </p>
        </odd>
             EAD

      resource = convert_and_return_resource(xml)
      expect(resource.notes[0].label).to eq "Primary Recording Artists"
      expect(resource.notes[0].subnotes[0]["content"]).to eq 'The following is a list extracted from the "Recording Artists" field of the NCTA database. See <ref target="accessandrestrictions">Access and Restrictions</ref> section for more information about the NCTA database. The list is provided to show the range of musicians and bands represented in the collection. See Appendix: <extref actuate="onrequest" href="https://hdl.loc.gov/loc.afc/afcead.af020002.apx" show="new">Recording Artists</extref> for additional performers accompanying the musicians and bands in this list, as well as instrumentation.'
    end

    it "can import tables etc" do
      xml = <<~EAD
              <odd id="mferd138e3154v">
                 <head althead="Locations" id="appendix">Appendix: Locations by Date</head>
                 <p>This appendix serves as an aid to researchers to better identify Schuyler’s locations by
        city and country and to find resources within the collection. The information in this
        appendix was compiled from Schuyler’s correspondence and scrapbook. </p>
                 <table>
                    <tgroup cols="10" align="left">
                       <colspec colnum="1" colname="col1" colwidth="30*"/>
                       <colspec colnum="2" colname="col2" colwidth="80*"/>
                       <thead valign="bottom">
                          <row>
                             <entry colname="col1" morerows="0">Date</entry>
                             <entry colname="col2" morerows="0">Location</entry>
                          </row>
                       </thead>
                       <tbody valign="top">
                          <row>
                             <entry colname="col1" morerows="0">1859, Nov. 12</entry>
                             <entry colname="col2" morerows="0">New Haven, Connecticut</entry>
                          </row>
                          <row>
                             <entry colname="col1" morerows="0">1862, Jan. 21</entry>
                             <entry colname="col2" morerows="0">New Haven, Connecticut</entry>
                          </row>
                       </tbody>
                    </tgroup>
                 </table>
              </odd>
                  EAD

      resource = convert_and_return_resource(xml)
      expect(resource.notes[0].label).to eq "Appendix: Locations by Date"
      expect(resource.notes[0].subnotes[0]["content"]).to eq "This appendix serves as an aid to researchers to better identify Schuyler’s locations by city and country and to find resources within the collection. The information in this appendix was compiled from Schuyler’s correspondence and scrapbook.\n\n<table> <tgroup align=\"left\" cols=\"10\"> <colspec colname=\"col1\" colnum=\"1\" colwidth=\"30*\"/> <colspec colname=\"col2\" colnum=\"2\" colwidth=\"80*\"/> <thead valign=\"bottom\"> <row> <entry colname=\"col1\" morerows=\"0\">Date</entry> <entry colname=\"col2\" morerows=\"0\">Location</entry> </row> </thead> <tbody valign=\"top\"> <row> <entry colname=\"col1\" morerows=\"0\">1859, Nov. 12</entry> <entry colname=\"col2\" morerows=\"0\">New Haven, Connecticut</entry> </row> <row> <entry colname=\"col1\" morerows=\"0\">1862, Jan. 21</entry> <entry colname=\"col2\" morerows=\"0\">New Haven, Connecticut</entry> </row> </tbody> </tgroup> </table>"
    end

    it "can import bibref tags as bibliography note items" do
      xml = <<~EAD
          <bibliography encodinganalog="510" id="mferd407e713v">
             <head>Bibliography</head>
             <bibref>
                <title>
                   <part>Guide to the Special Collections of Prints and Photographs in the Library
                of Congress</part>
                </title> / compiled by Paul Vanderbilt. Washington, D.C. : 1955, no. 534 (Available
        in the <ref show="new" actuate="onrequest" href="https://lccn.loc.gov/54060020">Prints and Photographs Reading Room</ref> and online through <ref show="new" actuate="onrequest"
                     href="https://catalog.hathitrust.org/Record/001469580">HathiTrust</ref>)
              </bibref>
             <bibref>
                Another bibref
              </bibref>
           </bibliography>
          EAD
      resource = convert_and_return_resource(xml)
      expect(resource.notes[0].items.size).to eq 2
    end

    it "can import archref tags" do
      xml = <<~EAD
        <relatedmaterial id="mferd1759e247">
           <head>Related Materials</head>
           <archref>A Stitch in Time: African American Quilters of
        Oakland, AFC 1991/010</archref>
           <archref>Alliance for American Quilts Interview
        Collection, AFC 2007/009</archref>
           <archref>Blue Ridge Parkway Folklife Project
        Collection, AFC 1982/009</archref>
        </relatedmaterial>
          EAD
      resource = convert_and_return_resource(xml)
      expect(resource.notes[0].subnotes.size).to eq 1
      expect(resource.notes[0].subnotes[0].items.size).to eq 3
      expect(resource.notes[0].subnotes[0].items[0]).to eq "A Stitch in Time: African American Quilters of Oakland, AFC 1991/010"
    end
  end

  describe "didnote handling" do
    it "can import a didnote tag as a multipart 'odd' note" do
      xml = <<~EAD
        <c04 id="mferd6e45072" level="file">
           <did>
              <unittitle id="ref_id11541" encodinganalog="245$a">B log
              (black-and-white photo log)</unittitle>
              <didnote encodinganalog="500" label="Note">Black-and-white log
              starts on page 12</didnote>
           </did>
        </c04>
          EAD
      record = convert_and_return_archival_object(xml)
      expect(record.notes[0]['type']).to eq("odd")
      expect(record.notes[0].subnotes[0]['content']).to eq("Black-and-white log starts on page 12")
      expect(record.notes[0]['label']).to eq("Note")
    end
  end

  describe "additional note behavior" do

    it "can ingest defined lists" do
      xml = <<~EAD
        <bioghist>
            <p>
               <emph render="bold">Related Publications:</emph>
            </p>
            <list listtype="deflist">
               <defitem>
                  <label>Chandler, James Winston</label>
                  <item>
                     <emph render="italic">The Function of the Choreographer in the Development of the
            Conceptual Musical: An Examination of the Work of Jerome Robbins, Bob Fosse,
            and Michael Bennett on Broadway Between 1944 and 1981.</emph> Ann Arbor, MI:
         UMI Dissertation Services, 1993.</item>
               </defitem>
               <defitem>
                  <label>Gargaro, Kenneth Vance</label>
                  <item>
                     <emph render="italic">The Work of Bob Fosse and the Choreographer-directors in the
            Translation of Musicals to the Screen</emph>. Ann Arbor, MI: University
         Microfilms International, 1980.</item>
               </defitem>
             </list>
           </bioghist>
        EAD
      resource = convert_and_return_resource(xml)
      expect(resource.notes.size).to eq 1
      expect(resource.notes[0].subnotes.size).to eq 2
      expect(resource.notes[0].subnotes[1].jsonmodel_type).to eq "note_definedlist"
    end

    it "imports nested bioghist head tags correctly" do
      with_top_level_head = <<~EAD
        <bioghist encodinganalog="545" id="mferd313e252v">
           <head>Biographical Sketches</head>
           <bioghist id="mferd313e255v">
              <head>Alice Eversman</head>
              <p>Alice Eversman was born on September 4, 1885, in Effingham, Illinois, to John Caspar...</p>
           </bioghist>
           <bioghist id="mferd313e290v">
              <head>Elena de Sayn</head>
              <p>Elena de Sayn (also known as Helena, Helen, or Yelena) was born on May 10...</p>
           </bioghist>
         </bioghist>
              EAD

      resource = convert_and_return_resource(with_top_level_head)
      expect(resource.notes.size).to eq 1
      expect(resource.notes[0].label).to eq "Biographical Sketches"
      expect(resource.notes[0].subnotes.size).to eq 2
      expect(resource.notes[0].subnotes[0].jsonmodel_type).to eq "note_text"
      expect(resource.notes[0].subnotes[0].content).to start_with "<head>Alice Eversman</head>\n\nAlice Eversman was born"
      expect(resource.notes[0].subnotes[1].jsonmodel_type).to eq "note_text"
      expect(resource.notes[0].subnotes[1].content).to start_with "<head>Elena de Sayn</head>\n\nElena de Sayn (also known"

      without_top_level_head = <<~EAD
        <bioghist encodinganalog="545" id="mferd313e252v">
           <bioghist id="mferd313e255v">
              <head>Alice Eversman</head>
              <p>Alice Eversman was born on September 4, 1885, in Effingham, Illinois, to John Caspar...</p>
           </bioghist>
           <bioghist id="mferd313e290v">
              <head>Elena de Sayn</head>
              <p>Elena de Sayn (also known as Helena, Helen, or Yelena) was born on May 10...</p>
           </bioghist>
         </bioghist>
              EAD

      resource = convert_and_return_resource(without_top_level_head)
      expect(resource.notes.size).to eq 1
      expect(resource.notes[0].label).to be_nil
      expect(resource.notes[0].subnotes.size).to eq 2
      expect(resource.notes[0].subnotes[0].jsonmodel_type).to eq "note_text"
      expect(resource.notes[0].subnotes[0].content).to start_with "<head>Alice Eversman</head>\n\nAlice Eversman was born"
      expect(resource.notes[0].subnotes[1].jsonmodel_type).to eq "note_text"
      expect(resource.notes[0].subnotes[1].content).to start_with "<head>Elena de Sayn</head>\n\nElena de Sayn (also known"
    end

    it "can import odd notes with &amp entities" do
      odd_with_table = <<~EAD
        <odd>
            <head althead="Research &amp; Scholarly Orgs">Research and Scholarly Organizations </head>
            <table>
                <tgroup cols="2">
                    <colspec colwidth="50*"/>
                    <colspec colwidth="50*"/>
                    <thead>
                        <row>
                            <entry>Name</entry>
                            <entry>LCCN</entry>
                        </row>
                    </thead>
                    <tbody>
                        <row>
                            <entry>American Council of Learned Societies records, 1910-2011</entry>
                            <entry>
                                <ref href="https://lccn.loc.gov/mm80054288">
                                    https://lccn.loc.gov/mm80054288</ref>
                            </entry>
                        </row>
                    </tbody>
                </tgroup>
            </table>
          </odd>
              EAD

      resource = convert_and_return_resource(odd_with_table)
      expect(resource.notes.size).to eq 1
      expect(resource.notes[0].label).to eq "Research and Scholarly Organizations"
      expect(resource.notes[0].subnotes.size).to eq 1
      expect(resource.notes[0].subnotes[0].jsonmodel_type).to eq "note_text"
      expect(resource.notes[0].subnotes[0].content).to start_with "<table>"
    end

    it "can import defined lists with listhead elements" do
      deflist = <<~EAD
        <relatedmaterial encodinganalog="544 1" id="mferd81e228v">
           <head> Related Archival Collections at the Library of Congress </head>
           <list listtype="deflist">
              <listhead>
                 <head01 id="nbcarch"> The NBC Archives at the Library of Congress include the NBC
        Press Releases (the subject of this finding aid) as well as the following archival
        NBC collections. </head01>
              </listhead>
              <defitem>
                 <label>NBC History Files </label>
                 <item> The National Broadcasting Company History files include memoranda,
        correspondence, speeches, reports, policy statements, and pamphlets covering the
        creation of the network, its growth in the field of radio, and its subsequent
        expansion into television broadcasting. </item>
              </defitem>
              <defitem>
                 <label>Radio Log Books. Manuscript </label>
                 <item> The Library holds log books for WEAF and WNBC (1922 - 1955), for WJZ (1923 -
        1941), and for WJY (1923 - 1926.) </item>
              </defitem>
           </list>
        </relatedmaterial>
              EAD

      resource = convert_and_return_resource(deflist)
      expect(resource.notes.size).to eq 1
      expect(resource.notes[0].label).to eq "Related Archival Collections at the Library of Congress"
      expect(resource.notes[0].subnotes.size).to eq 1
      expect(resource.notes[0].subnotes[0].jsonmodel_type).to eq "note_definedlist"
      expect(resource.notes[0].subnotes[0].title).to eq "The NBC Archives at the Library of Congress include the NBC Press Releases (the subject of this finding aid) as well as the following archival NBC collections."
    end

    it "can import notes with blockquote elements" do
      deflist = <<~EAD
           <odd>
              <blockquote>
                 <p> “From General Marshall’s 3rd Report prepared from hemisphere drawing in
        Atlas for U.S. Citizen. B&amp;W-colored for this report. 1945.” </p>
              </blockquote>
              <blockquote>
                 <p>
                    <emph>Fortune</emph> map for General Marshall’s Third Report October 1945.
        This view is that from a great circle route from the United States to
        Europe.” </p>
              </blockquote>
           </odd>
              EAD

      resource = convert_and_return_resource(deflist)
      expect(resource.notes.size).to eq 1
      expect(resource.notes[0].subnotes.size).to eq 1
      expect(resource.notes[0].subnotes[0].jsonmodel_type).to eq "note_text"
      expect(resource.notes[0].subnotes[0].content).to eq "<blockquote>\n\n“From General Marshall’s 3rd Report prepared from hemisphere drawing in Atlas for U.S. Citizen. B&amp;W-colored for this report. 1945.”\n\n</blockquote>\n<blockquote>\n\n<emph>Fortune</emph> map for General Marshall’s Third Report October 1945. This view is that from a great circle route from the United States to Europe.”\n\n</blockquote>"
    end

    it "converts paragraphs into double line breaks" do
      xml = <<~EAD
        <odd>
          <head id="artists">label</head>
          <p>
          foo
          </p>
          <p>
          bar
          </p>
        </odd>
             EAD
      resource = convert_and_return_resource(xml)
      expect(resource.notes[0].label).to eq "label"
      expect(resource.notes[0].subnotes[0]["content"]).to eq "foo\n\nbar"
    end
  end

  describe "maintenance history and revision statement" do
    it "converts <maintenancehistory> into a revision_statment subrecord" do
      xml = <<~XML
        <maintenancehistory>
           <maintenanceevent>
              <eventtype value="revised"/>
              <eventdatetime standarddatetime="2021-03">2021 March</eventdatetime>
              <agenttype value="human"/>
              <agent>Manuscript Division staff</agent>
              <eventdescription>Addition of records for three globe gores</eventdescription>
           </maintenanceevent>
        </maintenancehistory>
          XML
      resource = convert_and_return_resource(xml)
      expect(resource.revision_statements[0]['date']).to eq("2021-03")
      expect(resource.revision_statements[0]['agent_type']).to eq("human")
      expect(resource.revision_statements[0]['agent']).to eq("Manuscript Division staff")
    end
  end
end
