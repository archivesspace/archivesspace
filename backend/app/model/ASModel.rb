module ASModel
  include JSONModel

  def before_create
    self.create_time = Time.now
    self.last_modified = Time.now
    super
  end


  def before_update
    self.last_modified = Time.now
    super
  end


  def self.included(base)
    base.extend(ClassMethods)
    base.extend(JSONModel)
  end


  def update_from_json(json)
    old = JSONModel(json.class.record_type).from_hash(self.values).to_hash
    changes = self.class.references_to_ids(json)

    old.each do |k, v|
      if not changes.has_key?(k)
        changes[k] = nil
      end
    end

    self.class.strict_param_setting = false
    self.update(changes)
    self.save
  end


  module ClassMethods

    def reference_to_id(ref)
      if ref =~ /\/([0-9]+)$/
        return $1
      else
        # This shouldn't happen: the JSON model should have already validated the
        # syntax of each reference.
        raise "Invalid reference: '#{ref}'"
      end
    end


    def reference_to_id_map
      {
        "repository" => :repo_id,
      }
    end


    def id_to_reference_map
      {
        :repo_id => {
          :property => "repository",
          :uri_format => "/repositories/%s",
        }
      }
    end


    def ids_to_references(hash)
      if self.respond_to? :id_to_reference_map
        self.id_to_reference_map.each do |column, reference|
          if hash[column]
            hash[reference[:property]] = sprintf(reference[:uri_format],
                                                 hash[column])
          end
        end
      end

      hash
    end


    def references_to_ids(json)
      row = json.to_hash

      if self.respond_to? :reference_to_id_map
        self.reference_to_id_map.each do |reference, column|
          if column and row[reference]
            row[column] = reference_to_id(row[reference])
          end

          row.delete(reference)
        end
      end

      row
    end


    def create_from_json(json, extra_values = {})
      self.strict_param_setting = false
      self.create(references_to_ids(json).merge(extra_values))
    end


    def get_or_die(id)
      # For a minute there I lost myself...
      self[id] or raise NotFoundException.new("#{self} not found")
    end


    def to_jsonmodel(obj, model)
      if obj.is_a? Integer
        # An ID.  Get the Sequel row for it.
        obj = get_or_die(obj)
      end

      mapped = ids_to_references(obj.values)

      json = JSONModel(model).from_hash(mapped.reject {|k, v| v.nil? })

      json.uri = json.class.uri_for(obj.id, {:repo_id => obj[:repo_id]})

      json
    end
  end
end
