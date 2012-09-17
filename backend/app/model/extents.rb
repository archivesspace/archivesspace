# Handling for models that require Extents
require_relative 'extent'

module Extents

  def self.included(base)
    base.one_to_many :extents

    base.jsonmodel_hint(:the_property => :extents,
                        :contains_records_of_type => :extent,
                        :corresponding_to_association  => :extents)
  end

end
