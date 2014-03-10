module Publishable

  def self.included(base)
    base.extend(ClassMethods)
  end


  module ClassMethods

    def create_from_json(json, opts = {})
      json['publish'] = Preference.defaults['publish'] if json['publish'].nil?
      super
    end

  end

end
