module FileEmbedHelper

  def can_embed?(file_version)
    is_image = %w(jpeg gif).include?(file_version['file_format_name'])
    is_allowed_scheme = FileURI.allowed_scheme?(file_version['file_uri'])
    is_small_enough = file_version['file_size_bytes'].to_i < 512001

    is_image && is_allowed_scheme && is_small_enough
  end
end
