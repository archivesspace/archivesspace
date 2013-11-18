module ExportHelper
  
  def xml_response(request_uri)

    JSONModel::HTTP::stream(request_uri, {}) do |res|
      size, total = 0, res.header['Content-Length'].to_i
      puts "+++++++++++++++ resp: #{res.to_hash}"
      res.read_body do |chunk|
        size += chunk.size
        percent = total > 0 ? ((size * 100) / total) : 0
        yield chunk, percent
      end
    end

  end

end
    
