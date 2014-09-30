require_relative 'jdbc_report'

class AccessionsReport < JDBCReport

  register_report({
                    :uri_suffix => "accessions",
                    :description => "Another Report on repository locations",
                  })

end
