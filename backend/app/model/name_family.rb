require_relative 'name_mixin'
require_relative 'auto_generator'

class NameFamily < Sequel::Model(:name_family)
  include ASModel
  corresponds_to JSONModel(:name_family)

  include NameMixin



  include AutoGenerator

  auto_generate :property => :sort_name,
                :generator => proc  { |json|
                  result = ""

                  result << json["family_name"] if json["family_name"]
                  result << ", #{json["prefix"]}" if json["prefix"]
                  result << ", #{json["dates"]}" if json["dates"]
                  result << " (#{json["qualifier"]})" if json["qualifier"]

                  result
                },
                :only_if => proc { |json| json["sort_name_auto_generate"] }
end
