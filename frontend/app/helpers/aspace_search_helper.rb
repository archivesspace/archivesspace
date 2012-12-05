module AspaceSearchHelper

  def jsonmodel_url_for(search_result_json, action)
    case search_result_json["jsonmodel_type"]
      when "accession"
        {:controller => :accessions, :action => action, :id => JSONModel(:accession).id_for(search_result_json["uri"]),:search_token => @search_data['search_token']}
      when "resource"
        {:controller => :resources, :action => action, :id => JSONModel(:resource).id_for(search_result_json["uri"]),:search_token => @search_data['search_token']}
      when "archival_object"
        {
          :controller => :resources,
          :action => action,
          :id => JSONModel(:resource).id_for(search_result_json["resource"]),
          :anchor => "tree::archival_object_#{JSONModel(:archival_object).id_for(search_result_json["uri"])}",
          :search_token => @search_data['search_token']

        }
      when "digital_object"
        {:controller => :digital_objects, :action => action, :id => JSONModel(:digital_object).id_for(search_result_json["uri"]),:search_token => @search_data['search_token']}
      when "digital_object_component"
        {
          :controller => :digital_objects,
          :action => action,
          :id => JSONModel(:digital_object).id_for(search_result_json["digital_object"]),
          :anchor => "tree::digital_object_component_#{JSONModel(:digital_object_component).id_for(search_result_json["uri"])}",
          :search_token => @search_data['search_token']
        }
      else
        nil
    end
  end

  def jsonmodel_edit_url_for(search_result_json)
    jsonmodel_url_for(search_result_json, :show)
  end

  def jsonmodel_view_url_for(search_result_json)
    jsonmodel_url_for(search_result_json, :edit)
  end

end
