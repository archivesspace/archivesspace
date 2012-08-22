class Term < Sequel::Model(:terms)
  plugin :validation_helpers
  include ASModel

  many_to_many :subjects

  def validate
    super
    validates_unique([:vocab_id, :term, :term_type], :message=>"Term must be unique")
  end

  def self.set_vocabulary(json, opts)
    opts["vocab_id"] = nil
    
    if json["vocabulary"]
      opts["vocab_id"] = JSONModel::parse_reference(json["vocabulary"], opts)[:id]
    end
  end

  def self.create_from_json(json, opts = {})
    set_vocabulary(json, opts)    
    super(json, opts)
  end

  def self.sequel_to_jsonmodel(obj, type)
    json = super(obj, type)
    json.vocabulary = JSONModel(:vocabulary).uri_for(obj.vocab_id)

    json
  end


  def self.ensure_exists(json)
    begin
      self.create_from_json(json).id
    rescue Sequel::ValidationFailed
      Term.find(:vocab_id => JSONModel(:vocabulary).id_for(json.vocabulary),
                :term => json.term,
                :term_type => json.term_type).id
    end
  end

end
