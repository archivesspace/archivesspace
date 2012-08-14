class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/vocabularies/:vocab_id')
    .params(["vocab_id", Integer, "The vocabulary ID to update"],
            ["vocabulary", JSONModel(:vocabulary), "The vocabulary data to update", :body => true])
    .returns([200, "OK"]) \
  do
    vocabulary = Vocabulary.get_or_die(params[:vocab_id])
    vocabulary.update_from_json(params[:vocabulary])
    json_response({:status => "Updated", :id => vocabulary[:id]})
  end

  Endpoint.post('/vocabularies')
     .params(["vocabulary", JSONModel(:vocabulary), "The vocabulary data to create", :body => true])
     .returns([200, "OK"]) \
  do
    vocabulary = Vocabulary.create_from_json(params[:vocabulary])

    created_response(vocabulary[:id], params[:vocabulary]._warnings)
  end


  Endpoint.get('/vocabularies')
    .params(["ref_id", String, "An alternate, externally-created ID for the vocabulary", :optional => true])
    .returns([200, "OK"]) \
  do
    if params[:ref_id]
      json_response(Vocabulary.set({:ref_id => params[:ref_id] }).collect { |vocabulary|
                      Vocabulary.to_jsonmodel(vocabulary, :vocabulary).to_hash
                    })
    else
      json_response(Vocabulary.all.collect {|vocabulary|
                      Vocabulary.to_jsonmodel(vocabulary, :vocabulary).to_hash
                    })
    end
  end


  Endpoint.get('/vocabularies/:vocab_id')
    .params(["vocab_id", Integer, "The vocabulary ID"])
    .returns([200, "OK"]) \
  do
    Vocabulary.to_jsonmodel(params[:vocab_id], :vocabulary).to_json
  end
end
