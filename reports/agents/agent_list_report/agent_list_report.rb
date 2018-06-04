class AgentListReport < AbstractReport

  register_report

  def query
    people = db[:name_person]
              .filter(:name_person__is_display_name => 1)
              .filter(Sequel.~(:name_person__source_id => nil))
              .filter(db[:user]
                        .filter(:user__agent_record_id => :name_person__agent_person_id)
                        .select(:agent_record_id) => nil)
              .select(Sequel.as(:sort_name, :sort_name),
                      Sequel.as('Person', :name_type),
                      Sequel.as(Sequel.lit('GetEnumValueUF(name_person.source_id)'), :name_source))

    families = db[:name_family]
                .filter(:name_family__is_display_name => 1)
                .filter(Sequel.~(:name_family__source_id => nil))
                .select(Sequel.as(:sort_name, :sort_name),
                        Sequel.as('Family', :name_type),
                        Sequel.as(Sequel.lit('GetEnumValueUF(name_family.source_id)'), :name_source))

    corporate = db[:name_corporate_entity]
                 .filter(:name_corporate_entity__is_display_name => 1)
                 .filter(Sequel.~(:name_corporate_entity__source_id => nil))
                 .select(Sequel.as(:sort_name, :sort_name),
                         Sequel.as('Corporate', :name_type),
                         Sequel.as(Sequel.lit('GetEnumValueUF(name_corporate_entity.source_id)'), :name_source))

    people
      .union(families)
      .union(corporate)
  end

  def identifier_field
    :sort_name
  end
end
