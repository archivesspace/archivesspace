class AccessionNamesSubreport < AbstractReport

  def template
    "accession_names_subreport.erb"
  end

  def query
    db[:linked_agents_rlshp]
      .filter(:accession_id => @params.fetch(:accessionId))
      .select(Sequel.as(:id, :linked_agents_rlshp_id),
              Sequel.as(Sequel.lit("GetAgentSortname(agent_person_id, agent_family_id, agent_corporate_entity_id)"), :sortName),
              Sequel.as(Sequel.lit("GetEnumValueUF(role_id)"), :nameLinkFunction),
              Sequel.as(Sequel.lit("GetEnumValue(relator_id)"), :role))
  end

end
