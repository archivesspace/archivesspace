class AgentListReport < AbstractReport

  register_report

  def query_string
    "(select
      sort_name,
      'Person' as name_type,
      source_id as name_source
    from name_person
      left outer join user
        on user.agent_record_id = name_person.agent_person_id
    where is_display_name
      and not source_id is null
      and user.id is null)
    
    union
        
    (select
      sort_name,
        'Family' as name_type,
        source_id as name_source
    from name_family
    where is_display_name
      and not source_id is null)
        
    union

    (select
      sort_name,
        'Corporate' as name_type,
        source_id as name_source
    from name_corporate_entity
    where is_display_name
      and not source_id is null)"
  end

  def fix_row(row)
    ReportUtils.get_enum_values(row, [:name_source])
  end

  def identifier_field
    :sort_name
  end

  def page_break
    false
  end
  
end
