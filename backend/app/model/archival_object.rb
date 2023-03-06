require 'securerandom'
require_relative 'ancestor_listing'


class ArchivalObject < Sequel::Model(:archival_object)
  include ASModel
  corresponds_to JSONModel(:archival_object)

  include Subjects
  include Extents
  include LangMaterials
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
  include RightsRestrictionNotes
  include RepresentativeFileVersion
  include Assessments::LinkedRecord
  include TouchRecords
  include Arks

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
                :generator => proc { |json| ArchivalObject.produce_display_string(json) }


  auto_generate :property => :slug,
                :generator => proc { |json|
                  if AppConfig[:use_human_readable_urls]
                    if json["is_slug_auto"]
                      AppConfig[:auto_generate_slugs_with_id] ?
                        SlugHelpers.id_based_slug_for(json, ArchivalObject) :
                        SlugHelpers.name_based_slug_for(json, ArchivalObject)
                    else
                      json["slug"]
                    end
                  end
                }

  define_relationship(:name => :accession_component_links,
                      :json_property => 'accession_links',
                      :contains_references_to_types => proc {[Accession]},
                      :is_array => true)

  def self.produce_display_string(json)
    display_string = json['title'] || ""

    date_label = json.has_key?('dates') && json['dates'].length > 0 ?
                   json['dates'].map do |date|
                     if date['expression']
                       date['date_type'] == 'bulk' ? "#{I18n.t("date_type_bulk.bulk")}: #{date['expression']}" : date['expression']
                     elsif date['begin'] and date['end']
                       date['date_type'] == 'bulk' ? "#{I18n.t("date_type_bulk.bulk")}: #{date['begin']} - #{date['end']}" : "#{date['begin']} - #{date['end']}"
                     else
                       date['date_type'] == 'bulk' ? "#{I18n.t("date_type_bulk.bulk")}: #{date['begin']}" : date['begin']
                     end
                   end.join(', ') : false

    display_string += ", " if json['title'] && date_label
    display_string += date_label if date_label

    display_string
  end

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

  # For archival objects, we want the level returned in our ordered_record
  # response
  def self.ordered_record_properties(record_ids)
    result = super.clone

    self.filter(:id => record_ids).select(:id, :level_id, :other_level).each do |row|
      id = row[:id]
      level = if row[:other_level]
                row[:other_level]
              else
                BackendEnumSource.value_for_id('archival_record_level', row[:level_id])
              end

      result[id] ||= {}
      result[id][:level] = level
    end

    result
  end

  def self.touch_records(obj)
    [{ type: Resource, ids: [obj.root_record_id] }]
  end

  def publish!(setting = true)
    super(setting)
    Resource.update_mtime_for_ids([self.root_record_id])
  end

end
