class ParallelNamePerson < Sequel::Model(:parallel_name_person)
  include ASModel
  corresponds_to JSONModel(:parallel_name_person)

  include ParallelAgentNames
  include AutoGenerator

  def self.type_specific_hash_fields
    %w(primary_name title name_order prefix rest_of_name suffix fuller_form number qualifier )
  end

  auto_generate :property => :sort_name,
                :generator => proc { |json|
                  SortNameProcessor::Person.process(json)
                },
                :only_if => proc { |json| json["sort_name_auto_generate"] }
end
