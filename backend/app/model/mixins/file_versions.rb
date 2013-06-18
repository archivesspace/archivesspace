module FileVersions

  def publish!
    self.file_version.each do |version|
      version.publish!
    end

    super
  end

  def self.included(base)
    base.one_to_many :file_version

    base.def_nested_record(:the_property => :file_versions,
                           :contains_records_of_type => :file_version,
                           :corresponding_to_association  => :file_version,
                           :always_resolve => true)
  end

end
