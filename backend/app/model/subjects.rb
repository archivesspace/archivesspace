# Handling for models that require Subjects
require_relative 'subject'

module Subjects

  def self.included(base)
    base.many_to_many :subject, :join_table => "subject_#{base.table_name}", :order => "subject_#{base.table_name}__id"

    base.jsonmodel_hint(:the_property => :subjects,
                        :contains_records_of_type => :subject,
                        :corresponding_to_association  => :subject)
  end

end
