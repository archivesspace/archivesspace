# encoding: utf-8
require 'spec_helper'
require 'converter_spec_helper'

require_relative '../app/converters/digital_object_converter'

describe 'Digital Object converter' do

  def my_converter
    DigitalObjectConverter
  end


  before(:all) do
    test_file = File.expand_path("../../frontend/public/bulk_import_templates/aspace_digital_object_import_template.csv",
                                 File.dirname(__FILE__))
    @records = convert(test_file)
    @digital_objects = @records.select {|r| r['jsonmodel_type'] == 'digital_object' }
  end


  it "did something" do
    expect(@digital_objects[0]).not_to be_nil

    expect(@digital_objects[0]['jsonmodel_type']).to eq('digital_object')
    expect(@digital_objects[0]['level']).to eq('image')
    expect(@digital_objects[0]['title']).to eq('a new digital object')
    expect(@digital_objects[0]['publish']).to be_truthy
  end



  it "maps digital_object_file version information to the object" do
    expect(@digital_objects[0]['file_versions'].length).to eq(1)
    {"jsonmodel_type"=>"file_version", "uri"=>nil, "file_uri"=>"http://aspace.me", "publish"=>true, "use_statement"=>"It's all good", "xlink_actuate_attribute"=>"onRequest", "xlink_show_attribute"=>"embed", "file_format_name"=>"jpeg", "file_format_version"=>"1", "file_size_bytes"=>100, "checksum"=>"xxxxxxx", "checksum_method"=>"md5"}.each do |k, v|
      expect(@digital_objects[0]["file_versions"][0][k]).to eq(v)
    end
    expect(@digital_objects[0]["file_versions"][0]["file_size_bytes"]).to be_a(Integer)
  end


  describe "utf-8 encoding" do
    let(:test_file_bom) {
      File.expand_path('./examples/digital_object/test_digital_object_utf8_bom.csv',
                       File.dirname(__FILE__))
    }

    it "does something even if its a kooky utf-8 file with a BOM" do
      @records = convert(test_file_bom)
      @digital_objects = @records.select {|r| r['jsonmodel_type'] == 'digital_object' }

      expect(@digital_objects[0]).not_to be_nil

      expect(@digital_objects[0]['jsonmodel_type']).to eq('digital_object')
      expect(@digital_objects[0]['title']).to eq('DO test ¥j¥ü¥Ó/anne')
    end
  end

  describe "multiple file versions" do
    before(:all) do
      test_file = File.expand_path('./examples/digital_object/test_digital_object_multi_file_versions.csv',
                                   File.dirname(__FILE__))
      @multi_records = convert(test_file)
      @multi_dos = @multi_records.select {|r| r['jsonmodel_type'] == 'digital_object' }
    end

    it "creates a file version for each numbered column group" do
      expect(@multi_dos[0]['file_versions'].length).to eq(2)
    end

    it "maps _1 file version fields correctly" do
      fv = @multi_dos[0]['file_versions'][0]
      expect(fv['file_uri']).to eq('http://example.com/file1.jpg')
      expect(fv['publish']).to be true
      expect(fv['is_representative']).to be true
      expect(fv['caption']).to eq('First file')
    end

    it "maps _2 file version fields correctly" do
      fv = @multi_dos[0]['file_versions'][1]
      expect(fv['file_uri']).to eq('http://example.com/file2.pdf')
      expect(fv['publish']).to be false
      expect(fv['is_representative']).to be false
      expect(fv['caption']).to eq('Second file')
    end

    it "skips a numbered group whose URI is the literal string NULL" do
      do_with_null_uri = @multi_dos[1]
      expect(do_with_null_uri['file_versions'].length).to eq(1)
      expect(do_with_null_uri['file_versions'][0]['file_uri']).to eq('http://example.com/only.jpg')
    end

    it "skips a numbered group whose URI is blank" do
      expect(@multi_dos[2]['file_versions'].length).to eq(1)
      expect(@multi_dos[2]['file_versions'][0]['file_uri']).to eq('http://example.com/blank.jpg')
    end

    it "strips leading and trailing whitespace from string fields" do
      expect(@multi_dos[3]['file_versions'][0]['caption']).to eq('Padded caption')
    end

    it "treats the literal string NULL in a non-URI field as unset" do
      fv = @multi_dos[4]['file_versions'][0]
      expect(fv['file_uri']).to eq('http://example.com/nullfield.jpg')
      expect(fv['caption']).to be_nil
    end
  end


  describe "file version backward compatibility" do
    before(:all) do
      test_file = File.expand_path('./examples/digital_object/test_digital_object_backward_compat.csv',
                                   File.dirname(__FILE__))
      @compat_records = convert(test_file)
      @compat_dos = @compat_records.select {|r| r['jsonmodel_type'] == 'digital_object' }
    end

    it "handles un-suffixed file_version_* columns from old CSVs" do
      expect(@compat_dos[0]['file_versions'].length).to eq(1)
      expect(@compat_dos[0]['file_versions'][0]['file_uri']).to eq('http://example.com/oldstyle.jpg')
      expect(@compat_dos[0]['file_versions'][0]['publish']).to be true
      expect(@compat_dos[0]['file_versions'][0]['caption']).to eq('Old style')
    end
  end
end
