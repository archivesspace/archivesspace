
# Mixin for clients who want to say '.to_hash'
# and get an object with language "English" rather
# than "eng"

module JSONModelTranslatable


  def to_hash_with_translated_enums(enums_to_translate, mode = nil)

    hash = self.to_hash(mode)

    if enums_to_translate
      hash = JSONModelTranslatable.translate_hash(hash, self.class.schema, enums_to_translate)
    end

    hash

  end


  def self.translate_hash(hash, schema, enums_to_translate)
    result = hash.clone

    schema["properties"].each do |property, definition|

      if (definition['type'] == 'array') and (definition['items']['type'] =~ /^JSONModel\(:(.*)\)/)
        type = $1
        result[property] = hash[property].map {|item| self.translate_hash(item, JSONModel(type).schema, enums_to_translate) }
      elsif (definition['type'] == 'array') and (definition['items']['type'] == 'object')
        result[property] = hash[property].map {|item| self.translate_hash(item, definition['items'], enums_to_translate) }

      elsif (definition['type'] == 'array') and (definition['items']['type'].is_a?(Array))
        result[property] = hash[property].map {|item|
         if item['jsonmodel_type']
           self.translate_hash(item, JSONModel(item['jsonmodel_type']).schema, enums_to_translate)
         else
           item
         end
        }

      elsif definition.has_key?("dynamic_enum")
        enum_name = definition["dynamic_enum"]

        next unless enums_to_translate.include? enum_name
        next unless hash[property]

        translated = JSONModel::init_args[:i18n_source].
          t("enumerations.#{enum_name}.#{hash[property]}")

        if translated
          result[property] = translated
        end
      end

    end

    result
  end

end
