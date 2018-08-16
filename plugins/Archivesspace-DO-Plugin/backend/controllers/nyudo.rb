require_relative File.join(ASUtils.find_base_directory, 'plugins/nyudo', 'mixed_content_parser')


class ArchivesSpaceService < Sinatra::Base

  # Endpoint to return data to archiveit for display in their interfaces
  Endpoint.get('/plugins/nyudo/repositories/:repo_id/archiveit/:resource_id')
    .description("Get summarized Digital Object data for a specific Resource")
    .params(["repo_id", :repo_id],
      ["resource_id", String])
    .permissions([:view_repository])
    .returns([200, "[(:digital_object)]"],
      [400, :error]) \
    do

    summary = Composers.summary(params[:resource_id])
    detail = Composers.detailed(summary[0][:component_id])

    resp = {
      :title => detail[:resource_title], 
      :extent => summary.size.to_s + " Digital Objects", 
      :display_url =>  File.join(AppConfig[:backend_proxy_url], "plugins/nyudo/repositories/#{params[:repo_id]}/#{params[:resource_id]}") 
    }

    if resp.empty?
      json_response({:error => "Resource not found for identifier: #{params[:resource_id]}"}, 400)
    else
      json_response(resp)
    end

  end

  # Endpoint to return data about a resource in archivesspace
  Endpoint.get('/plugins/nyudo/repositories/:repo_id/summary/:resource_id')
    .description("Get summarized Digital Object data for a specific Resource")
    .params(["resource_id", String], ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "[(:digital_object)]"],
      [400, :error]) \
    do
    
    digital_objects = Composers.summary(params[:resource_id])
    
    if digital_objects.empty?
      json_response({:error => "Resource not found for identifier: #{params[:resource_id]}"}, 400)
    else
      resource = Composers.get_resource(digital_objects[0][:component_id])
      json_response(
        :version => "0.0.1", 
        :resource_identifier => resource[:resource_identifier], 
        :resource_title => resource[:resource_title], 
        :ead_location => resource[:ead_location],
        :scopecontent => resource[:resource_scopecontent][0],
        :bioghist => resource[:resource_bioghist][0],
        :digital_objects => digital_objects)
    end
  end

  # Endpoint to return data about a an archival object in archivesspace
  Endpoint.get('/plugins/nyudo/repositories/:repo_id/detailed/:component_id')
    .description("Get detailed data for a specific digital object record")
    .params(["component_id", String, "Component id for the record"], ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "[(:digital_object)]"],
       [400, :error]) \
    do

    archival_object = Composers.detailed(params[:component_id])
    parent = Composers.get_parent(archival_object)
    aeon_form = 'https://aeon.library.nyu.edu/aeonauth/Logon?Action=10&Form=31&Value='.to_s
    ead_loc = Composers.get_resource(params[:component_id])[:ead_location].gsub(/html/, "ead").to_s + '.xml&view=xml'.to_s
    aeon_url = aeon_form + ead_loc
    json_response(:archival_object => archival_object, :parent_object => parent, :request_url => aeon_url)
  
  end

end
