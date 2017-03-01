class ArchivesSpaceService < Sinatra::Base


  Endpoint.post('/repositories/:repo_id/jobs')
    .description("Create a new job")
    .params(["job", JSONModel(:job), "The job object", :body => true],
            ["repo_id", :repo_id])
    .permissions([:import_records])
    .returns([200, :updated]) \
  do
    job = Job.create_from_json(params[:job], :user => current_user)

    created_response(job, params[:job])
  end


  Endpoint.post('/repositories/:repo_id/jobs_with_files')
    .description("Create a new job and post input files")
    .params(["job", JSONModel(:job)],
            ["files", [UploadFile]],
            ["repo_id", :repo_id])
    .permissions([:import_records])
    .returns([200, :updated]) \
  do
    job = Job.create_from_json(params[:job], :user => current_user)

    params[:files].each do |file|
      job.add_file(file.tempfile)
    end

    created_response(job, params[:job])
  end


  Endpoint.get('/repositories/:repo_id/jobs/types')
    .description("List all supported job types")
    .params(["repo_id", :repo_id])
    .permissions([])
    .returns([200, "A list of supported job types"]) \
  do
    json_response(JobRunner.registered_job_types)
  end


  # This should probably be encapsulated somewhere
  # with other import-specific backend logic
  Endpoint.get('/repositories/:repo_id/jobs/import_types')
    .description("List all supported import job types")
    .params(["repo_id", :repo_id])
    .permissions([])
    .returns([200, "A list of supported import types"]) \
  do
    show_hidden = false
    json_response(Converter.list_import_types(show_hidden))
  end


  Endpoint.post('/repositories/:repo_id/jobs/:id/cancel')
    .description("Cancel a Job")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:cancel_importer_job])
    .returns([200, :updated]) \
  do
    job = Job.get_or_die(params[:id])
    job.cancel!

    updated_response(job)
  end


  Endpoint.get('/repositories/:repo_id/jobs')
    .description("Get a list of Jobs for a Repository")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:job)]"]) \
  do
    handle_listing(Job, params, {}, [:status, :id])
  end


  Endpoint.get('/repositories/:repo_id/jobs/active')
    .description("Get a list of all active Jobs for a Repository")
    .params(["resolve", :resolve],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "[(:job)]"]) \
  do
    running = CrudHelpers.scoped_dataset(Job, :status => "running")
    queued = CrudHelpers.scoped_dataset(Job, :status => "queued")

    # Sort the running jobs newest to oldest, then show queued jobs oldest to
    # newest (since the oldest jobs run next)
    active = running.all.sort{|a,b| b.system_mtime <=> a.system_mtime} + queued.all.sort{|a,b| a.system_mtime <=> b.system_mtime}

    listing_response(active, Job)
  end


  Endpoint.get('/repositories/:repo_id/jobs/archived')
    .description("Get a list of all archived Jobs for a Repository")
    .params(["resolve", :resolve],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .paginated(true)
    .returns([200, "[(:job)]"]) \
  do
    handle_listing(Job, params, Sequel.~(:status => ["running", "queued"]), Sequel.desc(:time_finished))
  end


  Endpoint.get('/repositories/:repo_id/jobs/:id')
    .description("Get a Job by ID")
    .params(["id", :id],
            ["resolve", :resolve],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "(:job)"]) \
  do
    json_response(resolve_references(Job.to_jsonmodel(params[:id]), params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/jobs/:id/log')
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
    job = Job.get_or_die(params[:id])
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

  Endpoint.get('/repositories/:repo_id/jobs/:id/output_files')
    .description("Get a list of Job's output files by ID")
    .params(["id", :id],
            ["repo_id", :repo_id] )
    .permissions([:view_repository])
    .returns([200, "An array of output files"]) \
  do
    job = Job.get_or_die(params[:id])
    files = JobFile.filter( :job_id => job.id ).select(:id).map {|f| f[:id] } 
    json_response(files) 
  
  end
  
    Endpoint.get('/repositories/:repo_id/jobs/:id/output_files/:file_id')
    .description("Get a Job's output file by ID")
    .params(["id", :id],
            ["file_id", :id], 
            ["repo_id", :repo_id] )
    .permissions([:view_repository])
    .returns([200, "Returns the file"]) \
  do
    file = JobFile.filter(  :id => params[:file_id], :job_id => params[:id] ).select(:file_path).first
    stream_response(IO.read(file[:file_path]))
  
  end

  Endpoint.get('/repositories/:repo_id/jobs/:id/records')
    .description("Get a Job's list of created URIs")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .paginated(true)
    .returns([200, "An array of created records"]) \
  do
    job = Job.get_or_die(params[:id])

    # Collection management records aren't true top-level records.  I think they
    # need a bit of a rethink.  They're really nested records, so they shouldn't
    # have URIs in the first place.
    handle_listing(JobCreatedRecord,
                   params,
                   Sequel.&(Sequel.~(Sequel.like(:record_uri, "%/collection_management/%")), {:job_id => job.id}),
                   Sequel.desc(:create_time))
  end

end
