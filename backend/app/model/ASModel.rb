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
    old = JSONModel(json.class.record_type).from_hash(json.to_hash.merge(self.values)).to_hash
    changes = json.to_hash.merge(opts)

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


    def get_or_die(id, repo_id = nil)
      # For a minute there I lost myself...
      obj = repo_id.nil? ? self[id] : self[:id => id, :repo_id => repo_id]

      obj or raise NotFoundException.new("#{self} not found")
    end


    def sequel_to_jsonmodel(obj, model)
      json = JSONModel(model).new(obj.values.reject {|k, v| v.nil? })

      uri = json.class.uri_for(obj.id, {:repo_id => obj[:repo_id]})
      json.uri = uri if uri

      json
    end


    def to_jsonmodel(obj, model, repo_id = nil)
      if obj.is_a? Integer
        # An ID.  Get the Sequel row for it.
        obj = get_or_die(obj, repo_id)
      end

      sequel_to_jsonmodel(obj, model)
    end

  end
end
