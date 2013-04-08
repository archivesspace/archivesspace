module Subjects

  def self.included(base)
    base.many_to_many :subject, :join_table => "subject_#{base.table_name}", :order => "subject_#{base.table_name}__id".intern

    base.include(Relationships)

    base.define_relationship(:name => :subject,
                             :json_property => 'subjects',
                             :contains_references_to_types => proc {[Subject]})
  end

end
