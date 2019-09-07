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
                  display_string = json['title'] || json['label'] || nil

                  date_label = json.has_key?('dates') && json['dates'].length > 0 ?
                                lambda {|date|
                                  if date['expression']
                                    date['expression']
                                  elsif date['begin'] and date['end']
                                    "#{date['begin']} - #{date['end']}"
                                  else
                                    date['begin']
                                  end
                                }.call(json['dates'].first) : nil

                  "#{[display_string, date_label].compact.join(", ")}"
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
