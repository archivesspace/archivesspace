class ParallelNameCorporateEntity < Sequel::Model(:parallel_name_corporate_entity)
  include ASModel
  corresponds_to JSONModel(:parallel_name_corporate_entity)

  include ParallelAgentNames

  def self.type_specific_hash_fields
    %w(primary_name subordinate_name_1 subordinate_name_2 number qualifier)
  end

end
