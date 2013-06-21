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
end

