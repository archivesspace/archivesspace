require 'spec_helper'
require_relative '../app/converters/ead_converter'

describe 'EAD converter' do

  let (:test_doc_1) {
    src = <<ANEAD
<c id="1" level="file">
  <unittitle>oh well</unittitle>
  <container id="cid1" type="Box" label="Text">1</container>
  <container parent="cid2" type="Folder"></container>
  <unitdate normal="1907/1911" era="ce" calendar="gregorian" type="inclusive">1907-1911</unitdate>
  <c id="2" level="file">
    <unittitle>whatever</unittitle>
    <container id="cid3" type="Box" label="Text">FOO</container>
  </c>
</c>
ANEAD

    tmp = Tempfile.new("doc1")
    tmp.write(src)
    tmp.close
    tmp.path
  }


  it "should be able to manage empty tags" do
    converter = EADConverter.new(test_doc_1)
    converter.run
    parsed = JSON(IO.read(converter.get_output_path))

    parsed.length.should eq(2)
    parsed.find{|r| r['ref_id'] == '1'}['instances'][0]['container']['type_2'].should eq('Folder')
  end

end
