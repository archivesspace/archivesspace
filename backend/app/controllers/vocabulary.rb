class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/vocabularies/:id')
    .description("Update a Vocabulary")
    .params(["id", :id],
            ["vocabulary", JSONModel(:vocabulary), "The updated record", :body => true])
    .permissions([:update_vocabulary_record])
    .returns([200, :updated]) \
  do
    handle_update(Vocabulary, params[:id], params[:vocabulary])
  end

  Endpoint.post('/vocabularies')
    .description("Create a Vocabulary")
    .params(["vocabulary", JSONModel(:vocabulary), "The record to create", :body => true])
    .permissions([:update_vocabulary_record])
    .returns([200, :created]) \
  do
    handle_create(Vocabulary, params[:vocabulary])
  end


  Endpoint.get('/vocabularies')
    .description("Get a list of Vocabularies")
    .params(["ref_id", String, "An alternate, externally-created ID for the vocabulary", :optional => true])
    .permissions([])
    .returns([200, "[(:vocabulary)]"]) \
  do
    if params[:ref_id]
      handle_unlimited_listing(Vocabulary, :ref_id => params[:ref_id])
    else
      handle_unlimited_listing(Vocabulary)
    end
  end


  Endpoint.get('/vocabularies/:id/terms')
    .description("Get a list of Terms for a Vocabulary")
    .params(["id", :id])
    .permissions([])
    .returns([200, "[(:term)]"]) \
  do
    handle_unlimited_listing(Term, :vocab_id => params[:id])
  end


  Endpoint.get('/vocabularies/:id')
    .description("Get a Vocabulary by ID")
    .params(["id", :id])
    .permissions([])
    .returns([200, "OK"]) \
  do
    json_response(Vocabulary.to_jsonmodel(params[:id]))
  end
end
