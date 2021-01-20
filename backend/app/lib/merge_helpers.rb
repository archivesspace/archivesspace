module MergeHelpers
	def parse_references(request)
    target = JSONModel.parse_reference(request.target['ref'])
    victims = request.victims.map {|victim| JSONModel.parse_reference(victim['ref'])}

    [target, victims]
  end

  def check_repository(target, victims, repo_id)
    repo_uri = JSONModel(:repository).uri_for(repo_id)

    if ([target] + victims).any? {|r| r[:repository] != repo_uri}
      raise BadParamsException.new(:merge_request => ["All records to merge must be in the repository specified"])
    end
  end


  def ensure_type(target, victims, type)
    if (victims.map {|r| r[:type]} + [target[:type]]).any? {|t| t != type}
      raise BadParamsException.new(:merge_request => ["This merge request can only merge #{type} records"])
    end
  end

  def parse_selections(selections, path=[], all_values={})
    selections.each_pair do |k, v|
      path << k

      position = selections['position']

      case v
        when String
          if v === "REPLACE"
            all_values.merge!({"#{path.join(".")}.#{position}" => "#{v}"})
            path.pop
          else
            path.pop
            next
          end
        when Hash then parse_selections(v, path, all_values)
        when Array then v.each_with_index do |v2, index|
          path << index
          parse_selections(v2, path, all_values)
        end
        path.pop
        else
          path.pop
          next
      end
    end
    path.pop

    return all_values
  end

  # when merging, set the agent id foreign key (e.g, agent_person_id, agent_family_id...) from the victim to the target
  def set_agent_id(target_id, subrecord)
    if subrecord['agent_person_id']
      subrecord['agent_person_id'] = target_id

    elsif subrecord['agent_family_id']
      subrecord['agent_family_id'] = target_id

    elsif subrecord['agent_corporate_entity_id']
      subrecord['agent_corporate_entity_id'] = target_id

    elsif subrecord['agent_software_id']
      subrecord['agent_software_id'] = target_id

    # this section updates related_agents ids
    elsif subrecord['agent_person_id_0']
      subrecord['agent_person_id_0'] = target_id
      
    elsif subrecord['agent_family_id_0']
      subrecord['agent_family_id_0'] = target_id

    elsif subrecord['agent_corporate_entity_id_0']
      subrecord['agent_corporate_entity_id_0'] = target_id
    end
    
  end

  def merge_details(target, victim, selections, params)
    target[:linked_events] = []
    victim[:linked_events] = []

    subrec_add_replacements = []
    field_replacements = []
    victim_values = {}
    values_from_params = params[:merge_request_detail].selections

    # this code breaks selections into arrays like this:
    # ["agent_record_identifiers", 1, "append", 2] // add entire subrec, record is in position 2
    # ["agent_record_controls", 0, "replace", 1] // replace entire subrec, record is in position 1
    # ["agent_record_controls", 0, "maintenance_status", 1] // replace field, record is in position 1
    # ["agent_record_controls", 0, "publication_status", 0] // replace field, record is in position 0 
    # ["agent_record_controls", 0, "maintenance_agency", 3]
    # and then creates data structures for the subrecords to append, replace entirely, and replace by field. record in in position 3
    selections.each_key do |key|
      path = key.split(".")
      path_fix = []
      path.each do |part|
        if part.length === 1
          part = part.to_i
        elsif (part.length === 2) and (part.start_with?('1'))
          part = part.to_i
        end
        path_fix.push(part)
      end

      subrec_name = path_fix[0]
      victim_values[subrec_name] = values_from_params[subrec_name]

      # subrec level add/replace 
      if path_fix[2] == "append" || path_fix[2] == "replace"
        subrec_add_replacements.push(path_fix)

      # field level replace
      else
        field_replacements.push(path_fix)
      end
    end

    merge_details_subrec(target, victim, subrec_add_replacements, victim_values)
    merge_details_replace_field(target, victim, field_replacements, victim_values)

    target['title'] = target['names'][0]['sort_name']
    target

  # This code can be hard to debug when things go wrong, especially since details of problems aren't bubbled up to the frontend where the user is.
  # So we'll make sure to catch problems and dump out any info we know.
  rescue => e
    STDERR.puts "EXCEPTION!"
    STDERR.puts e.inspect
    STDERR.puts e.backtrace
  end

  # do field replace operations
  def merge_details_replace_field(target, victim, selections, values)
    selections.each do |path_fix|
      subrec_name = path_fix[0]
      # this is the index of the order the user arranged the subrecs in the form, not the order of the subrecords in the DB.
      ind         = path_fix[1]
      field       = path_fix[2]
      position    = path_fix[3]

      subrec_index = find_subrec_index_in_victim(victim, subrec_name, position)

      target[subrec_name][ind][field] = victim[subrec_name][subrec_index][field]
    end
  end


  # do subrec replace operations
  def merge_details_subrec(target, victim, selections, values)
    selections.each do |path_fix|
      subrec_name = path_fix[0]
      # this is the index of the order the user arranged the subrecs in the form, not the order of the subrecords in the DB.
      ind         = path_fix[1] 
      mode        = path_fix[2]
      position    = path_fix[3]

      subrec_index = find_subrec_index_in_victim(victim, subrec_name, position)

      replacer = victim[subrec_name][subrec_index]

      # notes are a special case because of the way they store JSON in a db field. So Reordering is not supported, and we can assume the position in the merge request is the position in the victims notes subrecord JSON.
      if subrec_name == "notes"
        replacer = victim["notes"][ind]
        to_append = process_subrecord_for_merge(target, replacer, subrec_name, mode, ind)

        target[subrec_name].push(process_subrecord_for_merge(target, replacer, subrec_name, mode, ind))
      elsif mode == "replace"
        target[subrec_name][ind] = process_subrecord_for_merge(target, replacer, subrec_name, mode, ind)
      elsif mode == "append"
        target[subrec_name].push(process_subrecord_for_merge(target, replacer, subrec_name, mode, ind))
      end

    end
  end

  # we don't know how the user reordered the subrecords on the merge form,
  # so find the index with the right data given the position of the right thing to replace/add by searching for it.
  def find_subrec_index_in_victim(victim, subrec_name, position)
    ind = nil
    victim[subrec_name].each_with_index do |subrec, i|
      if i == position
        ind = i
        break
      end
    end

    return ind ? ind : -1
  end

  # before we can merge a subrecord, we need to update the IDs, tweak things to prevent validation issues, etc
  def process_subrecord_for_merge(target, subrecord, jsonmodel_type, mode, ind)
    target_id = target['id']

    if jsonmodel_type == 'names'
      # an agent name can only have one authorized or display name.
      # make sure the name being merged in doesn't conflict with this

      # if appending, always disable fields that validate across a set. If replacing, always keep values from target 
      if mode == "append"
        subrecord['authorized']      = false
        subrecord['is_display_name'] = false
      elsif mode == "replace"
        subrecord['authorized']      = target['names'][ind]['authorized']
        subrecord['is_display_name'] = target['names'][ind]['is_display_name']
      end

    elsif jsonmodel_type == 'agent_record_identifiers'
      # same with agent_record_identifiers being marked as primary, we can only have one

      if mode == "append"
        subrecord['primary_identifier'] = false

      elsif mode == "replace"
        subrecord['primary_identifier'] = target['agent_record_identifiers'][ind]['primary_identifier']
      end
    end

    set_agent_id(target_id, subrecord)

    return subrecord
  end


  # NOTE: this code is a duplicate of the auto_generate code for creating sort name
  # in the name_person, name_family, name_software, name_corporate_entity models
  # Consider refactoring when continued work done on the agents model enhancements
  def preview_sort_name(target)
    result = ""

    case target['jsonmodel_type']
    when 'name_person'
      if target["name_order"] === "inverted"
        result << target["primary_name"] if target["primary_name"]
        result << ", #{target["rest_of_name"]}" if target["rest_of_name"]
      elsif target["name_order"] === "direct"
        result << target["rest_of_name"] if target["rest_of_name"]
        result << " #{target["primary_name"]}" if target["primary_name"]
      else
        result << target["primary_name"] if target["primary_name"]
      end

      result << ", #{target["prefix"]}" if target["prefix"]
      result << ", #{target["suffix"]}" if target["suffix"]
      result << ", #{target["title"]}" if target["title"]
      result << ", #{target["number"]}" if target["number"]
      result << " (#{target["fuller_form"]})" if target["fuller_form"]
      result << ", #{target["dates"]}" if target["dates"]
    when 'name_corporate_entity'
      result << "#{target["primary_name"]}" if target["primary_name"]
      result << ". #{target["subordinate_name_1"]}" if target["subordinate_name_1"]
      result << ". #{target["subordinate_name_2"]}" if target["subordinate_name_2"]

      grouped = [target["number"], target["dates"]].reject{|v| v.nil?}
      result << " (#{grouped.join(" : ")})" if not grouped.empty?
    when 'name_family'
      result << target["family_name"] if target["family_name"]
      result << ", #{target["prefix"]}" if target["prefix"]
      result << ", #{target["dates"]}" if target["dates"]
    when 'name_software'
      result << "#{target["manufacturer"]} " if target["manufacturer"]
      result << "#{target["software_name"]}" if target["software_name"]
      result << " #{target["version"]}" if target["version"]
    end

    result << " (#{target["qualifier"]})" if target["qualifier"]

    result.lstrip!

    if result.length > 255
      return result[0..254]
    else
      return result
    end

  end
end