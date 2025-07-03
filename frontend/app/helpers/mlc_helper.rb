require 'multiple_titles_helper'

module MlcHelper

  # Get the appropriate title string to display based on language preferences
  def title_for_display(record = nil, clean = nil)
    r = record || current_record
    MultipleTitlesHelper.determine_primary_title(r.titles, I18n.locale)
  end

end
