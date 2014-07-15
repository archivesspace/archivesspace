module FileEmbedHelper

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
