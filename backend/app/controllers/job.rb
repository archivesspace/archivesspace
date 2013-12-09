class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/jobs')
    .description("Create a new import job")
    .params(["job", JSONModel(:job)],
            ["files", [UploadFile]],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, :updated]) \
  do
    [200, {}, params[:files].map(&:filename).to_s]
  end

end
