module Publishable

  def self.included(base)
    base.extend(ClassMethods)
  end


  module ClassMethods

    def create_from_json(json, opts = {})
      obj = super

      if respond_to?(:publish) && obj.publish.nil?
        obj.publish = Preference.defaults['publish'] ? 1 : 0
      end

      obj
    end

  end

end
