class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/update_monitor')
    .description("Refresh the list of currently known edits")
    .params(["active_edits",
             JSONModel(:active_edits),
             "The list of active edits",
             :body => true])
    .permissions([:mediate_edits])
    .returns([200, "hooray"]) \
  do
    edits = ActiveEdit.update_with(params[:active_edits])

    json_response(edits)
  end

end
