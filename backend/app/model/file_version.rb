require_relative 'mixins/publishable'

class FileVersion < Sequel::Model(:file_version)
  include ASModel
  include Publishable
  include Representative

  corresponds_to JSONModel(:file_version)

  def representative_for_types
    { is_representative: [:digital_object] }
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
    # Discuss: I was getting false negatives with just `if !self[:publish] && self[:is_representative]`, so taking more explicit approach:
    is_published = false
    if self[:publish] == true || self[:publish] == 1
      is_published = true
    end

    is_representative = false
    if self[:is_representative] == true || self[:is_representative] == 1
      is_representative = true
    end

    if !is_published && is_representative
      raise Sequel::ValidationFailed.new("File version must be published to be representative.")
    end

    super
  end

end
