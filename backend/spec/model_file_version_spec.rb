require 'spec_helper'

describe 'FileVersion model' do
  {
    :is_display_thumbnail => 'display_thumbnail_must_be_published',
    :is_display_link => 'display_link_must_be_published',
  }.each do |flag, publish_error|
    it "reports '#{publish_error}' for an unpublished file version flagged '#{flag}'" do
      file_version = FileVersion.new(:file_uri => 'http://foo.com/bar', :publish => 0, flag => 1)

      expect(file_version.valid?).to be false
      expect(file_version.errors[flag]).to include(publish_error)
    end
  end

  it 'strips whitespace around the file URI when it is saved' do
    file_uri = 'http://hdl.handle.net/2333.1/wpzgmtgj?urlappend=/mode/thumb'
    digital_object = create(:json_digital_object,
                            :file_versions => [build(:json_file_version, :file_uri => " #{file_uri}\n")])

    expect(DigitalObject.to_jsonmodel(digital_object.id)['file_versions'].first['file_uri']).to eq(file_uri)

    json = DigitalObject.to_jsonmodel(digital_object.id)
    json['file_versions'].first['file_uri'] = "\t#{file_uri}/updated "
    DigitalObject[digital_object.id].update_from_json(json)

    expect(DigitalObject.to_jsonmodel(digital_object.id)['file_versions'].first['file_uri']).to eq("#{file_uri}/updated")
  end

  it 'rejects a file URI of only whitespace as missing (ANW-3089)' do
    file_version = FileVersion.new(:file_uri => " \t\n", :publish => 0)

    expect(file_version.valid?).to be false
    expect(file_version.errors[:file_uri]).to include('missing_required_property')
  end
end
