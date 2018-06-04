class AccessionNamesSubreport < AbstractSubreport

  def initialize(parent_report, accession_id)
    super(parent_report)
    @accession_id = accession_id
  end

  def query
    db[:linked_agents_rlshp]
      .filter(:accession_id => @accession_id)
      .select(Sequel.as(Sequel.lit("GetAgentSortname(agent_person_id, agent_family_id, agent_corporate_entity_id)"), :name),
              Sequel.as(Sequel.lit("GetEnumValueUF(role_id)"), :function),
              Sequel.as(Sequel.lit("GetEnumValue(relator_id)"), :role))
  end

end
