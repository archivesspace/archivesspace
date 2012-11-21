require 'securerandom'

module AutoIdGenerator

  module Mixin
    def self.included(base)
      base.extend(ClassMethods)
    end

    def before_create
      super
      self.class.properties_to_auto_generate.each do |property|
        if self.send(property).nil?
          self.send("#{property}=", SecureRandom.hex)
          @stale = true
        end
      end
    end

    def update_from_json(json, opts = {})
      self.class.properties_to_auto_generate.each do |property|
        json[property] = self.send(property)
      end
      super
    end

    module ClassMethods

      def register_auto_id(property)
        @properties_to_auto_generate ||= []
        @properties_to_auto_generate.push(property)
      end

      def properties_to_auto_generate
        @properties_to_auto_generate || []
      end

    end

  end
end
