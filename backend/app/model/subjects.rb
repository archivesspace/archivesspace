# Handling for models that require Subjects
require_relative 'subject'

module Subjects

  def self.included(base)
    base.many_to_many :subjects
    base.define_linked_record(:type => :subject,
                              :plural_type => :subjects,
                              :class => Subject)
  end

end
