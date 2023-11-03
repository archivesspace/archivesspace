require 'rspec'
require 'ashttp'
require 'spec/lib/jsonmodel_factories'
require 'vcr'
require 'webmock/rspec'
require 'test_utils'

AppConfig[:backend_url] = ENV['ASPACE_TEST_BACKEND_URL'] || "http://localhost:#{TestUtils::free_port_from(3636)}"

# VCR allows the tests to be self-contained - there is no need
# to spin up a backend in a CI environment or in development environment
# unless you are authoring or revising tests. In that case  you can simply spin
# up a new backend with a clean database and delete any yml files in 'cassettes'.
# Then commit your new cassette along with your test changes.
VCR.configure do |c|
  c.cassette_library_dir = File.join(File.dirname(__FILE__), 'cassettes')
  c.hook_into :webmock
  c.allow_http_connections_when_no_cassette = true
  c.register_request_matcher :uri_ignore_backend_host_and_port do |request_1, request_2|
    uri1, uri2 = URI(request_1.uri), URI(request_2.uri)
    uri1.request_uri == uri2.request_uri
  end
end


RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include JSONModel
  # Take advantage of JSONModel.init_args raising error when
  # JSONModel has not been set up with the backend
  config.around(:each) do |example| #
    VCR.use_cassette('indexer_spec', record: :new_episodes, match_requests_on: [:method, :uri_ignore_backend_host_and_port]) do |cassette|
      begin
        JSONModel.init_args
      rescue
        JSONModel::init_with_factories(url: AppConfig[:backend_url])
        repo = create(:json_repository)
        JSONModel.set_repository(repo.id)
      end
      example.run
    end
  end
end
