require 'json'
require 'net/http'
require 'nokogiri'

module RequestHandler

  attr_reader :token

  def login(user, password)
    url = URI("#{AppConfig[:backend_url]}/users/#{user}/login")
    @token = post(url, { "password" => password })["session"]
    token
  end

  ##### REQUEST HANDLING

  def get(url, format = :json)
    req = Net::HTTP::Get.new(url.request_uri)
    request url, req, format
  end

  def post(url, params, body = nil)
    req = Net::HTTP::Post.new(url.request_uri)
    req.set_form_data(params)
    req.body = body if body
    request url, req
  end

  def request(url, req, format = :json)
    req['X-ArchivesSpace-Session'] = @token
    Net::HTTP.start(url.host, url.port) do |http|
      response = http.request(req)
      if response.code =~ /^4/
        raise "Request error for #{url}: #{response.message}"
      end
      if format == :json
        JSON.parse response.body
      elsif format == :xml
        Nokogiri::XML response.body
      else
        raise "Request error unrecognized format for #{url}: #{format}"
      end
    end
  end

end
