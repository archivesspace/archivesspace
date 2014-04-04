module Publishable

  def self.included(base)
    base.extend(ClassMethods)
  end


  def self.db_value_for(hash)
    published = Preference.defaults['publish']

    if hash.has_key?('publish')
      published = hash['publish']
    end

    published ? 1 : 0
  end


  module ClassMethods

    def create_from_json(json, opts = {})
      json['publish'] = Preference.defaults['publish'] if json['publish'].nil?
      super
    end

  end

end
