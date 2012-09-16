class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/vocabularies/:vocab_id')
    .description("Update a Vocabulary")
    .params(["vocab_id", Integer, "The vocabulary ID to update"],
            ["vocabulary", JSONModel(:vocabulary), "The vocabulary data to update", :body => true])
    .returns([200, :updated]) \
  do
    vocabulary = Vocabulary.get_or_die(params[:vocab_id])
    vocabulary.update_from_json(params[:vocabulary])
    updated_response(vocabulary, params[:vocabulary])
  end

  Endpoint.post('/vocabularies')
    .description("Create a Vocabulary")
    .params(["vocabulary", JSONModel(:vocabulary), "The vocabulary data to create", :body => true])
    .returns([200, :created]) \
  do
    vocabulary = Vocabulary.create_from_json(params[:vocabulary])

    created_response(vocabulary, params[:vocabulary])
  end


  Endpoint.get('/vocabularies')
    .description("Get a list of Vocabularies")
    .params(["ref_id", String, "An alternate, externally-created ID for the vocabulary", :optional => true])
    .returns([200, "[(:vocabulary)]"]) \
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


  Endpoint.get('/vocabularies/:vocab_id/terms')
    .description("Get a list of Terms for a Vocabulary")
    .params(["vocab_id", Integer, "The vocabulary ID"])
    .returns([200, "[(:term)]"]) \
  do
    json_response(Term.filter({:vocab_id => params[:vocab_id]}).collect {|t|
                    Term.to_jsonmodel(t, :term).to_hash})
  end


  Endpoint.get('/vocabularies/:vocab_id')
    .description("Get a Vocabulary by ID")
    .params(["vocab_id", Integer, "The vocabulary ID"])
    .returns([200, "OK"]) \
  do
    Vocabulary.to_jsonmodel(params[:vocab_id], :vocabulary).to_json
  end
end
