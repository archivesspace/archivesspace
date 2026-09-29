# Builders shared by the thumbnail mixin specs
module ThumbnailSpecHelper
  def image_file_version(opts = {})
    build(:json_file_version, {
      :publish => true,
      :file_uri => "http://example.com/#{generate(:alphanumstr)}.jpg",
      :file_format_name => 'jpeg',
      :xlink_show_attribute => 'embed',
      :caption => nil,
    }.merge(opts))
  end

  def link_file_version(opts = {})
    build(:json_file_version, {
      :publish => true,
      :file_uri => "http://example.com/#{generate(:alphanumstr)}.pdf",
      :file_format_name => 'pdf',
      :xlink_show_attribute => 'new',
      :caption => nil,
    }.merge(opts))
  end

  def digital_object_with(file_versions, opts = {})
    create(:json_digital_object, {
      :publish => true,
      :digital_object_type => 'still_image',
      :file_versions => file_versions,
    }.merge(opts))
  end

  def thumbnail_for(model, record)
    model.to_jsonmodel(record.id)['thumbnail']
  end

  def representative_instance(digital_object, is_representative = true)
    build(:json_instance_digital,
          :digital_object => {'ref' => digital_object.uri},
          :is_representative => is_representative)
  end
end
