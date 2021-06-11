class NamePerson < Sequel::Model(:name_person)
  include ASModel
  corresponds_to JSONModel(:name_person)

  include AgentNames
  include AutoGenerator
  include Representative

  self.one_to_many :parallel_name_person, :class => "ParallelNamePerson"

  self.def_nested_record(:the_property => :parallel_names,
                         :contains_records_of_type => :parallel_name_person,
                         :corresponding_to_association => :parallel_name_person)

  def representative_for_types
    { authorized: [:agent_person], is_display_name: [:agent_person] }
  end

  def self.type_specific_hash_fields
    %w(primary_name title name_order prefix rest_of_name suffix fuller_form number qualifier )
  end

  auto_generate :property => :sort_name,
                :generator => proc { |json|
                  SortNameProcessor::Person.process(json)
                },
                :only_if => proc { |json| json["sort_name_auto_generate"] }
end
