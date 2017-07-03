# module AssessmentConservationIssues
# 
#   def self.included(base)
#     base.one_to_many :assessment_conservation_issue
# 
#     base.def_nested_record(:the_property => :conservation_issues,
#                            :contains_records_of_type => :assessment_conservation_issue,
#                            :corresponding_to_association  => :assessment_conservation_issue)
#   end
# 
# end
