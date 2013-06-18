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
  include ComponentsAddChildren

  agent_relator_enum("linked_agent_archival_record_relators")

  orderable_root_record_type :resource, :archival_object

  set_model_scope :repository

  auto_generate :property => :ref_id,
                :generator => proc { |json|
                  SecureRandom.hex
                },
                :only_on_create => true
                
  auto_generate :property => :label,
                :generator => proc { |json|
                  label = json['title'] || ""

                  date_label = json.has_key?('dates') && json['dates'].length > 0 ?
                                lambda {|date|
                                  if date['expression']
                                    date['expression']
                                  elsif date['begin'] and date['end']
                                    "#{date['begin']} - #{date['end']}"
                                  else
                                    date['begin']
                                  end
                                }.call(json['dates'].first) : false

                  label += ", " if json['title'] && date_label
                  label += date_label if date_label

                  label
                }

  def validate
    validates_unique([:root_record_id, :ref_id],
                     :message => "An Archival Object Ref ID must be unique to its resource")
    map_validation_to_json_property([:root_record_id, :ref_id], :ref_id)
    super
  end

end
