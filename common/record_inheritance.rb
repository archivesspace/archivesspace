class RecordInheritance

  def self.merge(json, opts = {})
    self.new.merge(json, opts)
  end


  def self.has_type?(type)
    self.new.has_type?(type)
  end


  # Add our inheritance-specific definitions to relevant JSONModel schemas
  def self.prepare_schemas
    get_config.each do |record_type, config|
      config[:inherited_fields].map {|fld| fld[:property]}.uniq.each do |property|
        schema_def = {
          'type' => 'object',
          'subtype' => 'ref',
          'properties' => {
            # Not a great type for a ref, but in this context we don't really
            # know for sure what type the ancestor might be.  Might need to
            # think harder about this if it causes problems.
            'ref' => {'type' => 'string'},
            'level' => {'type' => 'string'},
            'direct' => {'type' => 'boolean'},
          }
        }

        properties = JSONModel::JSONModel(record_type).schema['properties']
        if properties[property]['type'].include?('object')
          add_inline_inheritance_field(properties[property], schema_def)

        elsif properties[property]['type'] == 'array'
          extract_referenced_types(properties[property]['items']).each do |item_type|
            if item_type['type'].include?('object')
              add_inline_inheritance_field(item_type, schema_def)
            else
              $stderr.puts("Inheritence metadata for string arrays is not currently supported (record type: #{record_type}; property: #{property}).  Please file a bug if you need this!")
            end
          end
        else
          # We add a new property alongside
          properties["#{property}_inherited"] = schema_def
        end
      end
    end
  end


  # Extract a list elements like {'type' => 'mytype'} from the various forms
  # JSON schemas allow types to be in.  For example:
  #
  # {"type" => "JSONModel(:resource) uri"}
  #
  # {"type" => [{"type" => "JSONModel(:resource) uri"},
  #             {"type" => "JSONModel(:archival_object) uri"}]}
  #
  def self.extract_referenced_types(typedef)
    if typedef.is_a?(Array)
      typedef.map {|elt| extract_referenced_types(elt)}.flatten
    elsif typedef.is_a?(Hash)
      if typedef['type'].is_a?(String)
        [typedef]
      else
        extract_referenced_types(typedef['type'])
      end
    else
      $stderr.puts("Unrecognized type: #{typedef.inspect}")
      []
    end
  end

  def self.add_inline_inheritance_field(target, schema_def)
    schema = nil

    if target.has_key?('properties')
      schema = target['properties']
    elsif target['type'] =~ /JSONModel\(:(.*?)\) object/
      referenced_jsonmodel = $1.intern
      schema = JSONModel::JSONModel(referenced_jsonmodel).schema['properties']
    end

    if schema
      schema['_inherited'] = schema_def
    else
      $stderr.puts("Inheritence metadata for string arrays is not currently supported (property was: #{property}).  Please file a bug if you need this!")
    end
  end

  def self.get_config
    (AppConfig.has_key?(:record_inheritance) ? AppConfig[:record_inheritance] : {})
  end

  def initialize(config = nil)
    @config = config || self.class.get_config
  end


  def merge(jsons, opts = {})
    return merge_record(jsons, opts) unless jsons.is_a? Array

    jsons.map do |json|
      merge_record(json, opts)
    end
  end


  def has_type?(type)
    @config.has_key?(type.intern)
  end


  private


  def merge_record(json_in, opts)
    json = json_in.clone

    direct_only = opts.fetch(:direct_only) { false }
    remove_ancestors = opts.fetch(:remove_ancestors) { false }
    config = @config.fetch(json['jsonmodel_type'].intern) { false }

    if config
      config[:inherited_fields].each do |fld|
        next if direct_only && !fld[:inherit_directly]

        next if fld.has_key?(:skip_if) && fld[:skip_if].call(json)

        val = json[fld[:property]]

        if val.is_a?(Array)
          if val.empty? || fld.has_key?(:inherit_if) && fld[:inherit_if].call(val).empty?
            json['ancestors'].map {|ancestor|
              ancestor_val = fld.has_key?(:inherit_if) ? fld[:inherit_if].call(ancestor['_resolved'][fld[:property]])
                                                       : ancestor['_resolved'][fld[:property]]
              unless ancestor_val.empty?
                json[fld[:property]] = json[fld[:property]] + ancestor_val
                json[fld[:property]].flatten!
                json = apply_inheritance_properties(json, ancestor_val, ancestor, fld)
                break
              end
            }
          end
        else
          if !json[fld[:property]] || fld.has_key?(:inherit_if) && !fld[:inherit_if].call(json[fld[:property]])
            json['ancestors'].map {|ancestor|
              ancestor_val = ancestor['_resolved'][fld[:property]]
              if ancestor_val
                json[fld[:property]] = ancestor_val
                json = apply_inheritance_properties(json, ancestor_val, ancestor, fld)
                break
              end
            }
          end
        end
      end

      # composite identifer
      if config.has_key?(:composite_identifiers) && !direct_only
        ids = []
        json['ancestors'].reverse.each do |ancestor|
          if ancestor['_resolved']['component_id']
            id = ancestor['_resolved']['component_id']
            if config[:composite_identifiers][:include_level]
              id = [translate_level(ancestor['level']), id].join(' ')
            end
            ids << id
          elsif ancestor['_resolved']['id_0']
            ids << (0..3).map { |i| ancestor['_resolved']["id_#{i}"] }.compact.
              join(config[:composite_identifiers].fetch(:identifier_delimiter, ' '))
          end
        end

        # include our own id in the composite if it wasn't inherited
        if json['component_id'] && !json['component_id_inherited']
          id = json['component_id']
          if config[:composite_identifiers][:include_level]
            id = [translate_level(json['level']), id].join(' ')
          end
          ids << id
        end

        delimiter = config[:composite_identifiers].fetch(:identifier_delimiter, ' ')
        delimiter += ' ' if delimiter != ' ' && config[:composite_identifiers][:include_level]
        json['_composite_identifier'] = ids.join(delimiter)
      end
    end

    json['ancestors'] = [] if remove_ancestors
    json
  end

  
  def apply_inheritance_properties(json, vals, ancestor, field_config)
    props = {
      'ref' => ancestor['ref'],
      'level' => translate_level(ancestor['level']),
      'direct' => field_config[:inherit_directly]
    }

    ASUtils.wrap(vals).each do |val|
      if val.is_a?(Hash)
        val['_inherited'] = props
      else
        json["#{field_config[:property]}_inherited"] = props
      end
    end
    json
  end


  def translate_level(level)
    I18n.t("enumerations.archival_record_level.#{level}", :default => level)
  end

end
