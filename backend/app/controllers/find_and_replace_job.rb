class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/find_and_replace_jobs')
    .description("Create a new find and replace job")
    .params(["job", JSONModel(:find_and_replace_job), "The job definition", :body => true],
            ["repo_id", :repo_id])
    .permissions([:administer_system])
    .returns([200, :updated]) \
  do
    job = FindAndReplaceJob.create_from_json(params[:job], :user => current_user)

    created_response(job, params[:job])
  end


  Endpoint.post('/repositories/:repo_id/find_and_replace_jobs/:id/cancel')
    .description("Cancel a find and replace job")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:administer_system])
    .returns([200, :updated]) \
  do
    job = FindAndReplaceJob.get_or_die(params[:id])
    job.cancel!

    updated_response(job)
  end


  Endpoint.get('/repositories/:repo_id/find_and_replace_jobs')
    .description("Get a list of Jobs for a Repository")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:job)]"]) \
  do
    handle_listing(FindAndReplaceJob, params, {}, [:status, :id])
  end


  Endpoint.get('/repositories/:repo_id/find_and_replace_jobs/active')
    .description("Get a list of all active Jobs for a Repository")
    .params(["resolve", :resolve],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "[(:job)]"]) \
  do
    running = CrudHelpers.scoped_dataset(FindAndReplaceJob, :status => "running")
    queued = CrudHelpers.scoped_dataset(FindAndReplaceJob, :status => "queued")

    # Sort the running jobs newest to oldest, then show queued jobs oldest to
    # newest (since the oldest jobs run next)
    active = running.all.sort{|a,b| b.system_mtime <=> a.system_mtime} + queued.all.sort{|a,b| a.system_mtime <=> b.system_mtime}

    listing_response(active, FindAndReplaceJob)
  end


  Endpoint.get('/repositories/:repo_id/find_and_replace_jobs/archived')
    .description("Get a list of all archived Jobs for a Repository")
    .params(["resolve", :resolve],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .paginated(true)
    .returns([200, "[(:job)]"]) \
  do
    handle_listing(FindAndReplaceJob, params, Sequel.~(:status => ["running", "queued"]), Sequel.desc(:time_finished))
  end


  Endpoint.get('/repositories/:repo_id/find_and_replace_jobs/:id')
    .description("Get a Job by ID")
    .params(["id", :id],
            ["resolve", :resolve],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "(:job)"]) \
  do
    json_response(resolve_references(FindAndReplaceJob.to_jsonmodel(params[:id]), params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/find_and_replace_jobs/:id/log')
    .description("Get a Job's log by ID")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["offset",
             NonNegativeInteger,
             "The byte offset of the log file to show",
             :default => 0])
    .permissions([:view_repository])
    .returns([200, "The section of the import log between 'offset' and the end of file"]) \
  do
    job = FindAndReplaceJob.get_or_die(params[:id])
    (stream, length) = job.get_output_stream(params[:offset])

    [
     200,
     {'Content-Type' => 'text/plain', 'Content-Length' => length.to_s},
     Enumerator.new do |y|
       begin
         while (length > 0 && chunk = stream.read([length, 4096].min))
           y << chunk
           length -= chunk.bytesize
         end
       ensure
         stream.close
       end
     end
    ]
  end


  # Endpoint.get('/repositories/:repo_id/find_and_replace_jobs/:id/records')
  #   .description("Get a Job's list of created URIs")
  #   .params(["id", :id],
  #           ["repo_id", :repo_id])
  #   .permissions([:view_repository])
  #   .paginated(true)
  #   .returns([200, "An array of created records"]) \
  # do
  #   job = FindAndReplaceJob.get_or_die(params[:id])

  #   # Collection management records aren't true top-level records.  I think they
  #   # need a bit of a rethink.  They're really nested records, so they shouldn't
  #   # have URIs in the first place.
  #   handle_listing(FindAndReplaceJobCreatedRecord,
  #                  params,
  #                  Sequel.&(Sequel.~(Sequel.like(:record_uri, "%/collection_management/%")), {:job_id => job.id}),
  #                  Sequel.desc(:create_time))
  # end

end
