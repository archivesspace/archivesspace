class FileVersion < Sequel::Model(:file_version)
  include ASModel
  include Publishable
  include Representative

  corresponds_to JSONModel(:file_version)

  def representative_for_types
    {
      is_display_thumbnail: [:digital_object, :digital_object_component],
      is_display_link: [:digital_object, :digital_object_component],
    }
  end

  def self.handle_publish_flag(ids, val)
    ASModel.update_publish_flag(self.filter(:id => ids), val)
  end

  set_model_scope :global

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json["identifier"] = obj[:id].to_s
    end

    jsons
  end

  def validate
    is_published = [true, 1].include?(self[:publish])
    is_display_thumbnail = [true, 1].include?(self[:is_display_thumbnail])
    is_display_link = [true, 1].include?(self[:is_display_link])

    if !is_published && is_display_thumbnail
      errors.add(:is_display_thumbnail, 'display_thumbnail_must_be_published')
    end

    if !is_published && is_display_link
      errors.add(:is_display_link, 'display_link_must_be_published')
    end

    super
  end

end
