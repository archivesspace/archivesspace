class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/accessions/:id/suppressed')
  .description("Suppress this record")
  .params(["id", :id],
          ["suppressed", BooleanParam, "Suppression state"],
          ["repo_id", :repo_id])
  .permissions([:suppress_archival_record])
  .returns([200, :suppressed]) \
  do
    sup_state = Accession.get_or_die(params[:id]).set_suppressed(params[:suppressed])

    suppressed_response(params[:id], sup_state)
  end


  Endpoint.post('/repositories/:repo_id/resources/:id/suppressed')
  .description("Suppress this record")
  .params(["id", :id],
          ["suppressed", BooleanParam, "Suppression state"],
          ["repo_id", :repo_id])
  .permissions([:suppress_archival_record])
  .returns([200, :suppressed]) \
  do
    sup_state = Resource.get_or_die(params[:id]).set_suppressed(params[:suppressed])

    suppressed_response(params[:id], sup_state)
  end


  Endpoint.post('/repositories/:repo_id/archival_objects/:id/suppressed')
  .description("Suppress this record")
  .params(["id", :id],
          ["suppressed", BooleanParam, "Suppression state"],
          ["repo_id", :repo_id])
  .permissions([:suppress_archival_record])
  .returns([200, :suppressed]) \
  do
    sup_state = ArchivalObject.get_or_die(params[:id]).set_suppressed(params[:suppressed])

    suppressed_response(params[:id], sup_state)
  end


  Endpoint.post('/repositories/:repo_id/digital_objects/:id/suppressed')
  .description("Suppress this record")
  .params(["id", :id],
          ["suppressed", BooleanParam, "Suppression state"],
          ["repo_id", :repo_id])
  .permissions([:suppress_archival_record])
  .returns([200, :suppressed]) \
  do
    sup_state = DigitalObject.get_or_die(params[:id]).set_suppressed(params[:suppressed])

    suppressed_response(params[:id], sup_state)
  end


  Endpoint.post('/repositories/:repo_id/digital_object_components/:id/suppressed')
  .description("Suppress this record")
  .params(["id", :id],
          ["suppressed", BooleanParam, "Suppression state"],
          ["repo_id", :repo_id])
  .permissions([:suppress_archival_record])
  .returns([200, :suppressed]) \
  do
    sup_state = DigitalObjectComponent.get_or_die(params[:id]).set_suppressed(params[:suppressed])

    suppressed_response(params[:id], sup_state)
  end

end