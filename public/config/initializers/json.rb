# See: http://stackoverflow.com/questions/683989/how-do-you-deal-with-the-conflict-between-activesupportjson-and-the-json-gem
#
# Undo the effect of 'active_support/core_ext/object/to_json'

require 'jrjackson'

[Object, Array, Hash].each do |klass|
  klass.class_eval <<-RUBY, __FILE__, __LINE__ + 1
    def jsonize(options = nil)
      JrJackson::Json.generate self, options.merge(:quirks_mode => true)
    end
  RUBY
end
