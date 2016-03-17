module ExportHelper
  
  def csv_response(request_uri, params = {} )
        self.response.headers["Content-Type"] = "text/csv" 
        self.response.headers["Content-Disposition"] = "attachment; filename=#{Time.now.to_i}.csv"
        self.response.headers['Last-Modified'] = Time.now.ctime.to_s 
        params["dt"] = "csv" 
        self.response_body = Enumerator.new do |y|
          xml_response(request_uri, params) do |chunk, percent|
            y << chunk if !chunk.blank?
          end
        end 
  end
  
  def xml_response(request_uri, params = {})

    JSONModel::HTTP::stream(request_uri, params) do |res|
      size, total = 0, res.header['Content-Length'].to_i
      res.read_body do |chunk|
        size += chunk.size
        percent = total > 0 ? ((size * 100) / total) : 0
        yield chunk, percent
      end
    end

  end


end
    
