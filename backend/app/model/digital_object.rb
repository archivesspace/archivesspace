require_relative 'notes'

class DigitalObject < Sequel::Model(:digital_object)
  include ASModel
  include Subjects
  include Extents
  include Dates
  include ExternalDocuments
  include Agents
  include Trees
  include Notes
  include RightsStatements
  include ExternalIDs

  tree_of(:digital_object, :digital_object_component)
  set_model_scope :repository
  corresponds_to JSONModel(:digital_object)

end
