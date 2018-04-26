class ArchivesSpaceService < Sinatra::Base
  Endpoint.get("/ark:/:naan/:id")
    .description("Redirect to resource identified by ARK ID")
    .params(["id", :id])
    .permissions([])
    .returns([404, "Not found"],
             [302, :redirect]) \
  do
    if ark = ARKIdentifier[params[:id]]
      if ark.resource_id
        # redirect to resource 
        if resource = Resource.any_repo.filter(:id => ark.resource_id).first
          redirect AppConfig[:ark_url_prefix] + 
                   "/repositories/" +
                   resource[:repo_id].to_s + 
                   "/resources/" +
                   ark.resource_id.to_s
        else
          not_found = true
        end


      elsif ark.accession_id
        # redirect to accession
        if accession = Accession.any_repo.filter(:id => ark.accession_id).first
          redirect AppConfig[:ark_url_prefix] + 
                   "/repositories/" +
                   accession[:repo_id].to_s + 
                   "/accessions/" +
                   ark.accession_id.to_s
        else
          not_found = true
        end


      elsif ark.digital_object_id
        # redirect to digital object
        if dig_obj = DigitalObject.any_repo.filter(:id => ark.digital_object_id).first
          redirect AppConfig[:ark_url_prefix] + 
                   "/repositories/" +
                   dig_obj[:repo_id].to_s + 
                   "/digital_objects/" +
                   ark.digital_object_id.to_s
        else
          not_found = true
        end
      end
    else # ark not found
      not_found = true
    end

    status 404 if not_found
  end
end
