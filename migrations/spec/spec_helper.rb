require 'test_utils'
require 'config/config-distribution'
require 'rspec/expectations'
require 'i18n'

$test_mode = true

$standalone = ENV['ASPACE_BACKEND_URL'] ? true : false

if $standalone
  $backend_url = ENV['ASPACE_BACKEND_URL']
else
  $backend_port = TestUtils::free_port_from(3636)
  $backend_url = "http://localhost:#{$backend_port}"
end


$backend_start_fn = proc {
  TestUtils::start_backend($backend_port,
                           {
                             :session_expire_after_seconds => 300,
                             :realtime_index_backlog_ms => 600000,
                             :db_url => AppConfig.demo_db_url
                           })
}

AppConfig[:backend_url] = $backend_url

I18n.load_path += [File.join(File.dirname(__FILE__), "../", "../", "common", "locales", "enums", "#{AppConfig[:locale]}.yml")]


def start_backend
  $backend_pid = $backend_start_fn.call unless $standalone
  response = JSON.parse(`curl -F'password=admin' #{$backend_url}/users/admin/login`)
  session_id = response['session']
  Thread.current[:backend_session] = session_id
end


def stop_backend
    TestUtils::kill($backend_pid) unless $standalone
end


if ENV['COVERAGE_REPORTS'] == 'true'
  require 'aspace_coverage'
  ASpaceCoverage.start('migrations:test')
end

require_relative "../lib/bootstrap"
require_relative "../../backend/app/lib/request_context"

JSONModel::init( { :strict_mode => true, :enum_source => MockEnumSource, :client_mode => true, :url => $backend_url} )

require 'factory_girl'
require_relative 'factories'
include FactoryGirl::Syntax::Methods


def make_test_vocab
  vocab = create(:json_vocab)

  vocab.uri
end

require_relative 'helpers/import_spec_helpers'
require_relative 'helpers/export_spec_helpers'
require_relative 'helpers/marc_export_spec_helpers'
require_relative 'helpers/custom_matchers'


# shortcut xpath method
module SloppyXpath
  def sxp(path)
    ns_path = path.split('/').map {|p| (p.empty? || p =~ /\w+:/) ? p : "xmlns:#{p}"}.join('/')
    self.xpath(ns_path)
  end
end


class Nokogiri::XML::Node
  include SloppyXpath
end

class Nokogiri::XML::NodeSet
  include SloppyXpath
end


def get_note(obj, id)
  obj['notes'].find{|n| n['persistent_id'] == id}
end


def get_notes_by_type(obj, note_type)
  obj['notes'].select{|n| n['type'] == note_type}
end


def get_note_by_type(obj, note_type)
  get_notes_by_type(obj, note_type)[0]
end


def get_subnotes_by_type(obj, note_type)
  obj['subnotes'].select {|sn| sn['jsonmodel_type'] == note_type}
end


def note_content(note)
  if note['content']
    Array(note['content']).join(" ")
  else
    get_subnotes_by_type(note, 'note_text').map {|sn| sn['content']}.join(" ").gsub(/\n +/, "\n")
  end
end


def get_notes_by_string(notes, string)
  notes.select {|note| (note.has_key?('subnotes') && note['subnotes'][0]['content'] == string) \
                    || (note['content'].is_a?(Array) && note['content'][0] == string) }
end


def get_family_by_name(families, famname)
  families.find {|f| f['names'][0]['family_name'] == famname}
end


def get_person_by_name(people, primary_name)
  people.find {|p| p['names'][0]['primary_name'] == primary_name}
end


def get_corp_by_name(corps, primary_name)
  corps.find {|c| c['names'][0]['primary_name'] == primary_name}
end


def translate(enum_path, value)
  enum_path << "." unless enum_path =~ /\.$/
  I18n.t("#{enum_path}#{value}", :default => value)
end
