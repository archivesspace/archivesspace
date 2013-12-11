class ArchivesSpaceService < Sinatra::Base

  ######################################################################
  # FIXME: Need some permissions here
  ######################################################################
  Endpoint.post('/repositories/:repo_id/jobs')
    .description("Create a new import job")
    .params(["job", JSONModel(:job)],
            ["files", [UploadFile]],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, :updated]) \
  do
    job = ImportJob.create_from_json(params[:job], :user => current_user)

    params[:files].each do |file|
      job.add_file(file.tempfile)
    end

    created_response(job, params[:job])
  end

end
