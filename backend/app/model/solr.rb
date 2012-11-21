require 'uri'
require 'net/http'


class Solr

  PAGE_SIZE = 10

  def self.solr_url
    URI.parse(AppConfig[:solr_url])
  end


  def self.search(query, record_type = nil)
    url = solr_url

    opts = {
      :q => query,
      :wt => "json",
      :defType => "edismax",
      :qf => "title^2 fullrecord"
    }

    if record_type
      opts[:fq] = "type:\"#{record_type}\""
    end


    url.path = "/select"
    url.query = URI.encode_www_form(opts)

    req = Net::HTTP::Get.new(url.request_uri)

    Net::HTTP.start(url.host, url.port) do |http|
      solr_response = http.request(req)

      if solr_response.code == '200'
        json = JSON.parse(solr_response.body)

        result = {}

        result['first_page'] = 1
        result['last_page'] = (json['response']['numFound'] / PAGE_SIZE.to_f).floor + 1
        result['this_page'] = (json['response']['start'] / PAGE_SIZE) + 1

        result['results'] = json['response']['docs']

        return result
      else
        raise "Solr search failed: #{solr_response.body}"
      end
    end
  end

end
