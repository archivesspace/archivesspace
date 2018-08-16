class Composers

  #  resource:
  #  -  ead_location
  #  -  identifier
  #  -  title
  #  -  bioghist note
  #  -  scopecontent note
  #  archival object:
  #  -  component identifier
  #  -  title
  #  -  date expression
  #  -  phystech
  #  -  extent/phystech
  #  -  scopecontent note
  #  -  accessrestrict note
  #  -  userestrict note
  #  -  rights statements
  #  -  names of linked agents

  def self.get_parent(digital_object)
    if digital_object[:parent_id] != nil then
      ao = ao_dataset(digital_object[:parent_id])
      notes = ASUtils.json_parse(ao[:ao_notes] || '{}')
      out = {
            :title => ao[:ao_title],
            :bioghist => []
      }
      out[:bioghist] << extract_note(notes, 'bioghist')
      crunch(out[:bioghist])
      out
    else
      nil
    end
  end

  def self.ao_dataset(ao_id)
    DB.open do |db|
      ao = db[:archival_object]
        .left_join(:note___ao_note, :archival_object_id => :archival_object__id)
        .select(
          Sequel.as(:archival_object__title, :ao_title), 
          Sequel.as(:ao_note__notes, :ao_notes))
        .where(:archival_object__id => ao_id).first
    end
  end  
  
  def self.get_resource(component_id)
    ds = dataset(true).filter(:archival_object__component_id => component_id)
    out = {}
    ds.each do |obj|
      res_notes = ASUtils.json_parse(obj[:res_notes] || '{}')
      ao_notes = ASUtils.json_parse(obj[:ao_notes] || '{}')
      if out.empty?
        out = {
          :resource_identifier => ASUtils.json_parse(obj[:res_identifier]).compact.join('.'),
          :resource_title => obj[:res_title],
          :ead_location => obj[:ead_location],
          :resource_scopecontent => [],
          :resource_bioghist => []
        }
      end
      out[:resource_bioghist] << extract_note(res_notes, 'bioghist')
      out[:resource_scopecontent] << extract_note(res_notes, 'scopecontent')
    end
    crunch(out[:resource_bioghist])
    crunch(out[:resource_scopecontent])
    out
  end
  
  def self.detailed(component_id)
    ds = dataset(true).filter(:archival_object__component_id => component_id)
    out = {}
    ds.each do |obj|
    
      res_notes = ASUtils.json_parse(obj[:res_notes] || '{}')
      ao_notes = ASUtils.json_parse(obj[:ao_notes] || '{}')
      if out.empty?
        out = {
          :component_id => obj[:component_id],
          :title => obj[:ao_title],
          :file_uris => [],
          :parent_id => obj[:parent_id],
          :resource_identifier => ASUtils.json_parse(obj[:res_identifier]).compact.join('.'),
          :resource_title => obj[:res_title],
          :ead_location => obj[:ead_location],
          :do_identifier => obj[:do_identifier],
          :date => [],
          :extent => "",
          :phystech => [],
          :item_scopecontent => [],
          :restrictions_apply => false,
          :accessrestrict => [],
          :userestrict => [],
          :rights_statements => [],
          :agents => [],
        }
      end

      out[:date] << [obj[:date_begin], obj[:date_end]]
      out[:phystech] << extract_note(ao_notes, 'phystech')
      out[:item_scopecontent] << extract_note(ao_notes, 'scopecontent')
      out[:accessrestrict] << extract_note(ao_notes, 'accessrestrict')
      out[:userestrict] << extract_note(ao_notes, 'userestrict')

      if obj[:ao_restrictions_apply] == 1 then 
        out[:restrictions_apply] = true 
      else
        out[:restrictions_apply] = false 
      end


      if obj[:rights_active] == 1
        out[:rights_statements] << {
          :type => I18n.t("enumerations.rights_statement_rights_type.#{obj[:rights_type]}",
                          :default => obj[:rights_type]),
          :permissions => obj[:rights_permissions],
          :restrictions => obj[:rights_restrictions],
          :restriction_start_date => obj[:rights_restriction_start_date],
          :restriction_end_date => obj[:rights_restriction_end_date],
        }
      end

      if obj[:person_is_display] == 1 || obj[:corporate_entity_is_display] == 1 || obj[:family_is_display] == 1
        out[:agents] << {
          :name => obj[:person] || obj[:corporate_entity] || obj[:family],
          :role => I18n.t("enumerations.linked_agent_role.#{obj[:agent_role]}", :default => obj[:agent_role]),
          :relator => I18n.t("enumerations.linked_agent_archival_record_relators.#{obj[:agent_relator]}",
                             :default => obj[:agent_relator]),
        }
      end

      if obj[:extent_number].to_s.empty?
          out[:extent] = nil
      else  
        out[:extent] = "#{obj[:extent_number]} #{obj[:extent_value]} in #{obj[:extent_container_summary]}"
      end 
      
      out[:file_uris] << obj[:file_uri]

    end
    
    return out if out.empty?

    crunch(out[:phystech])
    crunch(out[:item_scopecontent])
    crunch(out[:accessrestrict])
    crunch(out[:userestrict])
    crunch(out[:rights_statements])
    crunch(out[:agents])
    crunch(out[:file_uris])

    out[:date] = find_date_range(out[:date])

    out
  end

  def self.summary(resource_id)
    ds = dataset.filter(:identifier => ASUtils.to_json(resource_id.split('.', 4).concat(Array.new(4)).take(4)))
    out = {}
    ds.each do |obj|
      notes = ASUtils.json_parse(obj[:ao_notes] || '{}')
      if !out[obj[:ao_id]]
        component_data = {
          :component_id => obj[:component_id],
          :title => obj[:ao_title],
          :parent_id => obj[:parent_id],
          :date => [[obj[:date_begin], obj[:date_end]]],
        }

        if obj[:extent_number].to_s.empty?
          component_data[:extent] = nil
        else  
          component_data[:extent] = "#{obj[:extent_number]} #{obj[:extent_value]} #{obj[:extent_container_summary]}"
        end 

        if extract_note(notes, 'phystech').to_s.empty? then
          component_data[:phystech] = nil
        else
          component_data[:phystech] = [extract_note(notes, 'phystech')]
        end 

        if obj[:ao_restrictions_apply] == 1 then 
          component_data[:restrictions_apply] = true 
        else
          component_data[:restrictions_apply] = false 
        end

        out[obj[:ao_id]] = component_data
      end
    end

    out.values.map do |v|
      v[:date] = find_date_range(v[:date])
      v
    end
  end


  private

  def self.find_date_range(dates)
    earliest = '9999'
    latest = '0000'
    dates.flatten.compact.each do |date|
      earliest = date if date < earliest
      latest = date if date > latest
    end
    earliest = latest = '?' if earliest == '9999'
    earliest + (earliest == latest ? '' : " -- #{latest}")
  end


  def self.crunch(a)
    a.compact!
    a.uniq!
    a.delete_if { |v| v.empty? }
  end

  def self.extract_note(notes, type)
    return '' unless notes['type'] == type
    notes['subnotes'].select { |sn| sn['publish'] }.collect { |sn| sn['content'] }.join(' ')
  end


  def self.dataset(detailed = false)
    DB.open do |db|
      ds = db[:digital_object]

      #if AppConfig[:composers_repositories] != :all
      #  ds = ds.filter(:repo_id => AppConfig[:composers_repositories])
      #end

      ds = ds.join(:instance_do_link_rlshp, :digital_object_id => :id)
        .join(:instance, :id => :instance_id)
        .join(:archival_object, :id => :archival_object_id)
        .join(:resource, :id => :root_record_id)
        .left_join(:date, :archival_object_id => :archival_object__id)
        .left_join(:note___ao_note, :archival_object_id => :archival_object__id)
        .left_join(:extent, :archival_object_id => :archival_object__id)
        .left_join(:enumeration_value, :id => :extent__extent_type_id)
        .exclude(:archival_object__component_id => nil)
        .select(Sequel.as(:resource__title, :res_title),
                Sequel.as(:digital_object__digital_object_id, :do_identifier),
                Sequel.as(:archival_object__id, :ao_id),
                Sequel.as(:archival_object__component_id, :component_id),
                Sequel.as(:archival_object__title, :ao_title),
                Sequel.as(:archival_object__restrictions_apply, :ao_restrictions_apply),
                Sequel.as(:digital_object__title, :do_title),
                Sequel.as(:date__begin, :date_begin),
                Sequel.as(:date__end, :date_end),
                Sequel.as(:ao_note__notes, :ao_notes),
                Sequel.as(:extent__physical_details, :extent_phys),
                Sequel.as(:extent__number, :extent_number),
                Sequel.as(:extent__extent_type_id, :extent_type_id),
                Sequel.as(:extent__container_summary, :extent_container_summary),
                Sequel.as(:enumeration_value__value, :extent_value),
                Sequel.as(:archival_object__parent_id, :parent_id))



      if detailed
        ds = ds.left_join(:note___res_note, :resource_id => :resource__id)
          .left_join(:rights_statement, :archival_object_id => :archival_object__id)
          .left_join(:enumeration_value___rights_statement_rights_type, :id => :rights_statement__rights_type_id)
          .left_join(:file_version, :digital_object_id => :digital_object__id)
          .left_join(:linked_agents_rlshp, :linked_agents_rlshp__archival_object_id => :archival_object__id)
          .left_join(:name_person, :name_person__agent_person_id => :linked_agents_rlshp__agent_person_id)
          .left_join(:name_corporate_entity, :name_corporate_entity__agent_corporate_entity_id => :linked_agents_rlshp__agent_corporate_entity_id)
          .left_join(:name_family, :name_family__agent_family_id => :linked_agents_rlshp__agent_family_id)
          .left_join(Sequel.as(:enumeration_value, :role), :role__id => :linked_agents_rlshp__role_id)
          .left_join(Sequel.as(:enumeration_value, :relator), :relator__id => :linked_agents_rlshp__relator_id)
          .select_append(Sequel.as(:resource__identifier, :res_identifier),
                         Sequel.as(:resource__title, :res_title),
                         Sequel.as(:resource__ead_location, :ead_location),
                         Sequel.as(:res_note__notes, :res_notes),
                         Sequel.as(:rights_statement_rights_type__value, :rights_type),
                         Sequel.as(:rights_statement__active, :rights_active),
                         Sequel.as(:rights_statement__permissions, :rights_permissions),
                         Sequel.as(:rights_statement__restrictions, :rights_restrictions),
                         Sequel.as(:rights_statement__restriction_start_date, :rights_restriction_start_date),
                         Sequel.as(:rights_statement__restriction_end_date, :rights_restriction_end_date),
                         Sequel.as(:file_version__file_uri, :file_uri),
                         Sequel.as(:name_person__sort_name, :person),
                         Sequel.as(:name_corporate_entity__sort_name, :corporate_entity),
                         Sequel.as(:name_family__sort_name, :family),
                         Sequel.as(:name_person__is_display_name, :person_is_display),
                         Sequel.as(:name_corporate_entity__is_display_name, :corporate_entity_is_display),
                         Sequel.as(:name_family__is_display_name, :family_is_display),
                         Sequel.as(:relator__value, :agent_relator),
                         Sequel.as(:role__value, :agent_role))

      end

      ds
    end
  end
end

