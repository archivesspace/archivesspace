require 'spec_helper'
require 'converter_spec_helper'

require_relative '../app/converters/marcxml_accession_converter'

describe 'MARCXML Accession converter' do
  let(:my_converter) {
    MarcXMLAccessionConverter
  }


  describe "Basic MARCXML to Accession Record mappings" do
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
              <datafield tag="506" ind2=" " ind1="2">
                  <subfield code="3">SF 3</subfield>
                  <subfield code="c">SF C</subfield>
                  <subfield code="x">SF X</subfield>
              </datafield>
              <datafield tag="510" ind2=" " ind1="2">
                  <subfield code="3">SF 3</subfield>
                  <subfield code="c">SF C</subfield>
                  <subfield code="x">SF X</subfield>
              </datafield>
              <datafield tag="520" ind2=" " ind1="2">
                  <subfield code="a">SF A</subfield>
                  <subfield code="b">SF B</subfield>
                  <subfield code="c">SF C</subfield>
              </datafield>
              <datafield tag="540" ind2=" " ind1="2">
                  <subfield code="a">SF A</subfield>
              </datafield>
              <datafield tag="541" ind2=" " ind1="2">
                  <subfield code="a">541 SF A</subfield>
              </datafield>
              <datafield tag="561" ind2=" " ind1="2">
                  <subfield code="a">561 SF A</subfield>
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

      get_tempfile_path(src)
    }

    let (:test_doc_2) {
      src = <<END
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <collection xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd" xmlns="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <record>
              <leader>00000npc a2200000 u 4500</leader>
              <controlfield tag="008">130109i19601970xx                  eng d</controlfield>
              <datafield tag="040" ind2=" " ind1=" ">
                  <subfield code="a">Repositories.Agency Code 2-AT</subfield>
                  <subfield code="b">eng</subfield>
                  <subfield code="c">Repositories.Agency Code 2-AT</subfield>
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
              <datafield tag="506" ind2=" " ind1="1">
                  <subfield code="3">SF 3</subfield>
                  <subfield code="c">SF C</subfield>
                  <subfield code="x">SF X</subfield>
              </datafield>
              <datafield tag="510" ind2=" " ind1="2">
                  <subfield code="3">SF 3</subfield>
                  <subfield code="c">SF C</subfield>
                  <subfield code="x">SF X</subfield>
              </datafield>
              <datafield tag="520" ind2=" " ind1="2">
                  <subfield code="a">SF A</subfield>
                  <subfield code="b">SF B</subfield>
                  <subfield code="c">SF C</subfield>
              </datafield>
              <datafield tag="541" ind2=" " ind1="2">
                  <subfield code="a">541 SF A</subfield>
              </datafield>
              <datafield tag="561" ind2=" " ind1="2">
                  <subfield code="a">561 SF A</subfield>
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

      get_tempfile_path(src)
    }


    before(:all) do
      parsed = convert(test_doc_1)
      @accession = parsed.last
      @subjects = parsed.select{|r| r['jsonmodel_type'] == 'subject'}

      parsed2 = convert(test_doc_2)
      @accession2 = parsed2.last      
    end


    it "creates an Accession instead of a Resource" do
      @accession['jsonmodel_type'].should eq("accession")
    end

    it "maps field 506 to accession['access_restrictions_note']" do
      @accession['access_restrictions_note'].should eq("SF 3 SF C SF X")
    end

    it "maps field 245 to accession['title']" do
      @accession['title'].should eq("SF A : [SF H] SF N / SF C")
    end

    it "maps field 520 to accession.content_description" do
      @accession['content_description'].should eq("SF A SF B SF C");
    end

    it "maps field 540 to accession.use_restrictions_note" do
      @accession['use_restrictions_note'].should eq("SF A");
    end

    it "maps field 541 and 561 to accession.content_description" do
      @accession['provenance'].should eq("541 SF A 561 SF A");
    end

    it "sets use_restrictions based on 540" do
      @accession['use_restrictions'].should be_true
      @accession2['use_restrictions'].should be_false
    end

    it "sets access_restrictions based on 506@ind1" do
      @accession['access_restrictions'].should be_false
      @accession2['access_restrictions'].should be_true
    end
  end
end
