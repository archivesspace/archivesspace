#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'net/http'

Dir.chdir(File.dirname(__FILE__))

$port = 3434;
$url = "http://localhost:#{$port}";
$me = Time.now.to_i


def url(uri)
  URI("#{$url}#{uri}")
end


def do_post(s, url)
  Net::HTTP.start(url.host, url.port) do |http|
    req = Net::HTTP::Post.new(url.request_uri)
    req.body = s

    r = http.request(req)

    {:body => JSON(r.body), :status => r.code}
  end
end


def do_get(url)
  Net::HTTP.start(url.host, url.port) do |http|
    req = Net::HTTP::Get.new(url.request_uri)
    r = http.request(req)

    {:body => JSON(r.body), :status => r.code}
  end
end



def fail(msg, response)
  raise "FAILURE: #{msg} (#{response.inspect})"
end


def run_tests

  puts "Create a repository"
  r = do_post(JSON(:repo_code => "test#{$me}",
                   :description => "integration test repository"),
              url("/repositories"))

  repo_id = r[:body]["id"] or fail("Repository creation", r)


  puts "Create an accession"
  r = do_post(JSON(:id_0 => "test#{$me}",
                   :title => "integration test accession",
                   :accession_date => "2011-01-01"),
              url("/repositories/#{repo_id}/accessions"));

  acc_id = r[:body]["id"] or fail("Accession creation", r)


  puts "Request the accession"
  r = do_get(url("/repositories/#{repo_id}/accessions/#{acc_id}"));

  r[:body]["title"] =~ /integration test accession/ or
    fail("Accession fetch", r)


  puts "Create a collection"
  r = do_post(JSON(:title => "integration test collection"),
              url("/repositories/#{repo_id}/collections"))

  coll_id = r[:body]["id"] or fail("Collection creation", r)


  puts "Create a subject"
  r = do_post(JSON(:term => "Some term #{$me}",
                   :term_type => "Function",
                   :vocabulary => "/vocabularies/1"),
              url("/subjects"))

  subject_id = r[:body]["id"] or fail("Subject creation", r)


  puts "Create an archival object"
  r = do_post(JSON(:ref_id => "test#{$me}",
                   :title => "integration test archival object",
                   :subjects => ["/subjects/#{subject_id}"]),
              url("/repositories/#{repo_id}/archival_objects"));

  ao_id = r[:body]["id"] or fail("Archival Object creation", r)


  puts "Retrieve the archival object with subjects resolved"
  r = do_get(url("/repositories/#{repo_id}/archival_objects/#{ao_id}?resolve[]=subjects"))
  r[:body]["subjects"][0]["term"] == "Some term #{$me}" or
    fail("Archival object fetch", r)


  puts "Add the archival object to a collection"
  # Note: you could also do this by updating the AO directly
  r = do_post(JSON(:archival_object => "/repositories/#{repo_id}/archival_objects/#{ao_id}",
                   :children => []),
              url("/repositories/#{repo_id}/collections/#{coll_id}/tree"));

  r[:body]["status"] == "Updated" or fail("Add archival object to collection", r)


  puts "Verify that the archival object is now in the collection"
  r = do_get(url("/repositories/#{repo_id}/archival_objects/#{ao_id}"))
  r[:body]["collection"] == "/repositories/#{repo_id}/collections/#{coll_id}" or
    fail("Archival object in collection", r)

end



def main

  # start the backend
  server = Process.spawn("../build/run", "devserver:integration",
                         "-Daspace.port=#{$port}",
                         "-Daspace_integration_test=1")


  while true
    begin
      Net::HTTP.get(URI($url))
      break
    rescue
      # Keep trying
      # puts "Waiting for backend (#{$!.inspect})"
      sleep(5)
    end
  end

  status = 0
  begin
    run_tests
    puts "ALL OK"
  rescue
    puts "TEST FAILED: #{$!}"
    status = 1
  end

  Process.kill(15, server)
  begin
    Process.waitpid(server)
  rescue
    # Already dead.
  end

  exit(status)
end


main
