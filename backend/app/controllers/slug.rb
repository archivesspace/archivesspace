require_relative '../lib/slug_helpers'

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
                                             params['action'],
                                             nil)

    json_response({:id => id, :table => table, :repo_id => repo_id})
  end

  # same as above, with the repo_slug param
  Endpoint.get('/slug_with_repo')
    .description("Find the record given the slug and repository slug, return id, repo_id, and table name")
    .params('slug', 'controller', 'action', 'repo_slug')
    .permissions([])
    .returns([200, ""]) \
  do
    id, table, repo_id = SlugHelpers.get_id_from_slug(params['slug'],
                                             params['controller'],
                                             params['action'],
                                             params['repo_slug'])

    json_response({:id => id, :table => table, :repo_id => repo_id})
  end
end
