class OAIUtils
  def self.extract_published_note_content(note, toplevel = true)
    if toplevel && !note['publish']
      return []
    end

    if note.is_a?(Hash)
      if note.has_key?('content')
        if note['publish']
          Array(note['content']).map {|content|
            strip_mixed_content(content)
          }
        else
          []
        end
      else
        note.values.map {|value| extract_published_note_content(value, false)}.flatten
      end
    elsif note.is_a?(Array)
      note.map {|value| extract_published_note_content(value, false)}.flatten
    else
      []
    end
  end


  def self.strip_mixed_content(s)
    return s if s.nil?

    MixedContentParser.parse(s, '/')
  end
end
