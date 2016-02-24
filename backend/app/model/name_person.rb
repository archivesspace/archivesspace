class NamePerson < Sequel::Model(:name_person)
  include ASModel
  corresponds_to JSONModel(:name_person)

  include AgentNames
  include AutoGenerator

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
                :generator => proc  { |json|
                  result = ""

                  if json["name_order"] === "inverted"
                    result << json["primary_name"] if json["primary_name"]
                    result << ", #{json["rest_of_name"]}" if json["rest_of_name"]
                  elsif json["name_order"] === "direct"
                    result << json["rest_of_name"] if json["rest_of_name"]
                    result << " #{json["primary_name"]}" if json["primary_name"]
                  else
                    result << json["primary_name"]
                  end

                  result << ", #{json["prefix"]}" if json["prefix"]
                  result << ", #{json["suffix"]}" if json["suffix"]
                  result << ", #{json["title"]}" if json["title"]
                  result << ", #{json["number"]}" if json["number"]
                  result << " (#{json["fuller_form"]})" if json["fuller_form"]
                  result << ", #{json["dates"]}" if json["dates"]
                  result << " (#{json["qualifier"]})" if json["qualifier"]

                  result.lstrip!    
                  result.length > 255 ? result[0..254] : result
                },
                :only_if => proc { |json| json["sort_name_auto_generate"] }

end
