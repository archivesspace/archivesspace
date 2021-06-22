class NameCorporateEntity < Sequel::Model(:name_corporate_entity)
  include ASModel
  corresponds_to JSONModel(:name_corporate_entity)

  include AgentNames
  include AutoGenerator
  include Representative

  self.one_to_many :parallel_name_corporate_entity, :class => "ParallelNameCorporateEntity"

  self.def_nested_record(:the_property => :parallel_names,
                         :contains_records_of_type => :parallel_name_corporate_entity,
                         :corresponding_to_association => :parallel_name_corporate_entity)

  def representative_for_types
    { authorized: [:agent_corporate_entity], is_display_name: [:agent_corporate_entity] }
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
