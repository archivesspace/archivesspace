require_relative '../lib/slug_helpers'

class ArchivesSpaceService < Sinatra::Base
	# if slug found, returns JSON with ID for matching slug and table where it came from
	# returns -1 for id otherwise.
	Endpoint.get('/slug')
    .description("Search across repositories")
    .params('slug', 'controller', 'action')
    .permissions([])
    .returns([200, ""]) \
  do
  	id, table = SlugHelpers.get_id_from_slug(params['slug'], 
  																			     params['controller'], 
  																			     params['action'])

  	json_response({:id => id, :table => table})
  end
end
