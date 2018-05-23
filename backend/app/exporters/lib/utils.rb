require 'securerandom'

module ASpaceExport
  module Utils

    # Extract a string of a note's content (including the content field and any
    # text subnotes)
    def self.extract_note_text(note, include_unpublished = false, add_punct = false)
      subnotes = note['subnotes'] || []
      note_text = (Array(note['content']) +
                  subnotes.map { |sn|
                    sn['content'] if (sn['jsonmodel_type'] == 'note_text' && include_unpublished || sn["publish"])
                  }.compact).join(" ")

      # ANW-654: Check if last character of the note_text is terminal punctuation.
      # If not, append a period to the end of the note.
      if add_punct == true && !note_text.empty? && !['.', '!', '?'].include?(note_text[-1])
        note_text << "."
      end

      return note_text
    end

    def self.has_html?(text)
      !!(text =~ /.*\<[^>]+>.*/   )
    end

    def self.has_xml_node?(node, text)
      !!(text =~  /\<#{node}*/ )
    end

    # some notes don't allow heads....
    def self.headless_notes
     %w{ legalstatus }
    end

    # ... and some notes don't allow p's.
    def self.notes_with_p
      %w{ accessrestrict accruals acqinfo altformavail appraisal arrangement
      bibliography bioghist blockquote controlaccess custodhist daodesc descgrp
      div dsc dscgrp editionstmt fileplan index note odd originalsloc otherfindaid
      phystech prefercite processinfo publicationstmt relatedmaterial scopecontent
      separatedmaterial seriesstmt titlepage userestrict }
    end

    def self.include_p?(note_type)
      self.notes_with_p.include?(note_type)
    end

    def self.headless_note?(note_type, content)
       if content.strip.start_with?('<head') or self.headless_notes.include?(note_type)
          true
       else
         false
       end
    end

  end
end


module ASpaceMappings
  module MARC21

    def self.get_marc_source_code(code)

      marc_code = case code
                  when 'naf', 'lcsh', 'lcnaf'; 0
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

