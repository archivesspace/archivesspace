class NameSoftware < Sequel::Model(:name_software)
  include ASModel
  corresponds_to JSONModel(:name_software)

  include AgentNames
  include AutoGenerator

  self.one_to_many :parallel_name_software, :class => "ParallelNameSoftware"

  self.def_nested_record(:the_property => :parallel_names,
                         :contains_records_of_type => :parallel_name_software,
                         :corresponding_to_association => :parallel_name_software)

  def validate
    if authorized
      validates_unique([:authorized, :agent_software_id],
                       :message => "An agent can only have one authorized name")
      map_validation_to_json_property([:authorized, :agent_software_id], :authorized)
    end

    if is_display_name
      validates_unique([:is_display_name, :agent_software_id],
                       :message => "An agent can only have one display name")
      map_validation_to_json_property([:is_display_name, :agent_software_id], :is_display_name)
    end


    super
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
