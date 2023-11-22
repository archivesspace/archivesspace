# frozen_string_literal: true

require 'ashttp'
require "uri"
require "json"
require "digest"
require "rspec"
require 'rspec/retry'
require 'test_utils'
require 'config/config-distribution'
require 'securerandom'
require 'axe-rspec'
require 'nokogiri'

require_relative '../../indexer/app/lib/pui_indexer'

if ENV['COVERAGE_REPORTS'] == 'true'
  require 'aspace_coverage'
  ASpaceCoverage.start('public:test', 'rails')
end

require 'aspace_gems'

$server_pids = []
$expire = 30000
AppConfig[:backend_url] = ENV['ASPACE_TEST_BACKEND_URL'] || "http://localhost:#{TestUtils::free_port_from(3636)}"
AppConfig[:db_url] = ENV['ASPACE_TEST_DB_URL'] || AppConfig[:db_url]
AppConfig[:solr_url] = ENV['ASPACE_TEST_SOLR_URL'] || AppConfig[:solr_url]
AppConfig[:pui_hide][:record_badge] = false
AppConfig[:arks_enabled] = true


$backend_start_fn = proc {
  TestUtils::start_backend(URI(AppConfig[:backend_url]).port,
                           {
                             :session_expire_after_seconds => $expire,
                             :realtime_index_backlog_ms => 600000,
                             :db_url => AppConfig[:db_url]
                           })
}

module IndexTestRunner
  def run_indexers
    @@period ||= PeriodicIndexer.new(AppConfig[:backend_url])
    @@pui ||= PUIIndexer.new(AppConfig[:backend_url])
    @@period.run_index_round
    @@pui.run_index_round
  end
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
include FactoryBot::Syntax::Methods
include IndexTestRunner

def setup_test_data
  repo = create(:repo, :repo_code => "test_#{Time.now.to_i}", publish: true)
  set_repo repo

  digi_obj = create(:digital_object, title: 'Born digital', publish: true)

  subject = create(:subject, terms: [build(:term, term: 'Term 1')])

  subject2 = create(:subject, terms: [build(:term, {term: 'Term 1', term_type: 'temporal'}), build(:term, term: 'Term 2')])

  create(:agent_person,
         names: [build(:name_person,
                       name_order: 'direct',
                       primary_name: "Agent",
                       rest_of_name: "Published #{Time.now.to_i}",
                       sort_name: "Published Agent",
                       number: nil,
                       dates: nil,
                       qualifier: nil,
                       fuller_form: nil,
                       prefix: nil,
                       title: nil,
                       suffix: nil)],
         dates_of_existence: nil,
         publish: true)

  pa = create(:accession, title: "Published Accession", publish: true, instances: [
    build(:instance_digital, digital_object: { 'ref' => digi_obj.uri })
  ])
  ua = create(:accession, title: "Unpublished Accession", publish: false, instances: [
    build(:instance_digital, digital_object: { 'ref' => digi_obj.uri })
  ])

  create(:accession_with_deaccession, title: "Published Accession with Deaccession")
  create(:accession, title: "Accession for Phrase Search")


  create(:accession, title: "Accession with Relationship",
                     publish: true,
                     related_accessions: [
                        build(:accession_parts_relationship, ref: pa.uri),
                        build(:accession_parts_relationship, ref: ua.uri)
                     ])

  create(:accession, title: "Accession with Deaccession", publish: true,
    deaccessions: [build(:json_deaccession)])

  create(:accession, title: "Accession with Lang/Script",
                     publish: true,
                     language: 'eng',
                     script: 'Latn')

  create(:accession, title: "Accession with Lang Material Note",
                     publish: true,
                     lang_materials: [
                        build(:lang_material_with_note)
                     ])

  create(:accession, title: "Accession without Lang Material Note",
                     publish: true,
                     lang_materials: [
                        build(:lang_material)
                     ])

  resource = create(:resource, title: "Published Resource",
                    publish: true,
                    is_finding_aid_status_published: false,
                    finding_aid_status: "in_progress",
                    instances: [build(:instance_digital)],
                    subjects: [{'ref' => subject.uri}])

  create(:resource, title: "Resource with Deaccession", publish: true,
    deaccessions: [build(:json_deaccession)])

  create(:resource, title: "Resource with Accession", publish: true,
    related_accessions: [{'ref' => pa.uri}])


  classification = create(:classification, :title => "My Special Classification")
  create(:digital_object, title: "Digital Object With Classification",
                          classifications: [{'ref' => classification.uri}])

  aos = (0..5).map do
    create(:archival_object,
           title: "Published Archival Object", resource: { 'ref' => resource.uri }, publish: true)
  end

  unpublished_resource = create(:resource, title: "Unpublished Resource", publish: false)
  unp_aos = (0..5).map do
    create(:archival_object,
           resource: { 'ref' => unpublished_resource.uri }, publish: true)
  end
  create(:resource, title: "Resource for Phrase Search", publish: true)
  create(:resource, title: "Search as Phrase Resource", publish: true)


  linked_agent_1 = create(:agent_person,
         names: [build(:name_person,
                       primary_name: "Linked Agent 1",
                       sort_name: "Linked Agent 1")],
         publish: true)

  linked_agent_2 = create(:agent_person,
         names: [build(:name_person,
                       primary_name: "Linked Agent 2",
                       sort_name: "Linked Agent 2")],
         publish: true)


  create(:resource, title: "Resource with Agents", publish: true, linked_agents:
    [
      {'role' => 'creator', 'ref' => linked_agent_1.uri},
      {'role' => 'source', 'ref' => linked_agent_2.uri}
    ]
  )

  create(:resource, title: "Resource with Subject",
                    publish: true,
                    instances: [build(:instance_digital)],
                    subjects: [{'ref' => subject2.uri}])

  resource_with_scope = create(:resource_with_scope, title: "Resource with scope note", publish: true)
  aos = (0..5).map do
    create(:archival_object,
           resource: { 'ref' => resource_with_scope.uri }, publish: true)
  end

  resource_with_tree = create(:resource, title: "Resource with digital instance", publish: true)
  create(:archival_object,
    title: "AO with DO",
    resource: { 'ref' => resource_with_tree.uri },
    instances: [build(:instance_digital)],
    publish: true
  )

  create(:archival_object,
    title: "AO with DO unpublished",
    resource: { 'ref' => resource_with_tree.uri },
    instances: [build(:instance_digital)],
    publish: false
  )

  create(:archival_object,
    title: "AO without DO",
    resource: { 'ref' => resource_with_tree.uri },
    publish: true
  )

  create(:digital_object_component,
         publish: true,
         component_id: '12345')
end

RSpec.configure do |config|

  config.include FactoryBot::Syntax::Methods
  config.include BackendClientMethods
  config.include IndexTestRunner

  # show retry status in spec process
  config.verbose_retry = true
  # Try thrice (retry twice)
  config.default_retry_count = ENV['ASPACE_TEST_RETRY_COUNT'] || 3

  [:controller, :view, :request].each do |type|
    config.include ::Rails::Controller::Testing::TestProcess, :type => type
    config.include ::Rails::Controller::Testing::TemplateAssertions, :type => type
    config.include ::Rails::Controller::Testing::Integration, :type => type
  end

  config.before(:suite) do
    if ENV['ASPACE_TEST_BACKEND_URL']
      puts "Running tests against #{AppConfig[:backend_url]}"
    else
      puts "Starting backend using #{AppConfig[:backend_url]}"
      $server_pids << $backend_start_fn.call
    end
    ArchivesSpaceClient.init
    $admin = BackendClientMethods::ASpaceUser.new('admin', 'admin')
    JSONModel::init(:client_mode => true,
                    :url => AppConfig[:backend_url],
                    :priority => :high)

    require_relative 'factories'
    AspaceFactories.init
    unless ENV['ASPACE_TEST_SKIP_FIXTURES']
      setup_test_data
    end
    run_indexers
  end

  config.after(:suite) do
    $server_pids.each do |pid|
      TestUtils::kill(pid)
    end
    # For some reason we have to manually shutdown mizuno for the test suite to
    # quit.
    Rack::Handler.get('mizuno').instance_variable_get(:@server) ? Rack::Handler.get('mizuno').instance_variable_get(:@server).stop : next
  end
end

FIXTURES_DIR = File.join(File.dirname(__FILE__), "fixtures")
