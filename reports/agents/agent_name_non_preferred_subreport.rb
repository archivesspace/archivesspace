class AgentNameNonPreferredSubreport < AbstractReport

  def template
    'agent_name_non_preferred_subreport.erb'
  end

  def query
    name_type =  @params.fetch(:nameType)

    if name_type == 'Person'
      db[:name_person]
        .filter(:name_person__agent_person_id => @params.fetch(:agentId))
        .filter(Sequel.~(:name_person__source_id => nil))
        .filter(:name_person__is_display_name => nil)
        .select(Sequel.as(:agent_person_id, :agentId),
                Sequel.as(:sort_name, :sortName),
                Sequel.as('Person', :nameType),
                Sequel.as(Sequel.lit('GetEnumValueUF(name_person.source_id)'), :nameSource))
    elsif name_type == 'Family'
      db[:name_family]
        .filter(:name_family__is_display_name => nil)
        .filter(Sequel.~(:name_family__source_id => nil))
        .filter(:name_family__agent_family_id => @params.fetch(:agentId))
        .select(Sequel.as(:agent_family_id, :agentId),
                Sequel.as(:sort_name, :sortName),
                Sequel.as('Family', :nameType),
                Sequel.as(Sequel.lit('GetEnumValueUF(name_family.source_id)'), :nameSource))
    elsif name_type == 'Corporate'
      db[:name_corporate_entity]
        .filter(:name_corporate_entity__is_display_name => nil)
        .filter(Sequel.~(:name_corporate_entity__source_id => nil))
        .filter(:name_corporate_entity__agent_corporate_entity_id => @params.fetch(:agentId))
        .select(Sequel.as(:agent_corporate_entity_id, :agentId),
                Sequel.as(:sort_name, :sortName),
                Sequel.as('Corporate', :nameType),
                Sequel.as(Sequel.lit('GetEnumValueUF(name_corporate_entity.source_id)'), :nameSource))
    else
      raise "nameType not recognised: #{name_type}"
    end
  end
end
