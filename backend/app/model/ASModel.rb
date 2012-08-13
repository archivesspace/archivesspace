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


  def update_from_json(json, opts = {})
    old = JSONModel(json.class.record_type).from_hash(self.values).to_hash
    changes = json.to_hash

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

    def create_from_json(json, extra_values = {})
      self.strict_param_setting = false
      self.create(json.to_hash.merge(extra_values))
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

      json = JSONModel(model).from_hash(obj.values.reject {|k, v| v.nil? })

      json.uri = json.class.uri_for(obj.id, {:repo_id => obj[:repo_id]})

      json
    end
  end
end
