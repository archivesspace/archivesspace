module DynamicEnums

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    def uses_enums(*definitions)
      self.instance_eval do

        definitions.each do |definition|
          property = definition[:property].intern
          property_id = "#{definition[:property]}_id".intern

          define_method("#{property}=".intern) do |value|
            enum = Enumeration[:enum_name => definition[:uses_enum],
                               :enum_value => value]

            raise "Invalid value: #{value}" if !enum

            self[property_id] = enum.id
          end


          define_method("#{property}".intern) do
            if self[property_id]
              enum = Enumeration[self[property_id]] or raise "Couldn't find enum for #{self[property_id]}"
              enum[:enum_value]
            else
              nil
            end
          end
        end


        define_method(:values) do
          values = super
          values = values.clone

          definitions.each do |definition|
            property = definition[:property].intern
            values[property] = self.send(property)
          end

          values
        end

      end
    end
  end
end
