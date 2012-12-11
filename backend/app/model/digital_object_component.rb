require_relative 'orderable'
require_relative 'notes'

class DigitalObjectComponent < Sequel::Model(:digital_object_component)
  plugin :validation_helpers
  include ASModel
  include Subjects
  include Extents
  include Dates
  include ExternalDocuments
  include Agents
  include Orderable
  include Notes
  include RightsStatements

  orderable_root_record_type :digital_object, :digital_object_component

  set_model_scope :repository


  def self.sequel_to_jsonmodel(obj, type, opts = {})
    json = super

    json
  end

end
