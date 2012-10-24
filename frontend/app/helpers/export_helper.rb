require 'net/http'

module ExportHelper
  
  def xml_response(request_uri)
    
    url = URI(request_uri)
    req = Net::HTTP::Get.new(url.request_uri)
    req['X-ArchivesSpace-Session'] = Thread.current[:backend_session]
    
    
    Net::HTTP.start(url.host, url.port) do |http|
      response = http.request(req) do |res|
        size, total = 0, res.header['Content-Length'].to_i
        res.read_body do |chunk|
          size += chunk.size
          percent = (size * 100) / total
          yield chunk, percent
        end
      end
    end
  end
end
    