class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/accessions/:id/transfer')
    .description("Transfer this record to a different repository")
    .params(["id", :id],
            ["target_repo", String, "The URI of the target repository"],
            ["repo_id", :repo_id])
    .permissions([:update_accession_record])
    .returns([200, :moved]) \
  do
    handle_transfer(Accession, params[:id], :update_accession_record)
  end


  Endpoint.post('/repositories/:repo_id/resources/:id/transfer')
    .description("Transfer this record to a different repository")
    .params(["id", :id],
            ["target_repo", String, "The URI of the target repository"],
            ["repo_id", :repo_id])
    .permissions([:update_resource_record])
    .returns([200, :moved]) \
  do
    handle_transfer(Resource, params[:id], :update_resource_record)
  end


  Endpoint.post('/repositories/:repo_id/digital_objects/:id/transfer')
    .description("Transfer this record to a different repository")
    .params(["id", :id],
            ["target_repo", String, "The URI of the target repository"],
            ["repo_id", :repo_id])
    .permissions([:update_digital_object_record])
    .returns([200, :moved]) \
  do
    handle_transfer(DigitalObject, params[:id], :update_digital_object_record)
  end


  Endpoint.post('/repositories/:repo_id/transfer')
    .description("Transfer this record to a different repository")
    .params(["target_repo", String, "The URI of the target repository"],
            ["repo_id", :repo_id])
    .permissions([:transfer_repository])
    .returns([200, :moved]) \
  do
    target_id = JSONModel(:repository).id_for(params[:target_repo])

    # We require :transfer_repository permission in both the source & target
    # repositories.
    RequestContext.open(:repo_id => target_id) do
      if !current_user.can?(:transfer_repository)
        raise AccessDeniedException.new(:target_repo => ["Permission denied"])
      end
    end

    Repository[target_id].assimilate(Repository[params[:repo_id]])

    json_response(:status => "OK")
  end



  private


  def handle_transfer(model, id, perm)
    target_id = JSONModel(:repository).id_for(params[:target_repo])
    target = target_id && Repository[target_id]

    raise BadParamsException.new(:target_repo => ["Repository not found"]) if !target

    RequestContext.open(:repo_id => target.id) do
      if !current_user.can?(perm)
        raise AccessDeniedException.new(:target_repo => ["Permission denied"])
      end
    end

    model.get_or_die(id).transfer_to_repository(target)

    moved_response(id, target)

  end


end
