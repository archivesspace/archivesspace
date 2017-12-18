require 'nokogiri'

class OAIUtils
  def self.extract_published_note_content(note, toplevel = true)
    if toplevel && !note['publish']
      return []
    end

    if note.is_a?(Hash)
      if note['publish']
        if note['jsonmodel_type'] == 'note_chronology'
          [
            strip_mixed_content(note['title']),
            ASUtils.wrap(note['items']).map{|item|
              [
                item['event_date'],
                ASUtils.wrap(item['events']).map{|e| strip_mixed_content(e)}.join(', ')
              ].compact.join(', ')
            }.join('; ')
          ].compact.join('. ')
        elsif note['jsonmodel_type'] == 'note_definedlist'
          [
            note['title'],
            ASUtils.wrap(note['items']).map{|item|
              [
                strip_mixed_content(item['label']),
                strip_mixed_content(item['value'])
              ].compact.join(': ')
            }.join('; ')
          ].compact.join('. ')
        elsif note['jsonmodel_type'] == 'note_orderedlist'
          [
            strip_mixed_content(note['title']),
            ASUtils.wrap(note['items']).map{|i| strip_mixed_content(i)}.join('; ')
          ].compact.join('. ')
        elsif note.has_key?('content')
          Array(note['content']).map {|content|
            strip_mixed_content(content)
          }
        else
          note.values.map {|value| extract_published_note_content(value, false)}.flatten
        end
      else
        []
      end
    elsif note.is_a?(Array)
      note.map {|value| extract_published_note_content(value, false)}.flatten
    else
      []
    end
  end


  def self.strip_mixed_content(s)
    return s if s.nil?

    Nokogiri::HTML(s).text
  end


  def self.display_string(json)
    self.strip_mixed_content(json['display_string'] || json['title'])
  end
end
