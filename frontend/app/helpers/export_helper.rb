module ExportHelper

  def csv_response(request_uri, params = {}, filename_prefix = '')
    self.response.headers["Content-Type"] = "text/csv"
    self.response.headers["Content-Disposition"] = "attachment; filename=#{filename_prefix}#{Time.now.to_i}.csv"
    self.response.headers['Last-Modified'] = Time.now.ctime.to_s
    params["dt"] = "csv"
    self.response_body = Enumerator.new do |y|
      xml_response(request_uri, params) do |chunk, percent|
        y << chunk if !chunk.blank?
      end
    end
  end

  #ANW-1364: method to generate a CSV from a SearchResultData object as commonly accessible in staff interface controllers
  def csv_response_from_search_result_data(search_result_data, filename_prefix = '')
    self.response.headers["Content-Type"] = "text/csv"
    self.response.headers["Content-Disposition"] = "attachment; filename=#{filename_prefix}#{Time.now.to_i}.csv"
    self.response.headers['Last-Modified'] = Time.now.ctime.to_s
    params["dt"] = "csv"

    body = ""
    if search_result_data["results"].any?
      headers = search_result_data["results"].first.keys.reject { |key| key == "jsonmodel_type"}
      body << headers.join(',') + "\n"

      search_result_data["results"].each do |row|
        values = row.values
        values.map! do |v|
          if v.is_a?(Array)
            v.join("; ")
          else
            v
          end
        end

        body << values.join(',') + "\n"
      end
    end

    self.response_body = body
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
