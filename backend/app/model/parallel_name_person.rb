class ParallelNamePerson < Sequel::Model(:parallel_name_person)
  include ASModel
  corresponds_to JSONModel(:parallel_name_person)

  include ParallelAgentNames

  def self.type_specific_hash_fields
    %w(primary_name title name_order prefix rest_of_name suffix fuller_form number qualifier )
  end

end
