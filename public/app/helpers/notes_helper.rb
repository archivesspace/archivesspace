require 'mixed_content_parser'

module NotesHelper

  def clean_note(note, opts = {})
    opts[:wrap_blocks] ||= true 
    MixedContentParser::parse(note, url_for(:root), opts )
  end

end
