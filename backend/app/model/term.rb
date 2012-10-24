class Term < Sequel::Model(:term)
  plugin :validation_helpers
  include ASModel

  many_to_many :subject, :join_table => "subject_term"


  def validate
    super
    validates_unique([:vocab_id, :term, :term_type], :message => "Term must be unique")
    map_validation_to_json_property([:vocab_id, :term, :term_type], :term)
  end

  def self.set_vocabulary(json, opts)
    opts["vocab_id"] = nil

    if json["vocabulary"]
      opts["vocab_id"] = JSONModel::parse_reference(json["vocabulary"], opts)[:id]
    end
  end

  def self.create_from_json(json, opts = {})
    set_vocabulary(json, opts)

    broadcast_changes

    super
  end

  def self.sequel_to_jsonmodel(obj, type, opts = {})
    json = super
    json.vocabulary = JSONModel(:vocabulary).uri_for(obj.vocab_id)

    json
  end


  def self.ensure_exists(json, referrer)
    begin
      self.create_from_json(json)
    rescue Sequel::ValidationFailed
      Term.find(:vocab_id => JSONModel(:vocabulary).id_for(json.vocabulary),
                :term => json.term,
                :term_type => json.term_type).id
    end
  end

  def self.broadcast_changes
    Webhooks.notify("VOCABULARY_CHANGED")
  end
end
