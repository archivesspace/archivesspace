require_relative 'utils'
require 'nokogiri'

Sequel.migration do
  up do
    # If a nil 'other_level' has snuck through with a level of 'otherlevel' then we need to find and set a default 'other_level' since we're now enforcing the other_level requirement
    otherlevel = self[:enumeration_value].filter(:value => 'otherlevel').select(:id)

    [:resource, :archival_object].each do |table|
      self[table].where(level_id: otherlevel, other_level: nil).update(other_level: 'blank')
    end
  end
end
