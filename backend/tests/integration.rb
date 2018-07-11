#!/usr/bin/env ruby

require 'rubygems'
require 'tmpdir'
require 'tempfile'
require 'json'
require 'net/http'
require 'test_utils'
require_relative '../../indexer/app/lib/periodic_indexer.rb'
require 'ladle'
require 'simplecov'
require 'active_support/inflector'


$solr_port = 2999
$ldap_port = 3897
$port = 3434
$url = "http://localhost:#{$port}"
$me = Time.now.to_i
$expire = 3

def url(uri)
  URI("#{$url}#{uri}")
end


def do_post(s, url, content_type = 'application/x-www-form-urlencoded')
  ASHTTP.start_uri(url) do |http|
    req = Net::HTTP::Post.new(url.request_uri)
    req.body = s
    req['Content-Type'] = content_type
    req["X-ARCHIVESSPACE-SESSION"] = @session if @session

    r = http.request(req)
    {:body => JSON(r.body), :status => r.code}
  end
end


def do_get(url, raw = false)
  ASHTTP.start_uri(url) do |http|
    req = Net::HTTP::Get.new(url.request_uri)
    req["X-ARCHIVESSPACE-SESSION"] = @session if @session
    r = http.request(req)

    if raw
      r
    else
      {:body => JSON(r.body), :status => r.code}
    end
  end
end


def do_delete(url)
  ASHTTP.start_uri(url) do |http|
    req = Net::HTTP::Delete.new(url.request_uri)
    req["X-ARCHIVESSPACE-SESSION"] = @session if @session
    http.request(req)
  end
end



def fail(msg, response)
  raise "FAILURE: #{msg} (#{response.inspect})"
end


def start_ldap
  Ladle::Server.new(:tmpdir => Dir.tmpdir,
                    :port => $ldap_port,
                    :ldif => File.absolute_path("tests/data/aspace.ldif"),
                    :java_bin => ["java", "-Xmx64m"],
                    :domain => "dc=archivesspace,dc=org").tap do |s|
    s.start
  end
end



def run_tests(opts)

  test_user = "testuser_#{Time.now.to_i}_#{$$}"

  puts "Create a test user"
  r = do_post({:username => test_user, :name => test_user}.to_json,
              url("/users?password=testuser"),
              'text/json')
  r[:body]['status'] == 'Created' or fail("Test user creation", r)


  puts "Check local username completion"
  r = do_get(url("/users/complete?query=#{test_user}"))
  r[:body].first == test_user or fail("Local username completion", r)

  puts "Check local username completion excludes system users"
  r = do_get(url("/users/complete?query=admin"))
  !r[:body].include?("admin") or fail("Local username completion excludes system users", r)


  puts "Create an admin session"
  r = do_post(URI.encode_www_form(:password => "admin"),
              url("/users/admin/login?expiring=false"))

  @session = r[:body]["session"] or fail("Admin login", r)

  puts "Create a repository"
  r = do_post({
                :repo_code => "test#{$me}",
                :name => "Test #{$me}",
                :description => "integration test repository #{$$}"
              }.to_json,
              url("/repositories"),
              'text/json')

  repo_id = r[:body]["id"] or fail("Repository creation", r)


  puts "Create a second repository"
  r = do_post({
                :repo_code => "another#{$me}",
                :name => "Another Test #{$me}",
                :description => "another integration test repository #{$$}"
              }.to_json,
              url("/repositories"),
              'text/json')

  second_repo_id = r[:body]["id"] or fail("Second repository creation", r)


  puts "Create an accession"
  r = do_post({
                :id_0 => "test#{$me}",
                :title => "integration test accession #{$$}",
                :accession_date => "2011-01-01"
              }.to_json,
              url("/repositories/#{repo_id}/accessions"),
              'text/json')

  acc_id = r[:body]["id"] or fail("Accession creation", r)


  puts "Request the accession"
  r = do_get(url("/repositories/#{repo_id}/accessions/#{acc_id}"))

  r[:body]["title"] =~ /integration test accession/ or
    fail("Accession fetch", r)



  puts "Create an accession in the second repository"
  r = do_post({
                :id_0 => "another#{$me}",
                :title => "ANOTHER integration test accession #{$$}",
                :external_ids => [{'source' => 'mark', 'external_id' => 'rhubarb'}],
                :accession_date => "2011-01-01"
              }.to_json,
              url("/repositories/#{second_repo_id}/accessions"),
              'text/json')

  r[:body]["id"] or fail("Second accession creation", r)


  puts "Create a subject with no terms"
  r = do_post({
                :source => "local",
                :terms => [],
                :vocabulary => "/vocabularies/1"
              }.to_json,
              url("/subjects"),
              'text/json')
  r[:status] === "400" or fail("Invalid subject check", r)


  puts "Create a subject"
  r = do_post({
                :source => "local",
                  :terms => [
                           :term => "Some term #{$me}",
                           :term_type => "function",
                           :vocabulary => "/vocabularies/1"
                          ],
                :vocabulary => "/vocabularies/1"
              }.to_json,
              url("/subjects"),
              'text/json')

  subject_id = r[:body]["id"] or fail("Subject creation", r)


  puts "Create a resource"
  r = do_post({
                :title => "integration test resource #{$$}",
                :id_0 => "abc123",
                :dates => [ { "date_type" => "single", "label" => "creation", "expression" => "1492"   } ],
                :subjects => [{"ref" => "/subjects/#{subject_id}"}],
                :language => "eng",
                :level => "collection",
                :extents => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}]
              }.to_json,
              url("/repositories/#{repo_id}/resources"),
              'text/json')

  coll_id = r[:body]["id"] or fail("Resource creation", r)


  puts "Create an archival object under a resource"
  r = do_post({
                :ref_id => "test#{$me}",
                :title => "integration test archival object #{$$} - under a resource",
                :subjects => [{"ref" => "/subjects/#{subject_id}"}],
                :resource => {'ref' => "/repositories/#{repo_id}/resources/#{coll_id}"},
                :level => "item"
              }.to_json,
              url("/repositories/#{repo_id}/archival_objects"),
              'text/json')

  ao_id = r[:body]["id"] or fail("Archival Object creation", r)


  puts "Catch reference errors in batch imports"
  r = do_post([{
                :jsonmodel_type => "resource",
                :uri => "/repositories/#{repo_id}/temp_id_1",
                :title => "integration test resource #{$$}",
                :id_0 => "xyz456",
                :subjects => [{"ref" => "/subjects/99999999999999"}],
                :language => "eng",
                :level => "collection",
                :extents => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}]
              }].to_json,
              url("/repositories/#{repo_id}/batch_imports"),
              'text/json')

  r[:body].last["errors"] or fail("Catch reference errors", r)


  puts "Catch references in batch imports before creating records"
  r = do_post([{
                :jsonmodel_type => "resource",
                :uri => "/repositories/#{repo_id}/temp_id_2",
                :title => "integration test resource #{$$}",
                :id_0 => "xyz456",
                :language => "eng",
                :level => "collection",
                :extents => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}]
              }].to_json,
              url("/repositories/#{repo_id}/batch_imports"),
              'text/json')

  r[:body].last["saved"] or fail("Rollback reference errors", r)


  puts "Retrieve the resource with subjects resolved"
  r = do_get(url("/repositories/#{repo_id}/resources/#{coll_id}?resolve[]=subjects"))
  r[:body]["subjects"][0]["_resolved"]["terms"][0]["term"] == "Some term #{$me}" or
    fail("Resource fetch", r)


  if opts[:check_ldap]
    puts "Check LDAP authentication"

    r = do_post(URI.encode_www_form(:password => "wrongpassword"),
                url("/users/marktriggs/login"))

    (r[:status] == '403') or fail("LDAP login with incorrect password", r)


    r = do_post(URI.encode_www_form(:password => ""),
                url("/users/marktriggs/login"))

    (r[:status] == '403') or fail("LDAP login with blank password", r)


    r = do_post(URI.encode_www_form(:password => "testuser"),
                url("/users/marktriggs/login"))

    r[:body]["session"] or fail("LDAP login with correct password", r)


    r = do_get(url(r[:body]["user"]["uri"]))
    (r[:body]['name'] == 'Mark Triggs') or fail("User attributes from LDAP", r)


    puts "Check username completion"
    r = do_get(url("/users/complete?query=mark"))
    r[:body].first == "marktriggs" or fail("LDAP username completion", r)
  end


  puts "Check that search indexing works"
  state = Object.new
  def state.set_last_mtime(*args); end
  def state.get_last_mtime(*args); 0; end

  AppConfig[:backend_url] = $url
  indexer = PeriodicIndexer.get_indexer(state)
  indexer.run_index_round

  r = do_get(url("/repositories/#{repo_id}/search?q=integration+test+accession+#{$$}&page=1"))
  begin
    (Integer(r[:body]['total_hits']) > 0) or fail("Search indexing", r)
  rescue TypeError
    puts "Response: #{r.inspect}"
  end


  puts "Check that search results are repository-scoped"
  # This accession was created in repository #2, so shouldn't be found
  r = do_get(url("/repositories/#{repo_id}/search?q=%22ANOTHER+integration+test+accession+#{$$}%22&page=1"))
  begin
    (Integer(r[:body]['total_hits']) == 0) or fail("Repository scoping", r)
  rescue TypeError
    puts "Response: #{r.inspect}"
  end


  puts "Check that we can search within a record tree"
  r = do_get(url("/repositories/#{repo_id}/search?q=integration+test&root_record=/repositories/#{repo_id}/resources/#{coll_id}&page=1"))
  begin
    # We're expecting 1 hit here even though there are two archival objects that
    # match the query.  The scoping should limit the results to only the one
    # underneath the resource record.
    (Integer(r[:body]['total_hits']) == 1) or fail("Search within record tree", r)
  rescue TypeError
    puts "Response: #{r.inspect}"
  end


  puts "Records can be queried by their external ID"
  r = do_get(url("/by-external-id?eid=rhubarb"), true)
  r.code == '303' or r.code == '300' or fail("fetch by external ID", r)




  puts "It refuses to delete a non-empty repository"
  r = do_get(url("/repositories/#{repo_id}/groups"))
  (r[:body].count > 0) or fail("Groups should not be gone", r)

  puts "Create an expiring admin session"
  r = do_post(URI.encode_www_form(:password => "admin"),
              url("/users/admin/login"))

  @session = r[:body]["session"] or fail("Admin login", r)

  puts "Expire session after a nap"
  sleep $expire + 1
  r = do_get(url("/repositories"))
  r[:body]["code"] == "SESSION_EXPIRED" or fail("Session expiry", r)


  @session = nil
  puts "Check cannot delete record via batch when not authenticated"
  r = do_post(URI.encode_www_form("record_uris[]" => "/repositories/#{repo_id}/accessions/#{acc_id}"), url("/batch_delete"))
  r[:status] == '403' or fail("batch deleting when not authenticated", r)
end


def main

  standalone = true

  if ENV["ASPACE_BACKEND_URL"]
    $url = ENV["ASPACE_BACKEND_URL"]
    standalone = false
  end

  server = nil
  ldap = nil

  if standalone
    # start the backend
    ldap = start_ldap

    # Configure LDAP auth
    config = ASUtils.tempfile('aspace_integration_config')
    config.write <<EOF

AppConfig[:authentication_sources] = [
                                      {
                                        :model => 'LDAPAuth',
                                        :hostname => 'localhost',
                                        :port => 3897,
                                        :base_dn => 'ou=people,dc=archivesspace,dc=org',
                                        :username_attribute => 'uid',
                                        :attribute_map => {:cn => :name}
                                      }
                                     ]

EOF
    config.close

    server = TestUtils::start_backend($port,
                                      {:session_expire_after_seconds => $expire},
                                      config.path)

    TestUtils::wait_for_url("http://localhost:#{$solr_port}/")
  end

  status = 0
  begin
    run_tests(:check_ldap => ldap)
    puts "ALL OK"
  rescue
    puts "TEST FAILED: #{$!}"
    puts $@.join("\n")
    status = 1
  end

  if server
    ldap.stop
    TestUtils::kill(server)
  end

  exit(status)
end


main
