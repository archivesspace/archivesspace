class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/update-feed')
    .description("Get a stream of updated records")
    .preconditions(proc { current_user.can?(:index_system) })
    .params(["last_sequence", Integer, "The last sequence number seen",
             :optional => true,
             :default => 0])
    .returns([200, "a list of records and sequence numbers"]) \
  do
    updates = RealtimeIndexing.blocking_updates_since(params[:last_sequence])

    json_response(updates)
  end


  Endpoint.get('/delete-feed')
    .description("Get a stream of deleted records")
    .preconditions(proc { current_user.can?(:index_system) })
    .params(*Endpoint.pagination)
    .returns([200, "a list of URIs that were deleted"]) \
  do
    modified_since_time = Time.at(params[:modified_since])

    dataset = Tombstone.where { timestamp >= modified_since_time }
    dataset = dataset.paginate(params[:page], params[:page_size])

    response = {
      :first_page => dataset.page_range.first,
      :last_page => dataset.page_range.last,
      :this_page => dataset.current_page,
      :results => dataset.map(&:uri)
    }

    json_response(response)
  end

end
