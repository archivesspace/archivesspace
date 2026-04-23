# frozen_string_literal: true

# Validates inline EAD markup is well formed.
module MixedContentValidator
  DISALLOWED_TAGS = %w[
    script style iframe object embed applet
    meta link base form input button select
    textarea option optgroup label fieldset
  ].freeze

  def self.error_for_inline_ead(content)
    return 'mixed_content_disallowed_tag' unless allowed_tags?(content)
    return nil if valid_inline_ead?(content)

    'mixed_content_invalid_inline_ead'
  end

  def self.valid_inline_ead?(content)
    return true if content.nil? || content.strip.empty?
    return true unless content.include?('<')

    # Inspect each opening tag and ensure attribute assignments are properly quoted
    # Regex: match opening tags only (exclude comments <!>, processing <?>, and closing </>);
    # capture tag name (group 1) and raw attributes text (group 2)
    attributes_ok = content.scan(/<(?!!|\?|\/)([A-Za-z][A-Za-z0-9:_-]*)([^>]*)>/).all? do |tag, attrs|
      attributes_are_well_quoted?(attrs)
    end

    attributes_ok && tags_are_well_formed?(content)
  end

  def self.allowed_tags?(content)
    return true if content.nil? || content.strip.empty?
    return true unless content.include?('<')

    content.scan(/<\/?([A-Za-z][A-Za-z0-9:_-]*)/).all? do |tag_name,|
      !DISALLOWED_TAGS.include?(tag_name.downcase)
    end
  end

  def self.tags_are_well_formed?(content)
    stack = []

    # Regex: match any tag; capture if it's a closing tag (group 1),
    # the tag name (group 2), and the remainder/attributes (group 3)
    content.scan(/<(\/)?([A-Za-z][A-Za-z0-9:_-]*)([^>]*)>/).each do |closing, name, rest|
      if closing
        return false if stack.empty?
        return false unless stack.pop == name
      else
        # Self-closing if trailing slash before '>'
        self_closing = rest && rest.strip.end_with?('/')
        stack.push(name) unless self_closing
      end
    end

    stack.empty?
  end

  def self.attributes_are_well_quoted?(attrs)
    return true if attrs.nil? || attrs.strip.empty?

    # Reject any curly/smart quote characters outright
    return false if attrs.match?(/[“”‘’]/)

    remainder = attrs.dup

    # Remove properly quoted attribute assignments (double and single quoted)
    # Regex: remove well-formed attributes like key="..." (supports escaped quotes)
    remainder.gsub!(/\s+[A-Za-z_:][\w:.-]*\s*=\s*"(?:[^"\\]|\\.)*"/, ' ')
    # Regex: remove well-formed attributes like key='...' (supports escaped quotes)
    remainder.gsub!(/\s+[A-Za-z_:][\w:.-]*\s*=\s*'(?:[^'\\]|\\.)*'/, ' ')

    # Ignore trailing whitespace and self-closing slash
    remainder.strip!
    # Regex: strip a bare '/'
    remainder.sub!(%r{^/\s*$}, '')

    # If anything resembling an unhandled assignment remains, it's invalid
    !remainder.include?('=')
  end

  private_class_method :tags_are_well_formed?, :attributes_are_well_quoted?, :allowed_tags?
end
