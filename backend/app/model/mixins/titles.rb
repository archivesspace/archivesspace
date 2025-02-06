module Titles

  def self.included(base)
    base.one_to_many(:title)
    base.def_nested_record(:the_property => :titles,
                           :contains_records_of_type => :title,
                           :corresponding_to_association  => :title)
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    Log.debug("Updating from json: \n#{json.inspect}")

  end

end
