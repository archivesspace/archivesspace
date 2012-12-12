require_relative 'notes'

class DigitalObject < Sequel::Model(:digital_object)
  plugin :validation_helpers
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

  def link(opts)
    child = DigitalObjectComponent.get_or_die(opts[:child])
    child.digital_object_id = self.id
    child.parent_id = opts[:parent]
    child.save
  end


  def self.records_matching(query, max)
    self.this_repo.where(Sequel.like(Sequel.function(:lower, :title),
                                     "#{query}%".downcase)).first(max)
  end

end
