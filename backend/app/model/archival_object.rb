require_relative 'notes'
require_relative 'orderable'
require_relative 'auto_id_generator'

class ArchivalObject < Sequel::Model(:archival_object)
  include ASModel
  include Subjects
  include Extents
  include Dates
  include ExternalDocuments
  include RightsStatements
  include Instances
  include Agents
  include Orderable
  include AutoIdGenerator::Mixin
  include Notes
  include ExternalIDs

  orderable_root_record_type :resource, :archival_object

  set_model_scope :repository
  corresponds_to JSONModel(:archival_object)

  register_auto_id :ref_id


  def validate
    validates_unique([:root_record_id, :ref_id],
                     :message => "An Archival Object Ref ID must be unique to its resource")
    map_validation_to_json_property([:root_record_id, :ref_id], :ref_id)
    super
  end
end
