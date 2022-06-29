class ParallelNameSoftware < Sequel::Model(:parallel_name_software)
  include ASModel
  corresponds_to JSONModel(:parallel_name_software)

  include ParallelAgentNames
  include AutoGenerator

  def self.type_specific_hash_fields
    %w(software_name version manufacturer qualifier)
  end

  auto_generate :property => :sort_name,
                :generator => proc { |json|
                  SortNameProcessor::Software.process(json)
                },
                :only_if => proc { |json| json["sort_name_auto_generate"] }
end
