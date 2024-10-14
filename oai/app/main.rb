require 'rubygems'
require 'sinatra/base'
require 'asutils'
require 'ashttp'

require 'uri'
require 'net/http'

# JRuby 9.3.0.0 introduced more nuanced thread teardowns.
# See: https://github.com/jruby/jruby/pull/6176
# Under the assumption that the thread dump facility is not widely
# relied-upon, we hereby comment it out...
# require 'archivesspace_thread_dump'
# ArchivesSpaceThreadDump.init(File.join(ASUtils.find_base_directory, "thread_dump_oai.txt"))

class ArchivesSpaceOAIServer < Sinatra::Base

  TIMEOUT = 600

  get "/favicon.ico" do
    status 404
  end

  get '/sample' do
    oai_sample_url = URI.join(AppConfig[:backend_url], 'oai_sample')

    ASHTTP.start_uri(oai_sample_url, :open_timeout => TIMEOUT, :read_timeout => TIMEOUT) do |http|
      http_request = Net::HTTP::Get.new(oai_sample_url.request_uri)
      response = http.request(http_request)

      [Integer(response.code), prepare_headers(response.to_hash), response.body]
    end
  end

  get "/*" do
    send_get(request.query_string)
  end

  post "/*" do
    send_get(URI.encode_www_form(params.to_hash))
  end


  def send_get(query_string)
    oai_url = build_oai_url
    oai_url.query = query_string

    ASHTTP.start_uri(oai_url, :open_timeout => TIMEOUT, :read_timeout => TIMEOUT) do |http|
      http_request = Net::HTTP::Get.new(oai_url.request_uri)
      response = http.request(http_request)

      [Integer(response.code), prepare_headers(response.to_hash), response.body]
    end
  end

  def build_oai_url
    URI.join(AppConfig[:backend_url], 'oai')
  end

  def prepare_headers(headers)
    Hash[headers.map {|header, values|
           [header, values.join(' ')]
         }]
  end
end

if $0 == __FILE__
  puts("OAI Dev server starting up...")

  ArchivesSpaceOAIServer.run!(:bind => '0.0.0.0', :port => (ARGV[0] or 4568))
end
