require_relative 'mixins/publishable'

class FileVersion < Sequel::Model(:file_version)
  include ASModel
  include Publishable

  corresponds_to JSONModel(:file_version)

  def before_validation
    super

    self.is_representative = nil if self.is_representative != 1
  end


  def validate
    if is_representative
      validates_unique([:is_representative, :digital_object_id],
                       :message => "A digital object can only have one representative file version")
      map_validation_to_json_property([:is_representative, :digital_object_id], :is_representative)

    end

    super
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
