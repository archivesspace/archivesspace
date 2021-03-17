class ParallelNameFamily < Sequel::Model(:parallel_name_family)
  include ASModel
  corresponds_to JSONModel(:parallel_name_family)

  include ParallelAgentNames
  include AutoGenerator

  def self.type_specific_hash_fields
    %w(family_name prefix qualifier)
  end

  auto_generate :property => :sort_name,
                :generator => proc { |json|
                  SortNameProcessor::Family.process(json)
                },
                :only_if => proc { |json| json["sort_name_auto_generate"] }
end
