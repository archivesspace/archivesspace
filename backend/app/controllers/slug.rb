require_relative '../lib/slugs/slug_helpers'

class ArchivesSpaceService < Sinatra::Base
  # if slug found, returns JSON with ID for matching slug and table where it came from
  # returns -1 for id otherwise.
  Endpoint.get('/slug')
    .description("Find the record given the slug, return id, repo_id, and table name")
    .params('slug', 'controller', 'action')
    .permissions([])
    .returns([200, ""]) \
  do
    id, table, repo_id = SlugHelpers.get_id_from_slug(params['slug'],
                                             params['controller'],
                                             params['action'])

    json_response({:id => id, :table => table, :repo_id => repo_id})
  end
end
