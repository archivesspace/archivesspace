
def clean_slug(slug)
  if slug
    # remove all non-ASCII chars
    encoding_options = {
      :invalid           => :replace,
      :undef             => :replace,
      :replace           => '',
      :universal_newline => true
    }

    slug = slug.encode(Encoding.find('ASCII'), encoding_options)

    # if the slug contains a slash, completely zero it out.
    # this is intended to revert an entity to use the URI if the ID or name the slug was generated from is a URL.
    slug = "" if slug =~ /\//

    # downcase everything to simplify case sensitivity issues
    slug = slug.downcase

    # replace spaces with underscores
    slug = slug.gsub(" ", "_")

    # remove double hypens
    slug = slug.gsub("--", "")

    # remove single quotes
    slug = slug.gsub("'", "")

    # remove URL-reserved chars
    slug = slug.gsub(/[&;?$<>#%{}|\\^~\[\]`\/\*\(\)@=:+,!.]/, "")

    # enforce length limit of 50 chars
    slug = slug.slice(0, 50)

    # replace any multiple underscores with a single underscore
    slug = slug.gsub(/_[_]+/, "_")

    # remove any leading or trailing underscores
    slug = slug.gsub(/^_/, "").gsub(/_$/, "")

    # if slug is numeric, add a leading '__'
    # this is necessary, because numerical slugs will be interpreted as an id by the controller
    if slug.match(/^(\d)+$/)
      slug = slug.prepend("__")
    end

  else
    slug = ""
  end

  return slug.parameterize
end


def format_identifier_separate(id0, id1, id2, id3)
  slug = id0
  slug += "-#{id1}" if id1
  slug += "-#{id2}" if id2
  slug += "-#{id3}" if id3

  return clean_slug(slug)
end

# for identifiers that look like this: "[\"987QCXI\",\"WPDX965\",\"244A528553S\",\"187RBJQ\"]"
def format_identifier_array(array)
  return "" if array.nil? || array.empty?

  joined = array.gsub("[", "")
                .gsub!("]", "")
                .gsub!('"', '')

  joined = joined.split(",").join("-")
  joined = joined.gsub("-null-null-null", "")

  return clean_slug(joined)
end

def get_generated_name_for_agent(agent)
  result = ""
  case agent.class.to_s
  when "AgentPerson"
    name_record = NamePerson.find(:agent_person_id => agent.id)

    if name_record[:name_order] === "inverted"
      result << name_record[:primary_name] if name_record[:primary_name]
      result << "_" + name_record[:rest_of_name] if name_record[:rest_of_name]
    elsif name_record[:name_order] === "direct"
      result << name_record[:rest_of_name] if name_record[:rest_of_name]
      result << "_" + name_record[:primary_name] if name_record[:primary_name]
    else
      result << name_record[:primary_name]
    end

  when "AgentFamily"
    name_record = NameFamily.find(:agent_family_id => agent.id)

    result = name_record[:family_name] if name_record[:family_name]

  when "AgentCorporateEntity"
    name_record = NameCorporateEntity.find(:agent_corporate_entity_id => agent.id)

    result << name_record[:primary_name] if name_record[:primary_name]
    result << "_" + name_record[:subordinate_name_1] if name_record[:subordinate_name_1]
    result << "_" + name_record[:subordinate_name_2] if name_record[:subordinate_name_2]

  when "AgentSoftware"
    name_record = NameSoftware.find(:agent_software_id => agent.id)
    result = name_record[:software_name] if name_record[:software_name]
  end

  result
end

def resource_with_slug(slug, auto = false)
  Resource.create_from_json(build(:json_resource_nohtml, :is_slug_auto => auto, :slug => slug))
end
