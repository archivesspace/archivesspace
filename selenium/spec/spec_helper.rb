require_relative 'factories.rb'

require_relative "../common"
require_relative '../../indexer/app/lib/realtime_indexer'
require_relative '../../indexer/app/lib/periodic_indexer'



$backend_port = TestUtils::free_port_from(3636)
$frontend_port = TestUtils::free_port_from(4545)
$solr_port = TestUtils::free_port_from(2989)
$backend = "http://localhost:#{$backend_port}"
$frontend = "http://localhost:#{$frontend_port}"
$expire = 300


$backend_start_fn = proc {

  # for the indexers
  AppConfig[:solr_url] = "http://localhost:#{$solr_port}"

  TestUtils::start_backend($backend_port,
                           {
                             :frontend_url => $frontend,
                             :solr_port => $solr_port,
                             :session_expire_after_seconds => $expire,
                             :realtime_index_backlog_ms => 600000
                           })

  AppConfig[:backend_url] = $backend

}

$frontend_start_fn = proc {
  TestUtils::start_frontend($frontend_port, $backend)
}

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
    @last_sequence ||= 0
    @last_sequence = @indexer.run_index_round(@last_sequence)
  end

  def run_periodic_index
    @period.run_index_round
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

  config.include ASpaceMethods
  config.include RepositoryHelperMethods
  config.include JSTreeHelperMethods
  config.include FactoryGirl::Syntax::Methods
  # config.formatter = :documentation

  config.before(:suite) do

    selenium_init($backend_start_fn, $frontend_start_fn)
    SeleniumFactories.init
  end

  config.before(:all) do
    @indexer = RealtimeIndexer.new($backend, nil)
    @period = PeriodicIndexer.new
  end

  config.after(:suite) do
    report_sleep
    cleanup
  end

end
