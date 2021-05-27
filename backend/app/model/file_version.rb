require_relative 'mixins/publishable'

class FileVersion < Sequel::Model(:file_version)
  include ASModel
  include Publishable
  include Representative

  corresponds_to JSONModel(:file_version)

  def representative_for_types
    [:digital_object]
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

end
