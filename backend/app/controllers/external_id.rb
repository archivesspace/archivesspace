class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/by-external-id')
    .description("List records by their external ID(s)")
    .permissions([:view_all_records])
    .params(["eid", String, "An external ID to find"],
            ["type",
             [String],
             "The record type to search (useful if IDs may be shared between different types)",
             :optional => true])
    .returns([303, "A redirect to the URI named by the external ID (if there's only one)"],
             [300, "A JSON-formatted list of URIs if there were multiple matches"],
             [404, "If there were no matches"]) \
  do
    show_suppressed = !RequestContext.get(:enforce_suppression)
    results = Solr.search("{!term f=external_id}#{params[:eid]}", 1, 10, nil, params[:type], show_suppressed)

    if results['total_hits'] == 0
      [404, {}, "[]"]
    elsif results['total_hits'] == 1
      [303, {"Location" => results['results'][0]['uri']}, ""]
    else
      json_response(results['results'].map {|result| result['uri']}, 300)
    end
  end

end
