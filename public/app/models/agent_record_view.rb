class AgentRecordView < ArchivalRecordView

  def names
    names = []

    @record['names'].each do |name|
      names << NameRecordView.new(name)
    end

    names
  end


  def published_agents
    related_agents = Array(@record['related_agents']).find_all {|doc| doc['_resolved']['publish'] === true}
    related_agents.each do |ra| 
      ra['dynamic_enum'] = JSONModel(ra['jsonmodel_type'].intern).schema['properties']['relator']['dynamic_enum']
    end

    related_agents
  end


  def related_resources
    criteria = {
      "filter_term[]" => [{"agent_uris" => @record['uri']}.to_json],
      "type[]" => "resource"
    }

    Search.all(criteria, {})
  end
end



class NameRecordView < ArchivalRecordView

end
