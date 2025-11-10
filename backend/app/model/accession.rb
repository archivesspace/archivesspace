require 'multiple_titles_helper'
require_relative 'mixins/mixed_content_validatable'

class Accession < Sequel::Model(:accession)
  include ASModel
  corresponds_to JSONModel(:accession)

  include Identifiers
  include Extents
  include LangMaterials
  include Subjects
  include Dates
  include ExternalDocuments
  include RightsStatements
  include Deaccessions
  include Agents
  include DirectionalRelationships
  include ExternalIDs
  include CollectionManagements
  include MetadataRights
  include Instances
  include UserDefineds
  include Classifications
  include AutoGenerator
  include Transferable
  include Events
  include Publishable
  include ReindexTopContainers
  include Assessments::LinkedRecord
  include RepresentativeFileVersion
  include Titles
  include MixedContentValidatable

  agent_role_enum("linked_agent_role")
  agent_relator_enum("linked_agent_archival_record_relators")

  enable_suppression
  set_model_scope :repository


  define_relationship(:name => :spawned,
                      :json_property => 'related_resources',
                      :contains_references_to_types => proc {[Resource]})

  define_relationship(:name => :accession_component_links,
                      :json_property => 'component_links',
                      :contains_references_to_types => proc {[ArchivalObject]},
                      :is_array => true)


  define_directional_relationship(:name => :related_accession,
                                  :json_property => 'related_accessions',
                                  :contains_references_to_types => proc {[Accession]},
                                  :class_callback => proc {|clz|
                                    clz.instance_eval do
                                      include DynamicEnums
                                      uses_enums({
                                                   :property => 'relator',
                                                   :uses_enum => ['accession_parts_relator', 'accession_sibling_relator']
                                                 },
                                                 {
                                                   :property => 'relator_type',
                                                   :uses_enum => ['accession_parts_relator_type', 'accession_sibling_relator_type']
                                                 })
                                    end
                                  })


  auto_generate :property => :display_string,
                :generator => lambda { |json|
                  locale = Preference.user_global_defaults['locale'] || Preference.global_defaults['locale']
                  primary_title = MultipleTitlesHelper.determine_primary_title(json['titles'], locale)
                  return primary_title if primary_title

                  %w(id_0 id_1 id_2 id_3).map {|p| json[p]}.compact.join("-")
                }

  auto_generate :property => :slug,
                :generator => proc { |json|
                  if AppConfig[:use_human_readable_urls]
                    if json["is_slug_auto"]
                      AppConfig[:auto_generate_slugs_with_id] ?
                        SlugHelpers.id_based_slug_for(json, Accession) :
                        SlugHelpers.name_based_slug_for(json, Accession)
                    else
                      json["slug"]
                    end
                  end
                }

  def validate
    validate_mixed_content_field()
    super
  end
end
