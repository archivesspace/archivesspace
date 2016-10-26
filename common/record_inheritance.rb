
class RecordInheritance

  def self.merge(json, opts = {})
    self.new.merge(json, opts)
  end


  def self.has_type?(type)
    self.new.has_type?(type)
  end


  def initialize(config = nil)
    @config = config || (AppConfig.has_key?(:record_inheritance) ? AppConfig[:record_inheritance] : {})
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


  def merge_record(json, opts)
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
                json = apply_inheritance_properties(json, ancestor_val, ancestor, fld)

                json[fld[:property]] << ancestor_val
                json[fld[:property]].flatten!
                break
              end
            }
          end
        else
          if !json[fld[:property]] || fld.has_key?(:inherit_if) && !fld[:inherit_if].call(json[fld[:property]])
            json['ancestors'].map {|ancestor|
              ancestor_val = ancestor['_resolved'][fld[:property]]
              if ancestor_val
                json = apply_inheritance_properties(json, ancestor_val, ancestor, fld)
                json[fld[:property]] = ancestor_val
                break
              end
            }
          end
        end
      end

      # composite identifer
      if config.has_key?(:composite_identifiers)
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
              join(config[:composite_identifiers].fetch(:identifier_delimiter) { ' ' })
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

        json['_composite_identifier'] = ids.join(' ')
      end
    end

    json['ancestors'] = [] if remove_ancestors
    json
  end

  
  def apply_inheritance_properties(json, vals, ancestor, field_config)
    ASUtils.wrap(vals).each do |val|
      props = {
        'ref' => ancestor['ref'],
        'level' => translate_level(ancestor['level']),
        'direct' => field_config[:inherit_directly]
      }
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
