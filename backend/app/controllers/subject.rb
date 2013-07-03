class ArchivesSpaceService < Sinatra::Base


  Endpoint.post('/subjects/:id')
    .description("Update a Subject")
    .params(["id", :id],
            ["subject", JSONModel(:subject), "The updated record", :body => true])
    .permissions([:update_subject_record])
    .returns([200, :updated]) \
  do
    handle_update(Subject, params[:id], params[:subject])
  end


  Endpoint.post('/subjects')
    .description("Create a Subject")
    .params(["subject", JSONModel(:subject), "The record to create", :body => true])
    .permissions([:update_subject_record])
    .returns([200, :created]) \
  do
    handle_create(Subject, params[:subject])
  end


  Endpoint.get('/subjects')
    .description("Get a list of Subjects")
    .params()
    .paginated(true)
    .permissions([])
    .returns([200, "[(:subject)]"]) \
  do
    handle_listing(Subject, params)
  end


  Endpoint.get('/subjects/:id')
    .description("Get a Subject by ID")
    .params(["id", :id])
    .permissions([])
    .returns([200, "(:subject)"]) \
  do
    json_response(Subject.to_jsonmodel(params[:id]))
  end


  Endpoint.delete('/subjects/:id')
    .description("Delete a Subject")
    .params(["id", :id])
    .permissions([:delete_subject_record])
    .returns([200, :deleted]) \
  do
    handle_delete(Subject, params[:id])
  end

end
