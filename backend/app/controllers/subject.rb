class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/subjects/:subject_id')
    .params(["subject_id", Integer, "The subject ID to update"],
            ["subject", JSONModel(:subject), "The subject data to update", :body => true])
    .returns([200, "OK"]) \
  do
    subject = Subject.get_or_die(params[:subject_id])
    subject.update_from_json(params[:subject])
    json_response({:status => "Updated", :id => subject[:id]})
  end

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
    Subject.to_jsonmodel(params[:subject_id], :subject).to_json
  end
end
