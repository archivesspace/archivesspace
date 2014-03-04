module Publishable

  def self.included(base)
    base.extend(ClassMethods)
  end


  module ClassMethods

    def create_from_json(json, opts = {})
      obj = super

      if obj.publish.nil?
        obj.publish = Preference.defaults['publish'] ? 1 : 0
      end

      obj
    end

  end

end
