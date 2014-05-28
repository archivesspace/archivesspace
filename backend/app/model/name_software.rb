class NameSoftware < Sequel::Model(:name_software)
  include ASModel
  corresponds_to JSONModel(:name_software)

  include AgentNames
  include AutoGenerator

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
                :generator => proc  { |json|
                  result = ""

                  result << "#{json["manufacturer"]} " if json["manufacturer"]
                  result << "#{json["software_name"]}" if json["software_name"]
                  result << " #{json["version"]}" if json["version"]
                  result << " (#{json["qualifier"]})" if json["qualifier"]

                  result.length > 255 ? result[0..254] : result
                },
                :only_if => proc { |json| json["sort_name_auto_generate"] }

end
