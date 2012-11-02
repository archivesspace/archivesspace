class ArchivesSpaceService < Sinatra::Base


  Endpoint.post('/subjects')
    .description("Create a Subject")
    .params(["subject", JSONModel(:subject), "The subject data to create", :body => true])
    .returns([200, :created]) \
  do
    handle_create(Subject, :subject)
  end


  Endpoint.get('/subjects')
    .description("Get a list of Subjects")
    .params()
    .returns([200, "[(:subject)]"]) \
  do
    handle_listing(Subject, :subject)
  end


  Endpoint.get('/subjects/:subject_id')
    .description("Get a Subject by ID")
    .params(["subject_id", Integer, "The subject ID"])
    .returns([200, "(:subject)"]) \
  do
    json_response(Subject.to_jsonmodel(params[:subject_id], :subject).to_hash)
  end
end
