class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/delete_requests/archival_records')
  .description("Carry out delete requests against a list of archival records")
  .params(["record_uris", [String], "A list of archival record uris"])
  .permissions([:delete_archival_record])
  .returns([200, :updated]) \
  do
    json_response(:status => "OK")
  end

end
