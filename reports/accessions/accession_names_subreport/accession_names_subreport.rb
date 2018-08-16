class AccessionNamesSubreport < AbstractSubreport

  def initialize(parent_report, accession_id)
    super(parent_report)
    @accession_id = accession_id
  end

  def query_string
    "select
      ifnull(ifnull(ifnull(name_person.sort_name, name_family.sort_name),
        name_corporate_entity.sort_name), 'Unknown') as name,
      role_id as function,
      relator_id as role
    from linked_agents_rlshp
      left outer join name_person
        on name_person.agent_person_id = linked_agents_rlshp.agent_person_id
      left outer join name_family
        on name_family.agent_family_id = linked_agents_rlshp.agent_family_id
      left outer join name_corporate_entity
        on name_corporate_entity.agent_corporate_entity_id = 
        linked_agents_rlshp.agent_corporate_entity_id
    where accession_id = #{db.literal(@accession_id)}"
  end

  def fix_row(row)
    ReportUtils.get_enum_values(row, [:function, :role])
  end

end
