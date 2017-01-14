class ResourceNamesAsCreatorsSubreport < AbstractReport

  def template
    'resource_names_as_creators_subreport.erb'
  end

  # FIXME I81n relator
  def query
    resource_id = @params.fetch(:resourceId)
    all_children_ids = db[:archival_object]
                        .filter(:root_record_id => resource_id)
                        .select(:id)

    creator_id = db[:enumeration_value]
                  .filter(:enumeration_id => db[:enumeration].filter(:name => 'linked_agent_role').select(:id))
                  .filter(:value => 'creator')
                  .select(:id)
                  

    dataset = db[:linked_agents_rlshp]
              .filter(:role_id => creator_id)
              .filter {
                 Sequel.|({:resource_id => resource_id},
                           :archival_object_id => all_children_ids)
              }
              .select(Sequel.as(Sequel.lit("GetAgentSortname(agent_person_id, agent_family_id, agent_corporate_entity_id)"), :sortName),
                      Sequel.as(Sequel.lit("GetEnumValue(relator_id)"), :relator))

    db.from(dataset).group(:sortName)
  end

end
