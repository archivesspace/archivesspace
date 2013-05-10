module Subjects

  def self.included(base)
    base.include(Relationships)

    base.define_relationship(:name => :subject,
                             :json_property => 'subjects',
                             :contains_references_to_types => proc {[Subject]})
  end

end
