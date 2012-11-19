require 'securerandom'

module AutoIdGenerator

  @@auto_generated_id_map = {}

  def self.register_auto_id(a_class, property)
    @@auto_generated_id_map[a_class] ||= []
    @@auto_generated_id_map[a_class].push(property.to_s)
  end


  def self.auto_generated_ids(a_class)
    @@auto_generated_id_map[a_class] || []
  end


  module Mixin
    def self.included(base)
      base.extend(ClassMethods)
    end

    def before_create
      super
      AutoIdGenerator.auto_generated_ids(self.class).each do |property|
        self.send("#{property}=", SecureRandom.hex) if self.send(property).nil?
      end
    end

    def update_from_json(json, opts = {})
      AutoIdGenerator.auto_generated_ids(self.class).each do |property|
        json[property] = self.send(property)
      end
      super
    end

    module ClassMethods

      def register_auto_id(properties)
        AutoIdGenerator.register_auto_id(self, properties)
      end

    end

  end
end
