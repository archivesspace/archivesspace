module ExternalIDs

  def self.included(base)
    base.one_to_many(:external_id)

    base.def_nested_record(:the_property => :external_ids,
                           :contains_records_of_type => :external_id,
                           :corresponding_to_association  => :external_id)
  end

end
