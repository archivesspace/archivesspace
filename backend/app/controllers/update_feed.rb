class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/update-feed')
    .description("Get a stream of updated records")
    .permissions([:index_system])
    .params(["last_sequence", Integer, "The last sequence number seen",
             :optional => true,
             :default => 0],
            ["resolve", :resolve])
    .returns([200, "a list of records and sequence numbers"]) \
  do
    updates = RealtimeIndexing.blocking_updates_since(params[:last_sequence])

    json_response(resolve_references(updates, params[:resolve]))
  end


  Endpoint.get('/delete-feed')
    .description("Get a stream of deleted records")
    .permissions([:index_system])
    .params()
    .paged(true)
    .returns([200, "a list of URIs that were deleted"]) \
  do
    modified_since_time = Time.at(params[:modified_since])

    dataset = Tombstone.where { timestamp >= modified_since_time }
    dataset = dataset.extension(:pagination).paginate(params[:page], params[:page_size])

    response = {
      :first_page => dataset.page_range.first,
      :last_page => dataset.page_range.last,
      :this_page => dataset.current_page,
      :results => dataset.map(&:uri)
    }

    json_response(response)
  end

end
