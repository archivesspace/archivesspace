module DynamicEnums

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    def uses_enums(*definitions)
      definitions.each do |definition|
        Enumeration.register_enumeration_dependant(definition, self)
      end

      self.instance_eval do

        definitions.each do |definition|
          property = definition[:property].intern
          property_id = "#{definition[:property]}_id".intern

          define_method("#{property}=".intern) do |value|

            if value
              Array(definition[:uses_enum]).each do |enum_name|
                enum_value_id = BackendEnumSource.id_for_value(enum_name, value)

                if !enum_value_id && value == 'other_unmapped' && AppConfig[:allow_other_unmapped]
                  # Ensure this value exists for this enumeration
                  enum = Enumeration[:name => definition[:uses_enum]]
                  enum_value_id = DB.attempt {
                    EnumerationValue.create(:enumeration_id => enum.id, :value => 'other_unmapped').id
                  }.and_if_constraint_fails do
                    BackendEnumSource.id_for_value(definition[:uses_enum], value)
                  end
                end

                next if !enum_value_id
                self[property_id] = enum_value_id
                break
              end

              raise "Invalid value: #{value}" if !self[property_id]
            else
              self[property_id] = nil
            end
          end


          define_method("#{property}".intern) do
            if self[property_id]
              result = Array(definition[:uses_enum]).map {|enum_name|
                BackendEnumSource.value_for_id(enum_name, self[property_id])
              }.compact.first

              raise "Couldn't find enum in #{property} for #{self.class} with id #{self[property_id]}" unless result
              result
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


require_relative '../enumeration'
