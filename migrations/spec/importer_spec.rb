require_relative "spec_helper"
require 'tempfile'


describe "ASpaceImport::Importer" do

  before(:each) do
    @repo_id = 2
  end


  it "should be able to create and register an importer sub-class" do
    ASpaceImport::Importer.importer :foo do
      def greet; "bar"; end
    end

    ASpaceImport::Importer.create_importer(:importer => :foo, :repo_id => @repo_id).greet.should eq("bar")
  end


  it "should not let two importers be registered  under the same key" do
    expect { ASpaceImport::Importer.importer :sgml do "Imports stuff" end }.to_not raise_error
    expect { ASpaceImport::Importer.importer :sgml do "Imports other stuff" end }.to raise_error
  end

  describe "ASpaceImport::Importer::EadImporter" do

    it "should be able to manaage empty tags" do

      doc1_src = <<ANEAD

<c id="1" level="file">
  <unittitle>oh well</unittitle>
  <container id="cid1" type="Box" label="Text"></container>
  <container parent="cid2" type="Folder"></container>
  <unitdate normal="1907/1911" era="ce" calendar="gregorian" type="inclusive">1907-1911</unitdate>
  <c id="2" level="file">
    <unittitle>whatever</unittitle>
    <container id="cid3" type="Box" label="Text">FOO</container>
  </c>
</c>
ANEAD

      doc = Tempfile.new("doc1")
      btch = Tempfile.new("batch")

      doc.write(doc1_src)
      doc.close

      FileUtils.copy_file(doc.path, "#{Dir.pwd}/doc.xml")


      i = ASpaceImport::Importer.create_importer(:importer => :ead,
                                                 :repo_id => @repo_id,
                                                 :input_file => doc.path,
                                                 :dry => true,
                                                 :batch_path => btch.path)
      i.run_safe do |message|
        message.has_key?('error').should be(false)
        message.has_key?('errors').should be(false)
      end

      b = IO.read(btch.path)

      batch = JSON.parse(b)
      batch.length.should eq(2)
      batch.find{|r| r['ref_id'] == '1'}['instances'][0]['container']['type_1'].should eq('Box')
    end
  end

  describe "ASpaceImport::Importer::MARCXMLImporter" do

    before(:all) do
      doc1_src = <<MARC

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
MARC

      doc = Tempfile.new("doc1")
      btch = Tempfile.new("batch")

      doc.write(doc1_src)
      doc.close

      FileUtils.copy_file(doc.path, "#{Dir.pwd}/doc.xml")


      i = ASpaceImport::Importer.create_importer(:importer => :marcxml,
                                                 :repo_id => 2,
                                                 :input_file => doc.path,
                                                 :dry => true,
                                                 :batch_path => btch.path)
      i.run_safe do |message|
        message.has_key?('error').should be(false)
        message.has_key?('errors').should be(false)
      end

      b = IO.read(btch.path)

      batch = JSON.parse(b)
      @resource = batch.last
      @subjects = batch.select{|r| r['jsonmodel_type'] == 'subject'}
    end

    # "{$a : }{$b }{[$h] }{$k , }{$n , }{$p , }{$s }{/ $c}"
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
      @subjects[1]['terms'].map {|t| t['term_type']}.sort.should eq(%w(uniform_title uniform_title topical).sort)
    end

    it "maps field 69* to resource['subjects']" do
      @subjects[0]['terms'][0]['term'].should eq("SF 3--SF A--SF D--SF X")
    end
  end
end

