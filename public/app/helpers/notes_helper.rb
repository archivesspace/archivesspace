require 'mixed_content_parser'

module NotesHelper

  def clean_note(note)
    MixedContentParser::parse(note, url_for(:root))
  end

end
