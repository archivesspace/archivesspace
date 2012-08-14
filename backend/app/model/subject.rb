class Subject < Sequel::Model(:subjects)
  plugin :validation_helpers
  include ASModel


  def validate
    super
    validates_presence(:term_type, :message=>"You must supply a term type")
    validates_unique(:term, :message=>"Term must be unique")
  end

  many_to_many :archival_objects
  
  def self.set_vocabulary(json, opts)
    opts["vocab_id"] = nil
    opts["parent_id"] = nil
    
    if json.vocabulary
      opts["vocab_id"] = JSONModel::parse_reference(json.vocabulary, opts)[:id]
      
      if json.parent
        opts["parent_id"] = JSONModel::parse_reference(json.parent, opts)[:id]
      end
    end
  end
  
  def self.create_from_json(json, opts = {})
    set_vocabulary(json, opts)
    super(json, opts)
  end
  
  def update_from_json(json, opts = {})
    puts "UPDATE FROM JSON #{json.inspect}"
    self.class.set_vocabulary(json, opts)
    super(json, opts)
  end
  
  def self.to_jsonmodel(obj, type)
    puts "UNSUPER JSON MODEL #{obj.inspect}"
    if obj.is_a? Integer
      # An ID.  Get the Sequel row for it.
      obj = get_or_die(obj)
    end
#    json = super(obj, type)
    obj_hash = obj.values.reject {|k, v| v.nil? }
    obj_hash.merge!({ "vocabulary" => JSONModel(:vocabulary).uri_for(obj.vocab_id) })
    json = JSONModel(type).from_hash(obj_hash)

    json.uri = json.class.uri_for(obj.id, {:repo_id => obj[:repo_id]})

    json

  end
  
end
