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


  tree_of(:digital_object, :digital_object_component)
  set_model_scope :repository
  corresponds_to JSONModel(:digital_object)

  def link(opts)
    child = DigitalObjectComponent.get_or_die(opts[:child])
    child.digital_object_id = self.id
    child.parent_id = opts[:parent]
    child.save
  end
end
