class DigitalObjectComponent < Sequel::Model(:digital_object_component)
  include ASModel
  corresponds_to JSONModel(:digital_object_component)

  include Subjects
  include Extents
  include LangMaterials
  include Dates
  include ExternalDocuments
  include Agents
  include TreeNodes
  include AutoGenerator
  include Notes
  include RightsStatements
  include ExternalIDs
  include FileVersions
  include ComponentsAddChildren
  include Events
  include Publishable
  include TouchRecords

  enable_suppression

  agent_role_enum("linked_agent_role")
  agent_relator_enum("linked_agent_archival_record_relators")

  tree_record_types :digital_object, :digital_object_component

  set_model_scope :repository


  auto_generate :property => :display_string,
                :generator => proc { |json|
                  DigitalObjectComponent.produce_display_string(json)
                }

  auto_generate :property => :slug,
                :generator => proc { |json|
                  if AppConfig[:use_human_readable_urls]
                    if json["is_slug_auto"]
                      AppConfig[:auto_generate_slugs_with_id] ?
                        SlugHelpers.id_based_slug_for(json, DigitalObjectComponent) :
                        SlugHelpers.name_based_slug_for(json, DigitalObjectComponent)
                    else
                      json["slug"]
                    end
                  end
                }


  def self.produce_display_string(json)
    display_string = json['title'] || json['label'] || nil

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

  def validate
    validates_unique([:root_record_id, :component_id],
                     :message => "A Digital Object Component ID must be unique to its Digital Object")
    map_validation_to_json_property([:root_record_id, :component_id], :component_id)
    super
  end

  def self.touch_records(obj)
    [{ type: DigitalObject, ids: [obj.root_record_id] }]
  end

end
