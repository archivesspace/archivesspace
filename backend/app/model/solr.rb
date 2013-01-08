require 'uri'
require 'net/http'


class Solr

  def self.solr_url
    URI.parse(AppConfig[:solr_url])
  end


  def self.search(query, page, page_size, repo_id,
                  record_types = nil, show_suppressed = false,
                  excluded_ids = [])
    url = solr_url

    opts = {
      :q => query,
      :wt => "json",
      :defType => "edismax",
      :qf => "title^2 fullrecord",
      :start => (page - 1) * page_size,
      :rows => page_size,
    }.to_a

    if repo_id
      opts << [:fq, "repository:\"/repositories/#{repo_id}\" OR repository:global"]
    end

    if record_types
      query = record_types.map { |type| "\"#{type}\"" }.join(' OR ')
      opts << [:fq, "types:(#{query})"]
    end

    if !show_suppressed
      opts << [:fq, "suppressed:false"]
    end

    if excluded_ids && !excluded_ids.empty?
      query = excluded_ids.map { |id| "\"#{id}\"" }.join(' OR ')
      opts << [:fq, "-id:(#{query})"]
    end

    url.path = "/select"
    url.query = URI.encode_www_form(opts)

    req = Net::HTTP::Get.new(url.request_uri)

    Net::HTTP.start(url.host, url.port) do |http|
      solr_response = http.request(req)

      if solr_response.code == '200'
        json = JSON.parse(solr_response.body, :max_nesting => false)

        result = {}

        result['first_page'] = 1
        result['last_page'] = (json['response']['numFound'] / page_size.to_f).floor + 1
        result['this_page'] = (json['response']['start'] / page_size) + 1

        result['offset_first'] = json['response']['start'] + 1
        result['offset_last'] = [(json['response']['start'] + page_size), json['response']['numFound']].min
        result['total_hits'] = json['response']['numFound']

        result['results'] = json['response']['docs'].map {|doc|
          doc['uri'] = doc['id']
          doc['jsonmodel_type'] = doc['primary_type']
          doc
        }

        return result
      else
        raise "Solr search failed: #{solr_response.body}"
      end
    end
  end

end
