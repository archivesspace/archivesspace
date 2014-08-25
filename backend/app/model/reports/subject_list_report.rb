require_relative 'jdbc_report'

class SubjectListReport < JDBCReport 

  register_report({
                    :uri_suffix => "subject_list",
                    :description => "A list of subject",
                  })

end

