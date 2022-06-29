class NameFamily < Sequel::Model(:name_family)
  include ASModel
  corresponds_to JSONModel(:name_family)

  include AgentNames
  include AutoGenerator
  include Representative

  self.one_to_many :parallel_name_family, :class => "ParallelNameFamily"

  self.def_nested_record(:the_property => :parallel_names,
                         :contains_records_of_type => :parallel_name_family,
                         :corresponding_to_association => :parallel_name_family)

  def representative_for_types
    { authorized: [:agent_family], is_display_name: [:agent_family] }
  end

  def self.type_specific_hash_fields
    %w(family_name prefix qualifier)
  end

  auto_generate :property => :sort_name,
                :generator => proc { |json|
                  SortNameProcessor::Family.process(json)
                },
                :only_if => proc { |json| json["sort_name_auto_generate"] }
end
