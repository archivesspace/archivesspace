require 'multiple_titles_helper'
require 'json'

module Titles
  def self.included(base)
    base.one_to_many(:title)
    base.def_nested_record(:the_property => :titles,
                           :contains_records_of_type => :title,
                           :corresponding_to_association  => :title)
  end

  def self.primary_title(titles)
    # since this is backend, try to support the Title model as well as json
    MultipleTitlesHelper.determine_primary_title(
      titles[0].is_a?(Title) ? titles.map(&:to_json) : titles,
      Preference.get_user_global_preference('locale').to_sym || I18n.default_locale
    )
  end
end
