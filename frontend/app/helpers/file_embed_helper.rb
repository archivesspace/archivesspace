module FileEmbedHelper

  SUPPORTED_URL_SCHEMES = ['http', 'https']

  def self.supported_scheme?(scheme)
    SUPPORTED_URL_SCHEMES.include?(scheme)
  end

  def uri_or_string(link)
    # If `link` can be sensibly rendered as a URL, return a URL object.
    begin
      parsed = URI.parse(link)

      if FileEmbedHelper.supported_scheme?(parsed.scheme)
        # Great.  We'll take it.
        return parsed
      end
    rescue URI::InvalidURIError
    end

    # Otherwise, return the verbatim string
    link
  end

  def can_embed?(file_version)
    begin
      uri = URI(file_version['file_uri'])
      if %w(jpeg gif).include?(file_version['file_format_name']) &&
        uri.scheme =~ /http/ &&
        file_version['file_size_bytes'].to_i < 512001
        true
      else
        false
      end
    rescue Exception => ex
      false
    end
  end

end
