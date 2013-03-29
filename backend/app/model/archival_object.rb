require_relative 'notes'
require_relative 'orderable'
require_relative 'auto_generator'
require 'securerandom'

class ArchivalObject < Sequel::Model(:archival_object)
  include ASModel
  corresponds_to JSONModel(:archival_object)

  include Subjects
  include Extents
  include Dates
  include ExternalDocuments
  include RightsStatements
  include Instances
  include Agents
  include Orderable
  include AutoGenerator
  include Notes
  include ExternalIDs

  agent_role_enum("linked_agent_archival_record_roles")
  agent_relator_enum("linked_agent_archival_record_relators")

  orderable_root_record_type :resource, :archival_object

  set_model_scope :repository

  auto_generate :property => :ref_id,
                :generator => proc { |json|
                  SecureRandom.hex
                },
                :only_on_create => true
                
  auto_generate :property => :title,
                :generator => proc { |json|
                  lambda {|date|
                    if date['expression']
                      date['expression']
                    elsif date['begin'] and date['end']
                      "#{date['begin']} -- #{date['end']}"
                    else
                      date['begin']
                    end
                  }.call(json[:dates].first)
                },
                :only_if => proc { |json| json.title_auto_generate }


  def validate
    validates_unique([:root_record_id, :ref_id],
                     :message => "An Archival Object Ref ID must be unique to its resource")
    map_validation_to_json_property([:root_record_id, :ref_id], :ref_id)
    super
  end
end
