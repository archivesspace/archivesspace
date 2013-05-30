class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/update_monitor')
    .description("Refresh the list of currently known edits")
    .params(["active_edits",
             JSONModel(:active_edits),
             "The list of active edits",
             :body => true])
    .permissions([:mediate_edits])
    .use_transaction(false)
    .returns([200, "A list of records, the user editing it and the lock version for each"]) \
  do
    edits = ActiveEdit.update_with(params[:active_edits])

    json_response(edits)
  end

end
