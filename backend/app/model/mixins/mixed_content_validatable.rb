require 'mixed_content_validator'

module MixedContentValidatable

  # Adds a validation error to the given field (default :title) for invalid EAD markup.
  def validate_mixed_content_field(field = :title)
    value = begin
      respond_to?(field) ? send(field) : self[field]
    rescue
      self[field]
    end

    return if value.nil? || value.to_s.strip.empty?

    if (msg = MixedContentValidator.error_for_inline_ead(value))
      errors.add(field, msg)
    end
  end
end
