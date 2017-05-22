class AgentListReport < AbstractReport

  register_report

  def template
    'generic_listing.erb'
  end

  def headers
    ['sortName', 'nameType', 'nameSource']
  end

  def query
    people = db[:name_person]
              .filter(:name_person__is_display_name => 1)
              .filter(Sequel.~(:name_person__source_id => nil))
              .filter(db[:user]
                        .filter(:user__agent_record_id => :name_person__agent_person_id)
                        .select(:agent_record_id) => nil)
              .select(Sequel.as(:agent_person_id, :agentId),
                      Sequel.as(:sort_name, :sortName),
                      Sequel.as('Person', :nameType),
                      Sequel.as(Sequel.lit('GetEnumValueUF(name_person.source_id)'), :nameSource))

    families = db[:name_family]
                .filter(:name_family__is_display_name => 1)
                .filter(Sequel.~(:name_family__source_id => nil))
                .select(Sequel.as(:agent_family_id, :agentId),
                        Sequel.as(:sort_name, :sortName),
                        Sequel.as('Family', :nameType),
                        Sequel.as(Sequel.lit('GetEnumValueUF(name_family.source_id)'), :nameSource))

    corporate = db[:name_corporate_entity]
                 .filter(:name_corporate_entity__is_display_name => 1)
                 .filter(Sequel.~(:name_corporate_entity__source_id => nil))
                 .select(Sequel.as(:agent_corporate_entity_id, :agentId),
                         Sequel.as(:sort_name, :sortName),
                         Sequel.as('Corporate', :nameType),
                         Sequel.as(Sequel.lit('GetEnumValueUF(name_corporate_entity.source_id)'), :nameSource))

    people
      .union(families)
      .union(corporate)
  end
end
