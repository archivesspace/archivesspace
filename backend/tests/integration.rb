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

  ## Create a repository
  r = do_post(JSON(:repo_code => "test#{$me}",
                   :description => "integration test repository"),
              url("/repositories"))

  repo_id = r[:body]["id"] or fail("Repository creation", r)


  ## Create an accession
  r = do_post(JSON(:id_0 => "test#{$me}",
                   :title => "integration test accession",
                   :accession_date => "2011-01-01"),
              url("/repositories/#{repo_id}/accessions"));

  acc_id = r[:body]["id"] or fail("Accession creation", r)


  ## Request the accession
  r = do_get(url("/repositories/#{repo_id}/accessions/#{acc_id}"));

  r[:body]["title"] =~ /integration test accession/ or
    fail("Accession fetch", r)


  ## Create a collection
  r = do_post(JSON(:title => "integration test collection"),
              url("/repositories/#{repo_id}/collections"))

  coll_id = r[:body]["id"] or fail("Collection creation", r)

end



def main

  system("cd ../; build/run devserver -Daspace.port=#{$port} -Daspace_integration_test=1 >/dev/null &")

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

  begin
    run_tests
    puts "ALL OK"
  rescue
    puts "TEST FAILED: #{$!}"
  end

  system("pkill -f 'aspace_integration_test'");
end


main
