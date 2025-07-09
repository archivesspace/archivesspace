require 'multiple_titles_helper'

module MlcHelper

  # Get the appropriate title string to display based on language preferences. Will use the current_record that should
  # be present in all controllers by default, but also allows passing one in explicitly when needed.
  # (default is to parse mixed content since this is typically used for display outside of an edit field)
  def title_for_display(record = nil, parse_mixed_content: true)
    r = record || current_record
    MultipleTitlesHelper.determine_primary_title(r.titles, I18n.locale, parse_mixed_content)
  end

end
