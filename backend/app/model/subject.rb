require_relative 'term'

class Subject < Sequel::Model(:subjects)
  plugin :validation_helpers
  include ASModel

  many_to_many :terms
  many_to_many :archival_objects

  link_association_to_jsonmodel(:association => :terms,
                                :jsonmodel => :term,
                                :json_property => :terms,
                                :always_resolve => true)


  def validate
    super
    validates_unique([:vocab_id, :terms], :message => "Subject must be unique")
  end


  def self.set_vocabulary(json, opts)
    opts["vocab_id"] = nil

    if json.vocabulary
      opts["vocab_id"] = JSONModel::parse_reference(json.vocabulary, opts)[:id]
    end
  end


  def self.create_from_json(json, opts = {})
    set_vocabulary(json, opts)
    super(json, opts)
  end

  def update_from_json(json, opts = {})
    self.class.set_vocabulary(json, opts)
    super(json, opts)
  end


  def self.sequel_to_jsonmodel(obj, type)
    json = super(obj, type)

    json.vocabulary = JSONModel(:vocabulary).uri_for(obj.vocab_id)

    json
  end

end
