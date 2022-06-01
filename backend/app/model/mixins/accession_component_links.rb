module AccessionComponentLinks

    def self.included(base)
      base.define_relationship(:name => :accession_component_links,
                               :json_property => 'component_links',
                               :contains_references_to_types => proc {[ArchivalObject]},
                               :is_array => true)
    end
  
  end