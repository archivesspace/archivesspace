class ParallelNameCorporateEntity < Sequel::Model(:parallel_name_corporate_entity)
  include ASModel
  corresponds_to JSONModel(:parallel_name_corporate_entity)

  include ParallelAgentNames
  include AutoGenerator

  def self.type_specific_hash_fields
    %w(primary_name subordinate_name_1 subordinate_name_2 number qualifier)
  end

  auto_generate :property => :sort_name,
                :generator => proc { |json|
                  SortNameProcessor::CorporateEntity.process(json)
                },
                :only_if => proc { |json| json["sort_name_auto_generate"] }
end
