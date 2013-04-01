require_relative 'name_mixin'
require_relative 'auto_generator'

class NameSoftware < Sequel::Model(:name_software)
  include ASModel
  corresponds_to JSONModel(:name_software)

  include NameMixin
  include AutoGenerator

  auto_generate :property => :sort_name,
                :generator => proc  { |json|
                  result = ""

                  result << "#{json["manufacturer"]} " if json["manufacturer"]
                  result << "#{json["software_name"]}" if json["software_name"]
                  result << " #{json["version"]}" if json["version"]
                  result << " (#{json["qualifier"]})" if json["qualifier"]

                  result
                },
                :only_if => proc { |json| json["sort_name_auto_generate"] }

end
