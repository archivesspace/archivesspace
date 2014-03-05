module Publishable

  def self.included(base)
    base.extend(ClassMethods)
  end


  module ClassMethods

    def create_from_json(json, opts = {})
      if respond_to?(:publish) && json['publish'].nil?
        json['publish'] = Preference.defaults['publish']
      end

      super
    end

  end

end
