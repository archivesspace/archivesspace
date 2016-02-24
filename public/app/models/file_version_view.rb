class FileVersionView

  def initialize(record)
    @record = record
  end


  def [](k)
    result = @record[k]

    if !result
      m = "#{k}".intern
      result = if self.respond_to?(m)
                 self.send(m)
               end
    end

    result
  end

  def uri
    begin
      uri = @record['file_uri'].gsub(/\\/, '/' ) # bit of a hack for windows uri 
      uri = "file:///#{uri}" unless uri.match(/^(http|file|)/) 
      @uri ||= URI(uri)
    rescue URI::InvalidURIError => e
      nil
    end
  end

  def embed
    if %w(jpeg gif).include?(@record['file_format_name']) && 
        uri.scheme =~ /http/ && 
        @record['file_size_bytes'].to_i < 512001

      true
    else
      false
    end
  end

  def embed_type
    if embed
      :image
    else
      nil
    end
  end
end
