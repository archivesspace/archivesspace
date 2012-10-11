class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/vocabularies/:vocab_id')
    .description("Update a Vocabulary")
    .params(["vocab_id", Integer, "The vocabulary ID to update"],
            ["vocabulary", JSONModel(:vocabulary), "The vocabulary data to update", :body => true])
    .returns([200, :updated]) \
  do
    handle_update(Vocabulary, :vocab_id, :vocabulary)
  end

  Endpoint.post('/vocabularies')
    .description("Create a Vocabulary")
    .params(["vocabulary", JSONModel(:vocabulary), "The vocabulary data to create", :body => true])
    .returns([200, :created]) \
  do
    handle_create(Vocabulary, :vocabulary)
  end


  Endpoint.get('/vocabularies')
    .description("Get a list of Vocabularies")
    .params(["ref_id", String, "An alternate, externally-created ID for the vocabulary", :optional => true])
    .returns([200, "[(:vocabulary)]"]) \
  do
    if params[:ref_id]
      handle_listing(Vocabulary, :vocabulary, :ref_id => params[:ref_id])
    else
      handle_listing(Vocabulary, :vocabulary)
    end
  end


  Endpoint.get('/vocabularies/:vocab_id/terms')
    .description("Get a list of Terms for a Vocabulary")
    .params(["vocab_id", Integer, "The vocabulary ID"])
    .returns([200, "[(:term)]"]) \
  do
    handle_listing(Term, :term, :vocab_id => params[:vocab_id])
  end


  Endpoint.get('/vocabularies/:vocab_id')
    .description("Get a Vocabulary by ID")
    .params(["vocab_id", Integer, "The vocabulary ID"])
    .returns([200, "OK"]) \
  do
    json_response(Vocabulary.to_jsonmodel(params[:vocab_id], :vocabulary, :none))
  end
end
