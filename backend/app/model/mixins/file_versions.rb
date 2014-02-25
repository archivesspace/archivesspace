module FileVersions

  def self.included(base)
    base.one_to_many :file_version

    base.def_nested_record(:the_property => :file_versions,
                           :contains_records_of_type => :file_version,
                           :corresponding_to_association  => :file_version)
  end

end
