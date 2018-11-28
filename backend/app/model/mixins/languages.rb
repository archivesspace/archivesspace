module Languages

  def self.included(base)
    base.one_to_many(:language)

    base.def_nested_record(:the_property => :languages,
                           :contains_records_of_type => :language,
                           :corresponding_to_association  => :language)
  end

end
