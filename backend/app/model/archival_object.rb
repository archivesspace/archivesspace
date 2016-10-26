require 'securerandom'
require_relative 'ancestor_listing'


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
  include TreeNodes
  include AutoGenerator
  include Notes
  include ExternalIDs
  include ComponentsAddChildren
  include Transferable
  include Events
  include Publishable
  include ReindexTopContainers
  include ArchivalObjectSeries
  include RightsRestrictionNotes
  include MapToAspaceContainer
  include RepresentativeImages

  enable_suppression

  agent_role_enum("linked_agent_role")
  agent_relator_enum("linked_agent_archival_record_relators")

  tree_record_types :resource, :archival_object

  set_model_scope :repository

  auto_generate :property => :ref_id,
                :generator => proc { |json|
                  SecureRandom.hex
                },
                :only_on_create => true

  auto_generate :property => :display_string,
                :generator => proc { |json|
                  display_string = json['title'] || ""

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

                  display_string += ", " if json['title'] && date_label
                  display_string += date_label if date_label

                  display_string
                }


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super
    AncestorListing.add_ancestors(objs, jsons)
    jsons
  end

  def validate
    validates_unique([:root_record_id, :ref_id],
                     :message => "An Archival Object Ref ID must be unique to its resource")
    map_validation_to_json_property([:root_record_id, :ref_id], :ref_id)
    super
  end

end
