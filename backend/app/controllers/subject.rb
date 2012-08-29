class ArchivesSpaceService < Sinatra::Base


  Endpoint.post('/subjects')
    .params(["subject", JSONModel(:subject), "The subject data to create", :body => true])
    .returns([200, "OK"]) \
  do
    subject = Subject.create_from_json(params[:subject])

    created_response(subject[:id], params[:subject]._warnings)
  end


  Endpoint.get('/subjects')
    .params()
    .returns([200, "OK"]) \
  do
    json_response(Subject.all.collect {|subject|
                    Subject.to_jsonmodel(subject, :subject).to_hash
                  })
  end


  Endpoint.get('/subjects/:subject_id')
    .params(["subject_id", Integer, "The subject ID"])
    .returns([200, "OK"]) \
  do
    json_response(Subject.to_jsonmodel(params[:subject_id], :subject).to_hash)
  end
end
