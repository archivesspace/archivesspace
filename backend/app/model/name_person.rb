require_relative 'name_mixin'
require_relative 'auto_generator'

class NamePerson < Sequel::Model(:name_person)
  include ASModel
  corresponds_to JSONModel(:name_person)

  include NameMixin
  include AutoGenerator

  auto_generate :property => :sort_name,
                :generator => proc  { |json|
                  result = ""

                  if json["name_order"] === "inverted"
                    result << json["primary_name"] if json["primary_name"]
                    result << ", #{json["rest_of_name"]}" if json["rest_of_name"]
                    result << ", #{json["prefix"]}" if json["prefix"]
                    result << ", #{json["suffix"]}" if json["suffix"]
                    result << ", #{json["title"]}" if json["title"]
                    result << ", #{json["number"]}" if json["number"]
                    result << " (#{json["fuller_form"]})" if json["fuller_form"]
                    result << ", #{json["dates"]}" if json["dates"]
                    result << " (#{json["qualifier"]})" if json["qualifier"]
                  elsif json["name_order"] === "direct"
                    result << json["rest_of_name"] if json["rest_of_name"]
                    result << " #{json["primary_name"]}" if json["primary_name"]
                    result << ", #{json["prefix"]}" if json["prefix"]
                    result << ", #{json["suffix"]}" if json["suffix"]
                    result << ", #{json["title"]}" if json["title"]
                    result << ", #{json["number"]}" if json["number"]
                    result << " (#{json["fuller_form"]})" if json["fuller_form"]
                    result << ", #{json["dates"]}" if json["dates"]
                    result << " (#{json["qualifier"]})" if json["qualifier"]
                  end

                  result
                },
                :only_if => proc { |json| json["sort_name_auto_generate"] }
end
