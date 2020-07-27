class ParallelNameFamily < Sequel::Model(:parallel_name_family)
  include ASModel
  corresponds_to JSONModel(:parallel_name_family)

  include ParallelAgentNames

  def self.type_specific_hash_fields
    %w(family_name prefix qualifier)
  end

end
