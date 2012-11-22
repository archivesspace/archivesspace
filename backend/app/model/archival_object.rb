require 'securerandom'
require_relative 'orderable'

class ArchivalObject < Sequel::Model(:archival_object)
  plugin :validation_helpers
  include ASModel
  include Subjects
  include Extents
  include Dates
  include ExternalDocuments
  include RightsStatements
  include Instances
  include Agents
  include Orderable

  orderable_root_record_type :resource, :archival_object

  set_model_scope :repository


  def before_create
    super
    self.ref_id = SecureRandom.hex if self.ref_id.nil?
  end


  def update_from_json(json, opts = {})
    # don't allow ref_id to be updated
    json.ref_id = self.ref_id

    super
  end


  def validate
    validates_unique([:root_record_id, :ref_id],
                     :message => "An Archival Object Ref ID must be unique to its resource")
    map_validation_to_json_property([:root_record_id, :ref_id], :ref_id)
    super
  end


  def self.records_matching(query, max)
    self.this_repo.where(Sequel.like(Sequel.function(:lower, :title),
                                     "#{query}%".downcase)).first(max)
  end

end
