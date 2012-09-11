# Handling for models that require Subjects
require_relative 'subject'

module Subjects

  def self.included(base)
    base.many_to_many :subjects

    base.jsonmodel_hint(:the_property => :subjects,
                        :contains_records_of_type => :subject,
                        :corresponding_to_association  => :subjects)
  end

end
