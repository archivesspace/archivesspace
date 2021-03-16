class NamePerson < Sequel::Model(:name_person)
  include ASModel
  corresponds_to JSONModel(:name_person)

  include AgentNames
  include AutoGenerator

  self.one_to_many :parallel_name_person, :class => "ParallelNamePerson"

  self.def_nested_record(:the_property => :parallel_names,
                         :contains_records_of_type => :parallel_name_person,
                         :corresponding_to_association => :parallel_name_person)

  def validate
    if authorized
      validates_unique([:authorized, :agent_person_id],
                       :message => "An agent can only have one authorized name")
      map_validation_to_json_property([:authorized, :agent_person_id], :authorized)
    end

    if is_display_name
      validates_unique([:is_display_name, :agent_person_id],
                       :message => "An agent can only have one display name")
      map_validation_to_json_property([:is_display_name, :agent_person_id], :is_display_name)
    end

    super
  end


  def self.type_specific_hash_fields
    %w(primary_name title name_order prefix rest_of_name suffix fuller_form number qualifier )
  end

  auto_generate :property => :sort_name,
                :generator => proc { |json|
                  SortNameProcessor::Person.process(json)
                },
                :only_if => proc { |json| json["sort_name_auto_generate"] }
end
