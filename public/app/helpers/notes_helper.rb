require 'notes_parser'

module NotesHelper

  def clean_note(note)
    NotesParser::parse(note, url_for(:root))
  end

end