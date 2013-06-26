class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/accessions/:accession_id/transfer')
    .description("Transfer this record to a different repository")
    .params(["accession_id", Integer, "The accession ID to transfer"],
            ["target_repo", String, "The URI of the target repository"],
            ["repo_id", :repo_id])
    .permissions([:update_archival_record])
    .returns([200, :moved]) \
  do
    handle_transfer(Accession, params[:accession_id])
  end


  Endpoint.post('/repositories/:repo_id/resources/:resource_id/transfer')
    .description("Transfer this record to a different repository")
    .params(["resource_id", Integer, "The resource ID to transfer"],
            ["target_repo", String, "The URI of the target repository"],
            ["repo_id", :repo_id])
    .permissions([:update_archival_record])
    .returns([200, :moved]) \
  do
    handle_transfer(Resource, params[:resource_id])
  end


  Endpoint.post('/repositories/:repo_id/digital_objects/:digital_object_id/transfer')
    .description("Transfer this record to a different repository")
    .params(["digital_object_id", Integer, "The digital object ID to transfer"],
            ["target_repo", String, "The URI of the target repository"],
            ["repo_id", :repo_id])
    .permissions([:update_archival_record])
    .returns([200, :moved]) \
  do
    handle_transfer(DigitalObject, params[:digital_object_id])
  end



  private


  def handle_transfer(model, id)
    target_id = JSONModel(:repository).id_for(params[:target_repo])
    target = target_id && Repository[target_id]

    raise BadParamsException.new(:target_repo => ["Repository not found"]) if !target

    RequestContext.open(:repo_id => target.id) do
      if !current_user.can?(:update_archival_record)
        raise AccessDeniedException.new(:target_repo => ["Permission denied"])
      end
    end

    model.get_or_die(id).transfer_to_repository(target)

    moved_response(id, target)

  end


end
