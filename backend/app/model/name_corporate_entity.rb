class NameCorporateEntity < Sequel::Model(:name_corporate_entity)
  include ASModel
  corresponds_to JSONModel(:name_corporate_entity)

  include AgentNames
  include AutoGenerator

  self.one_to_many :parallel_name_corporate_entity, :class => "ParallelNameCorporateEntity"

  self.def_nested_record(:the_property => :parallel_names,
                         :contains_records_of_type => :parallel_name_corporate_entity,
                         :corresponding_to_association => :parallel_name_corporate_entity)

  def validate
    if authorized
      validates_unique([:authorized, :agent_corporate_entity_id],
                       :message => "An agent can only have one authorized name")
      map_validation_to_json_property([:authorized, :agent_corporate_entity_id], :authorized)
    end

    if is_display_name
      validates_unique([:is_display_name, :agent_corporate_entity_id],
                       :message => "An agent can only have one display name")
      map_validation_to_json_property([:is_display_name, :agent_corporate_entity_id], :is_display_name)
    end

    super
  end


  def self.type_specific_hash_fields
    %w(primary_name subordinate_name_1 subordinate_name_2 number qualifier)
  end

  auto_generate :property => :sort_name,
                :generator => proc { |json|
                  SortNameProcessor::CorporateEntity.process(json)
                },
                :only_if => proc { |json| json["sort_name_auto_generate"] }
end
