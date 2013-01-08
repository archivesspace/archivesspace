require_relative 'orderable'
require_relative 'notes'

class DigitalObjectComponent < Sequel::Model(:digital_object_component)
  include ASModel
  include Subjects
  include Extents
  include Dates
  include ExternalDocuments
  include Agents
  include Orderable
  include Notes
  include RightsStatements
  include ExternalIDs

  orderable_root_record_type :digital_object, :digital_object_component

  set_model_scope :repository
  corresponds_to JSONModel(:digital_object_component)

end
