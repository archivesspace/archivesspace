module MergeHelpers
  def parse_references(request)
    merge_destination = JSONModel.parse_reference(request.merge_destination['ref'])
    merge_candidates = request.merge_candidates.map {|merge_candidate| JSONModel.parse_reference(merge_candidate['ref'])}

    [merge_destination, merge_candidates]
  end

  def check_repository(merge_destination, merge_candidates, repo_id)
    repo_uri = JSONModel(:repository).uri_for(repo_id)

    if ([merge_destination] + merge_candidates).any? {|r| r[:repository] != repo_uri}
      raise BadParamsException.new(:merge_request => ["All records to merge must be in the repository specified"])
    end
  end


  def ensure_type(merge_destination, merge_candidates, type)
    if (merge_candidates.map {|r| r[:type]} + [merge_destination[:type]]).any? {|t| t != type}
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
          next if v2.is_a? String
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

  # when merging, set the agent id foreign key (e.g, agent_person_id, agent_family_id...) from the merge_candidate to the merge_destination
  def set_agent_id(merge_destination_id, subrecord)
    if subrecord['agent_person_id']
      subrecord['agent_person_id'] = merge_destination_id

    elsif subrecord['agent_family_id']
      subrecord['agent_family_id'] = merge_destination_id

    elsif subrecord['agent_corporate_entity_id']
      subrecord['agent_corporate_entity_id'] = merge_destination_id

    elsif subrecord['agent_software_id']
      subrecord['agent_software_id'] = merge_destination_id

    # this section updates related_agents ids
    elsif subrecord['agent_person_id_0']
      subrecord['agent_person_id_0'] = merge_destination_id

    elsif subrecord['agent_family_id_0']
      subrecord['agent_family_id_0'] = merge_destination_id

    elsif subrecord['agent_corporate_entity_id_0']
      subrecord['agent_corporate_entity_id_0'] = merge_destination_id
    end
  end

  def merge_details(merge_destination, merge_candidate, selections, params)
    merge_destination[:linked_events] = []
    merge_candidate[:linked_events] = []

    subrec_add_replacements = []
    field_replacements = []
    merge_candidate_values = {}
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
      merge_candidate_values[subrec_name] = values_from_params[subrec_name]

      # subrec level add/replace
      if path_fix[2] == "append" || path_fix[2] == "replace"
        subrec_add_replacements.push(path_fix)

      # field level replace
      else
        field_replacements.push(path_fix)
      end
    end

    merge_details_subrec(merge_destination, merge_candidate, subrec_add_replacements, merge_candidate_values)
    merge_details_replace_field(merge_destination, merge_candidate, field_replacements, merge_candidate_values)

    merge_destination['title'] = merge_destination['names'][0]['sort_name']
    merge_destination

  # This code can be hard to debug when things go wrong, especially since details of problems aren't bubbled up to the frontend where the user is.
  # So we'll make sure to catch problems and dump out any info we know.
  rescue => e
    STDERR.puts "EXCEPTION!"
    STDERR.puts e.inspect
    STDERR.puts e.backtrace
  end

  # do field replace operations
  def merge_details_replace_field(merge_destination, merge_candidate, selections, values)
    selections.each do |path_fix|
      subrec_name = path_fix[0]
      # this is the index of the order the user arranged the subrecs in the form, not the order of the subrecords in the DB.
      ind         = path_fix[1]
      field       = path_fix[2]
      position    = path_fix[3]

      subrec_index = find_subrec_index_in_merge_candidate(merge_candidate, subrec_name, position)

      merge_destination[subrec_name][ind][field] = merge_candidate[subrec_name][subrec_index][field]
    end
  end


  # do subrec replace operations
  def merge_details_subrec(merge_destination, merge_candidate, selections, values)
    selections.each do |path_fix|
      subrec_name = path_fix[0]
      # this is the index of the order the user arranged the subrecs in the form, not the order of the subrecords in the DB.
      ind         = path_fix[1]
      mode        = path_fix[2]
      position    = path_fix[3]

      subrec_index = find_subrec_index_in_merge_candidate(merge_candidate, subrec_name, position)

      replacer = merge_candidate[subrec_name][subrec_index]

      # notes are a special case because of the way they store JSON in a db field. So Reordering is not supported, and we can assume the position in the merge request is the position in the merge_candidates notes subrecord JSON.
      if subrec_name == "notes"
        replacer = merge_candidate["notes"][ind]
        to_append = process_subrecord_for_merge(merge_destination, replacer, subrec_name, mode, ind)

        merge_destination[subrec_name].push(process_subrecord_for_merge(merge_destination, replacer, subrec_name, mode, ind))
      elsif mode == "replace"
        merge_destination[subrec_name][ind] = process_subrecord_for_merge(merge_destination, replacer, subrec_name, mode, ind)
      elsif mode == "append"
        merge_destination[subrec_name].push(process_subrecord_for_merge(merge_destination, replacer, subrec_name, mode, ind))
      end

    end
  end

  # we don't know how the user reordered the subrecords on the merge form,
  # so find the index with the right data given the position of the right thing to replace/add by searching for it.
  def find_subrec_index_in_merge_candidate(merge_candidate, subrec_name, position)
    ind = nil
    merge_candidate[subrec_name].each_with_index do |subrec, i|
      if i == position
        ind = i
        break
      end
    end

    return ind ? ind : -1
  end

  # before we can merge a subrecord, we need to update the IDs, tweak things to prevent validation issues, etc
  def process_subrecord_for_merge(merge_destination, subrecord, jsonmodel_type, mode, ind)
    merge_destination_id = merge_destination['id']

    if jsonmodel_type == 'names'
      # an agent name can only have one authorized or display name.
      # make sure the name being merged in doesn't conflict with this

      # if appending, always disable fields that validate across a set. If replacing, always keep values from merge_destination
      if mode == "append"
        subrecord['authorized']      = false
        subrecord['is_display_name'] = false
      elsif mode == "replace"
        subrecord['authorized']      = merge_destination['names'][ind]['authorized']
        subrecord['is_display_name'] = merge_destination['names'][ind]['is_display_name']
      end

    elsif jsonmodel_type == 'agent_record_identifiers'
      # same with agent_record_identifiers being marked as primary, we can only have one

      if mode == "append"
        subrecord['primary_identifier'] = false

      elsif mode == "replace"
        subrecord['primary_identifier'] = merge_destination['agent_record_identifiers'][ind]['primary_identifier']
      end
    end

    set_agent_id(merge_destination_id, subrecord)

    return subrecord
  end


  # NOTE: this code is a duplicate of the auto_generate code for creating sort name
  # in the name_person, name_family, name_software, name_corporate_entity models
  # Consider refactoring when continued work done on the agents model enhancements
  def preview_sort_name(merge_destination)
    result = ""

    case merge_destination['jsonmodel_type']
    when 'name_person'
      if merge_destination["name_order"] === "inverted"
        result << merge_destination["primary_name"] if merge_destination["primary_name"]
        result << ", #{merge_destination["rest_of_name"]}" if merge_destination["rest_of_name"]
      elsif merge_destination["name_order"] === "direct"
        result << merge_destination["rest_of_name"] if merge_destination["rest_of_name"]
        result << " #{merge_destination["primary_name"]}" if merge_destination["primary_name"]
      else
        result << merge_destination["primary_name"] if merge_destination["primary_name"]
      end

      result << ", #{merge_destination["prefix"]}" if merge_destination["prefix"]
      result << ", #{merge_destination["suffix"]}" if merge_destination["suffix"]
      result << ", #{merge_destination["title"]}" if merge_destination["title"]
      result << ", #{merge_destination["number"]}" if merge_destination["number"]
      result << " (#{merge_destination["fuller_form"]})" if merge_destination["fuller_form"]
      result << ", #{merge_destination["dates"]}" if merge_destination["dates"]
    when 'name_corporate_entity'
      result << "#{merge_destination["primary_name"]}" if merge_destination["primary_name"]
      result << ". #{merge_destination["subordinate_name_1"]}" if merge_destination["subordinate_name_1"]
      result << ". #{merge_destination["subordinate_name_2"]}" if merge_destination["subordinate_name_2"]

      grouped = [merge_destination["number"], merge_destination["dates"]].reject {|v| v.nil?}
      result << " (#{grouped.join(" : ")})" if not grouped.empty?
    when 'name_family'
      result << merge_destination["family_name"] if merge_destination["family_name"]
      result << ", #{merge_destination["prefix"]}" if merge_destination["prefix"]
      result << ", #{merge_destination["dates"]}" if merge_destination["dates"]
    when 'name_software'
      result << "#{merge_destination["manufacturer"]} " if merge_destination["manufacturer"]
      result << "#{merge_destination["software_name"]}" if merge_destination["software_name"]
      result << " #{merge_destination["version"]}" if merge_destination["version"]
    end

    result << " (#{merge_destination["qualifier"]})" if merge_destination["qualifier"]

    result.lstrip!

    if result.length > 255
      return result[0..254]
    else
      return result
    end
  end
end
