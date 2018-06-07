class ArchivesSpaceService < Sinatra::Base
  Endpoint.get("/ark:/:naan/:id")
    .description("Redirect to resource identified by ARK ID")
    .params(["id", :id])
    .permissions([])
    .returns([404, "Not found"],
             [302, :redirect]) \
  do
    if ark = ARKIdentifier[params[:id]]
      url = get_ark_url(ark)

      if url
        redirect url
      else
        not_found = true
      end
    else # ark not found via id
      not_found = true
    end

    status 404 if not_found
  end

  # helper method to resolve URL that ARK should point to
  def get_ark_url(ark)
    if ark.resource_id
      if resource = Resource.any_repo.filter(:id => ark.resource_id).first
        if resource.external_ark_url
          url = resource.external_ark_url 
        else
          url = AppConfig[:public_proxy_url] + "/repositories/" + resource[:repo_id].to_s + "/resources/" + ark.resource_id.to_s
        end
      else
        url = nil
      end
    elsif ark.accession_id
      if accession = Accession.any_repo.filter(:id => ark.accession_id).first
        if accession.external_ark_url
          url = accession.external_ark_url
        else
          url = AppConfig[:public_proxy_url] + "/repositories/" + accession[:repo_id].to_s + "/accessions/" + ark.accession_id.to_s
        end
      else
        url = nil
      end
    elsif ark.digital_object_id
      if dig_obj = DigitalObject.any_repo.filter(:id => ark.digital_object_id).first
        if dig_obj.external_ark_url
          url = dig_obj.external_ark_url
        else
          url = AppConfig[:public_proxy_url] + "/repositories/" + dig_obj[:repo_id].to_s + "/digital_objects/" + ark.digital_object_id.to_s
        end
      else
        url = nil
      end
    end

    return url
  end
end
