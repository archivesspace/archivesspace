class ParallelNameSoftware < Sequel::Model(:parallel_name_software)
  include ASModel
  corresponds_to JSONModel(:parallel_name_software)

  include ParallelAgentNames

  def self.type_specific_hash_fields
    %w(software_name version manufacturer qualifier)
  end

end
