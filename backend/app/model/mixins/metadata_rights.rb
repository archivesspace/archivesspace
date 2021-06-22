module MetadataRights

  def self.included(base)
    base.one_to_many :metadata_rights_declaration

    base.def_nested_record(:the_property => :metadata_rights_declarations,
                           :contains_records_of_type => :metadata_rights_declaration,
                           :corresponding_to_association  => :metadata_rights_declaration)
  end
end
