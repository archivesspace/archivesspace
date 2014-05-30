require 'securerandom'

module ASpaceExport
  module Utils

    # Extract a string of a note's content (including the content field and any
    # text subnotes)
    def self.extract_note_text(note, include_unpublished = false)
      subnotes = note['subnotes'] || []
      (Array(note['content']) +
       subnotes.map { |sn|
         sn['content'] if (sn['jsonmodel_type'] == 'note_text' && include_unpublished || sn["publish"])
       }.compact).join(" ")
    end

    def self.has_html?(text)
      !!(text =~ /.*\<[^>]+>.*/   )
    end

  end
end


module ASpaceMappings
  module MARC21

    def self.get_marc_source_code(code)

      marc_code = case code
                  when 'naf', 'lcsh'; 0
                  when 'lcshac'; 1
                  when 'mesh'; 2
                  when 'nal'; 3
                  when nil; 4
                  when 'cash'; 5
                  when 'rvm'; 6
                  else; 7
                  end

      marc_code.to_s
    end
  end
end

