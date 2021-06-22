class NameSoftware < Sequel::Model(:name_software)
  include ASModel
  corresponds_to JSONModel(:name_software)

  include AgentNames
  include AutoGenerator
  include Representative

  self.one_to_many :parallel_name_software, :class => "ParallelNameSoftware"

  self.def_nested_record(:the_property => :parallel_names,
                         :contains_records_of_type => :parallel_name_software,
                         :corresponding_to_association => :parallel_name_software)

  def representative_for_types
    { authorized: [:agent_software], is_display_name: [:agent_software] }
  end

  def self.type_specific_hash_fields
    %w(software_name version manufacturer qualifier)
  end

  auto_generate :property => :sort_name,
                :generator => proc { |json|
                  SortNameProcessor::Software.process(json)
                },
                :only_if => proc { |json| json["sort_name_auto_generate"] }
end
