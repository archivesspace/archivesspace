class Search

  def self.search(params, repo_id)
    show_suppressed = !RequestContext.get(:enforce_suppression)
    show_published_only = RequestContext.get(:current_username) === User.PUBLIC_USERNAME

    query = params[:q] || "*:*"

    query = advanced_query_string(params[:aq]['query']) if params[:aq]

    Solr.search(query, params[:page], params[:page_size],
                repo_id,
                params[:type], show_suppressed, show_published_only, false, params[:exclude], params[:filter_term],
                {
                  "facet.field" => Array(params[:facet]),
                  "sort" => params[:sort]
                })
  end

end
