class NameFamily < Sequel::Model(:name_family)
  include ASModel
  corresponds_to JSONModel(:name_family)

  include AgentNames
  include AutoGenerator

  def validate
    if authorized
      validates_unique([:authorized, :agent_family_id],
                       :message => "An agent can only have one authorized name")
      map_validation_to_json_property([:authorized, :agent_family_id], :authorized)
    end

    if is_display_name
      validates_unique([:is_display_name, :agent_family_id],
                       :message => "An agent can only have one display name")
      map_validation_to_json_property([:is_display_name, :agent_family_id], :is_display_name)
    end


    super
  end


  def self.type_specific_hash_fields
    %w(family_name prefix qualifier)
  end


  auto_generate :property => :sort_name,
                :generator => proc  { |json|
                  result = ""

                  result << json["family_name"] if json["family_name"]
                  result << ", #{json["prefix"]}" if json["prefix"]
                  result << ", #{json["dates"]}" if json["dates"]
                  result << " (#{json["qualifier"]})" if json["qualifier"]

                  result.length > 255 ? result[0..254] : result
                },
                :only_if => proc { |json| json["sort_name_auto_generate"] }
end
