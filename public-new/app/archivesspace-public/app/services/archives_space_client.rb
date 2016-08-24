require 'net/http'
require 'uri'

# This class is just a quick shim to get us connected and doing searches against
# the ArchivesSpace Solr instance.
#
# Ultimately we might want to split the ArchivesSpace interactions into
# different classes--different services for pulling back and mapping different
# data types.
#
class ArchivesSpaceClient

  DEFAULT_SEARCH_OPTS = {
    :page_size => AppConfig[:search_results_page_size]
  }

  # FIXME: Ultimately we'll set up a dedicated user for the public application
  # to use (instead of admin).
  def initialize(archivesspace_url: AppConfig[:archivesspace_url],
                 username: AppConfig[:archivesspace_user],
                 password: AppConfig[:archivesspace_password])
    @url = archivesspace_url
    @username = username
    @password = password

    # FIXME: We'll need some handling of lost sessions so the app reconnects if
    # ArchivesSpace's sessions are cleared.
    @session = login!
  end

  def list_repositories
    results = search_all_results("primary_type:repository")

    results.map { |result|
      Repository.from_json(JSON.parse(result['json']))
    }
  end

  def search(query, page = 1, search_opts = {})
    search_opts = DEFAULT_SEARCH_OPTS.merge(search_opts)
    url = build_url('/search', search_opts.merge(:q => query, :page => page))
    results = do_search(url)
  end

  # calls the '/search/records' endpoint
  def search_records(record_list, page = 1, search_opts = {})
    search_opts = DEFAULT_SEARCH_OPTS.merge(search_opts)
    url = build_url('/search/records', search_opts.merge("uri[]" => record_list))
    results = do_search(url)
  end

  # calls the '/search/published_tree' endpoint
  def get_tree(node_uri)
    url =  build_url('/search/published_tree', {:node_uri => node_uri})
    results = do_search(url)
    tree = JSON.parse(results['tree_json'])
  end

  private
  
  class LoginFailedException < StandardError; end

  class RequestFailedException < StandardError; end

  # perform the actual search, returning json-ized results, 
  # or raising an error
  def do_search(url)
    Rails.logger.debug("Search url: #{url}")
    request = Net::HTTP::Get.new(url)
    response = do_http_request(request)
    if response.code != '200'
      Rails.logger.debug("Code: #{response.code}")
      raise RequestFailedException.new("#{response.code}: #{response.body}")
    end
    JSON.parse(response.body)
  end
  

  # Authenticate to ArchivesSpace and grab a session token
  def login!
    path = "/users/#{@username}/login"

    request = Net::HTTP::Post.new(build_url(path))
    request.form_data = {:password => @password, :expiring => false}

    response = do_http_request(request)

    if response.code != '200'
      raise LoginFailedException.new("#{response.code}: #{response.body}")
    end

    @session = JSON(response.body).fetch('session')
  end

  # Fire a search against the top-level ArchivesSpace search API
  def search_all_results(query)
    results = []

    page = 1

    loop do
      hits = search(query, page)

      results.concat(hits['results'])

      if hits['last_page'] == page
        break
      else
        page += 1
      end
    end

    results
  end

  def build_url(path, params = {})
    result = URI.join(@url, path)
    result.query = URI.encode_www_form(params)
    result
  end

  def do_http_request(request)
    url = request.uri

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true if url.scheme == 'https'

    request['X-ArchivesSpace-Session'] = @session

    http.request(request)
  end

end
