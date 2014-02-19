class FileVersion < Sequel::Model(:file_version)
  include ASModel
  corresponds_to JSONModel(:file_version)

  def self.handle_publish_flag(ids, val)
    ASModel.update_publish_flag(self.filter(:id => ids), val)
  end

  set_model_scope :global

  def self.sequel_to_jsonmodel(obj, opts = {})
    json = super
    json["identifier"] = obj[:id]

    json
  end
  
end
