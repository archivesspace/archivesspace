require 'net/http'
require 'uri'
require 'thread'
require 'asutils'


# This class provides access to the basic ArchivesSpace API endpoints.  A single
# instance will be shared between all running request threads, so it should be
# thread safe!
#
class ArchivesSpaceClient

  LOGIN_TIMEOUT_SECONDS = 10

  DEFAULT_SEARCH_OPTS = {
    'publish' => true,
    'page_size' => AppConfig[:pui_search_results_page_size],
    'hl' => true
  }

  def self.init
    @instance = self.new
  end

  def self.instance
    @instance
  end

  def initialize(archivesspace_url: AppConfig[:backend_url],
                 username: AppConfig[:public_username],
                 password: AppConfig[:public_user_secret])
    @url = archivesspace_url
    @username = username
    @password = password

    @login_mutex = Mutex.new

    @session = nil
  end

  def list_repositories
    repos = {}
    results = search_all_results("primary_type:repository")

    results.map { |result|
      Repository.from_json(ASUtils.json_parse(result['json']))
    }
      .each { |r| repos[r['uri']] = r }
    repos
  end

  def search(query, page = 1, search_opts = {})
    search_opts = DEFAULT_SEARCH_OPTS.merge(search_opts)
    url = build_url('/search', search_opts.merge(:q => query, :page => page))
    results = do_search(url)

    SolrResults.new(results, search_opts)
  end

  # handles multi-line searching
  def advanced_search(base, page = 1, search_opts = {})
    search_opts = DEFAULT_SEARCH_OPTS.merge(search_opts)
    url = build_url(base, search_opts.merge(:page => page))
    results = do_search(url)

    SolrResults.new(results)
  end

  # calls the '/search/records' endpoint
  def search_records(record_list, search_opts = {}, full_notes = false)
    search_opts = DEFAULT_SEARCH_OPTS.merge(search_opts)

    url = build_url('/search/records', search_opts.merge("uri[]" => record_list))
    results = do_search(url)

    # Ensure that the order of our results matches the order of `record_list`
    results['results'] = results['results'].sort_by {|result| record_list.index(result.fetch('uri'))}

    SolrResults.new(results, search_opts, full_notes)
  end

  def get_raw_record(uri, search_opts = {})
    search_opts = DEFAULT_SEARCH_OPTS.merge(search_opts)
    url = build_url('/search/records', search_opts.merge("uri[]" => ASUtils.wrap(uri)))
    results = do_search(url)

    raise RecordNotFound.new if results.fetch('results', []).empty?

    ASUtils.json_parse(results.fetch('results').fetch(0).fetch('json'))
  end

  def get_record(uri, search_opts = {})
    results = search_records(ASUtils.wrap(uri), search_opts, full_notes = true)

    raise RecordNotFound.new if results.empty?

    results.first
  end

  def search_repository( base, repo_id, page = 1, search_opts = {})
    search_opts = DEFAULT_SEARCH_OPTS.merge(search_opts)

    url = build_url(base, search_opts.merge(:page => page))
    results = do_search(url)

    SolrResults.new(results, search_opts)
  end

  # calls the '/search/published_tree' endpoint
  def get_tree(node_uri)
    tree = {}
    url =  build_url('/search/published_tree', {:node_uri => node_uri})
    begin
      results = do_search(url, true)
      tree = ASUtils.json_parse(results['tree_json'])
    rescue RequestFailedException => error
      Rails.logger.error("Tree search failed on #{node_uri} : #{error}")
    end
    tree
  end

  def get_types_counts(record_type_list, repo_uri = nil)
    opts = {"record_types[]" => record_type_list}
    opts["repo_uri"] = repo_uri if repo_uri
    url = build_url('/search/record_types_by_repository', opts)
    results = do_search(url)
  end

  def get_repos_sublist(uri, type, search_opts = {})
    search_opts = DEFAULT_SEARCH_OPTS.merge(search_opts)
    search_opts = search_opts.merge({"q" => "(used_within_published_repository:\"#{uri}\" AND publish:true AND types:pui_#{type})"})
    url = build_url("/search", search_opts)
    results = do_search(url)

    SolrResults.new(results, search_opts)
  end

  private


  # perform the actual search, returning json-ized results,
  # or raising an error
  def do_search(url, use_get = false)
    if use_get
      request = Net::HTTP::Get.new(url)
      Rails.logger.debug("GET Search url: #{url}")
    else
      request = Net::HTTP::Post.new(url)
      Rails.logger.debug("POST Search url: #{url} ")
    end
    response = do_http_request(request)
    if response.code.to_s != '200'
      raise RequestFailedException.new("#{response.code}: #{response.body}")
    end
    results = ASUtils.json_parse(response.body)
    results
  end


  # Authenticate to ArchivesSpace and grab a session token.  If @session isn't
  # nil, this won't do anything.  If multiple threads attempt to log in at the
  # same time, one will do the login and the rest will wait for it.
  def login!
    @login_mutex.synchronize do
      return unless @session.nil?

      path = "/users/#{@username}/login"

      request = Net::HTTP::Post.new(build_url(path))
      request.form_data = {:password => @password, :expiring => false}

      begin
        # Try to log in, but don't block for too long if things aren't looking
        # good.  Better to bail out, fail the request and let a subsequent
        # request retry.
        response = do_http_request(request,
                                   :open_timeout => LOGIN_TIMEOUT_SECONDS,
                                   :read_timeout => LOGIN_TIMEOUT_SECONDS,
                                   :skip_login => true)

        if response.code != '200'
          raise LoginFailedException.new("#{response.code}: #{response.body}")
        end

        @session = ASUtils.json_parse(response.body).fetch('session')
      rescue
        raise LoginFailedException.new($!.message)
      end
    end
  end

  # Fire a search against the top-level ArchivesSpace search API
  def search_all_results(query)
    results = []

    page = 1

    loop do
      hits = search(query, page)

      results.concat(hits['results'])

      if hits['last_page'] == page || hits['last_page'] == 0
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

  MAX_HTTP_RETRIES = 10

  def do_http_request(request, http_opts = {})
    url = request.uri

    if !http_opts[:skip_login] && @session.nil?
      # We're going to need a session to complete this request.  Get one first.
      login!
    end

    if http_opts[:retry_count] && http_opts[:retry_count] >= MAX_HTTP_RETRIES
      raise RequestFailedException.new("Hit maximum retry count on request")
    end

    Net::HTTP.start(url.host, url.port,
                    http_opts) do |http|
      http.use_ssl = true if url.scheme == 'https'

      request['X-ArchivesSpace-Session'] = @session

      response = http.request(request)

      if response.code == '412'
        # Our session expired
        if http_opts[:skip_login]
          # We've been here before.  Don't try to login within a login.
          raise RequestFailedException.new("Successive login failures")
        else
          @session = nil
          login!

          http_opts[:retry_count] ||= 0
          http_opts[:retry_count] += 1

          # Retry with the new session
          return do_http_request(request, http_opts)
        end
      end

      response
    end
  end

  # process any filter information; at the moment, we add it to the query; later, hopefully, an fq
  def process_filters(search_opts = {})
    filter_str = ''
    if search_opts['filter']
      search_opts['filter'].each do |f|
        filter_str = "#{filter_str} AND #{f}"
      end
      search_opts.delete('filter')
    end
    filter_str
  end
end
