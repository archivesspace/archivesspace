# Handling for models that require Subjects
require_relative 'subject'

module Subjects

  def self.included(base)
    base.many_to_many :subjects
    base.link_association_to_jsonmodel(:association => :subjects,
                                       :jsonmodel => :subject,
                                       :json_property => :subjects)
  end

end
