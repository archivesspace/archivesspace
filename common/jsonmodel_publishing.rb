# Mixin for clients wanting to filter out unpublished data from
# JSONModel objects

require 'mixed_content_parser'

module JSONModelPublishing

  def to_hash(mode = nil)
    strip = false

    if mode == :publishing
      mode = nil
      strip = true
    end

    hash = super(mode)

    if strip
      JSONModelPublishing._drop_unpublished(hash)
      JSONModelPublishing._clean_mixed_content_notes(hash)
    end

    hash
  end


  def self._drop_unpublished(obj)
    if obj.is_a?(Array)
      obj.reject!{|item| self._drop_unpublished(item) }
      obj.each do |value|
        self._drop_unpublished(value)
      end
    elsif obj.is_a?(Hash)
      return true if obj.has_key?('publish') && !obj['publish']
      obj.reject! {|k, v| self._drop_unpublished(v) }
      self._drop_unpublished(obj.values)
    end

    false
  end


  def self._clean_mixed_content_notes(hash)
    if hash.has_key?('notes')
      hash['notes'] = hash['notes'].map {|note|
        if note.has_key?('content')
          content = note['content'].is_a?(Array) ? note['content'].join("\n\n") : note['content']
          note['content'] = MixedContentParser.parse(content, "/", {:wrap_blocks => true})
        end

        if note.has_key?('subnotes')
          note['subnotes'] = note['subnotes'].map {|subnote|
            if subnote.has_key?('content')
              subnote['content'] = MixedContentParser.parse(subnote['content'], "/", {:wrap_blocks => true})
            end

            subnote
          }
        end

        note
      }
    end
  end

end
