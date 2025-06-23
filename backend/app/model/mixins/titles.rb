require 'multiple_titles_helper'

module Titles

  def self.included(base)
    base.one_to_many(:title)
    base.def_nested_record(:the_property => :titles,
                           :contains_records_of_type => :title,
                           :corresponding_to_association  => :title)
  end

  def primary_title
    MultipleTitlesHelper.determine_primary_title(json['titles'], Preference.get_user_global_preference('locale'))
  end

end
