class Subject < Sequel::Model(:subjects)
  plugin :validation_helpers
  include ASModel

  def validate
    super
    validates_unique([:vocab_id, :terms], :message => "Subject must be unique")
  end

  many_to_many :terms
  many_to_many :archival_objects

  def self.set_vocabulary(json, opts)
    opts["vocab_id"] = nil

    if json.vocabulary
      opts["vocab_id"] = JSONModel::parse_reference(json.vocabulary, opts)[:id]
    end
  end


  def self.apply_terms(subject, json, opts)
    subject.remove_all_terms

    terms = (json.terms or []).map do |term_or_uri|
      if term_or_uri.kind_of? String
        # A URI
        JSONModel(:term).id_for(term_or_uri)
      else
        term = JSONModel(:term).from_hash(term_or_uri)
        Term.ensure_exists(term)
      end
    end

    terms.each do |term_id|
      subject.add_term(Term[term_id])
    end
  end


  def self.create_from_json(json, opts = {})
    set_vocabulary(json, opts)
    obj = super(json, opts)
    apply_terms(obj, json, opts)
    obj
  end

  def update_from_json(json, opts = {})
    self.class.set_vocabulary(json, opts)
    super(json, opts)
  end


  def self.sequel_to_jsonmodel(obj, type)
    json = super(obj, type)

    json.vocabulary = JSONModel(:vocabulary).uri_for(obj.vocab_id)
    json.terms = obj.terms.map {|term| Term.to_jsonmodel(term, :term).to_hash}

    json
  end

end
