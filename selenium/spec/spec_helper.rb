require_relative 'factories'

require_relative "../common"
require_relative '../../indexer/app/lib/realtime_indexer'
require_relative '../../indexer/app/lib/periodic_indexer'

$backend_port = TestUtils::free_port_from(3636)
$frontend_port = TestUtils::free_port_from(4545)
$solr_port = TestUtils::free_port_from(2989)
$backend = "http://localhost:#{$backend_port}"
$frontend = "http://localhost:#{$frontend_port}"
$expire = 30000


$backend_start_fn = proc {

  # for the indexers
  AppConfig[:solr_url] = "http://localhost:#{$solr_port}"

  pid = TestUtils::start_backend($backend_port,
                           {
                             :frontend_url => $frontend,
                             :solr_port => $solr_port,
                             :session_expire_after_seconds => $expire,
                             :realtime_index_backlog_ms => 600000
                           })

  AppConfig[:backend_url] = $backend

  pid

}

$frontend_start_fn = proc {
  pid = TestUtils::start_frontend($frontend_port, $backend)

  pid
}

module RSpecClassHelpers

  def xdescribe(*args)
  end
end


module ASpaceMethods

  def set_repo(repo)
    if repo.respond_to?(:uri)
      set_repo(repo.uri)
    elsif repo.is_a?(String) && repo.match(/^\/repositories\/\d+/)
      set_repo(JSONModel(:repository).id_for(repo))
    else
      JSONModel.set_repository(repo)
    end
  end


  def do_http_request(url, req)

    req['X-ArchivesSpace-Session'] = @current_session

    Net::HTTP.start(url.host, url.port) do |http|
      http.read_timeout = 1200
      http.request(req)
    end
  end


  def backend_login
    if @current_session
      return @current_session
    end

    username = "admin"
    password = "admin"

    url = URI.parse($backend + "/users/#{username}/login")

    request = Net::HTTP::Post.new(url.request_uri)
    request.set_form_data("expiring" => "false",
                          "password" => password)

    response = do_http_request(url, request)

    if response.code == '200'
      auth = ASUtils.json_parse(response.body)

      @current_session = auth['session']
      JSONModel::HTTP.current_backend_session = auth['session']

    else
      raise "Authentication to backend failed: #{response.body}"
    end
  end


  def run_index_round
    if ENV['ASPACE_INDEXER_URL']
      url = URI.parse(ENV['ASPACE_INDEXER_URL'] + "/run_index_round")

      request = Net::HTTP::Post.new(url.request_uri)
      request.content_length = 0

      tries = 5

      begin

        response = do_http_request(url, request)

        response.code
      rescue Timeout::Error
        tries -= 1
        retry if tries > 0
      end

    else
      $last_sequence ||= 0
      $last_sequence = $indexer.run_index_round($last_sequence)
    end
  end

  def run_periodic_index
    if ENV['ASPACE_INDEXER_URL']
      url = URI.parse(ENV['ASPACE_INDEXER_URL'] + "/run_periodic_index")

      request = Net::HTTP::Post.new(url.request_uri)
      request.content_length = 0

      response = do_http_request(url, request)

      response.code
    else
      $period.run_index_round
    end
  end


  def run_all_indexers
    run_index_round
    run_periodic_index
  end
end


module JSTreeHelperMethods

  class JSNode
    def initialize(obj)
      @obj = obj
    end

    def li_id
      "#{@obj.jsonmodel_type}_#{@obj.class.id_for(@obj.uri)}"
    end

    def a_id
      "#{self.li_id}_anchor"
    end

  end


  def js_node(obj)
    JSNode.new(obj)
  end
end


include FactoryGirl::Syntax::Methods

RSpec.configure do |config|

  config.fail_fast = false

  config.expect_with(:rspec) do |c|
    c.syntax = [:should, :expect]
  end

  config.include ASpaceMethods
  config.include RepositoryHelperMethods
  config.include JSTreeHelperMethods
  config.include FactoryGirl::Syntax::Methods
  config.extend RSpecClassHelpers
  config.verbose_retry = true

  config.before(:suite) do
    selenium_init($backend_start_fn, $frontend_start_fn)
    SeleniumFactories.init
    if !ENV['ASPACE_INDEXER_URL'] # runs indexers in the same thread as the tests
      $indexer = RealtimeIndexer.new($backend, nil)
      $period = PeriodicIndexer.new
    end
  end

  config.after(:suite) do
    report_sleep
    cleanup
  end

end
