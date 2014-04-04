class Term < Sequel::Model(:term)
  include ASModel
  corresponds_to JSONModel(:term)

  set_model_scope :global

  def validate
    super
    validates_unique([:vocab_id, :term, :term_type_id], :message => "Term must be unique")
    map_validation_to_json_property([:vocab_id, :term, :term_type_id], :term)
  end

  def self.set_vocabulary(json, opts)
    opts["vocab_id"] = nil

    if json["vocabulary"]
      opts["vocab_id"] = parse_reference(json["vocabulary"], opts)[:id]
    end
  end

  def self.create_from_json(json, opts = {})
    set_vocabulary(json, opts)
    obj = super

    broadcast_changes
    obj
  end

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json.vocabulary = uri_for(:vocabulary, obj.vocab_id)
    end

    jsons
  end


  def self.ensure_exists(json, referrer)
    DB.attempt {
      self.create_from_json(json)
    }.and_if_constraint_fails {|exception|
      term_type_id = BackendEnumSource.id_for_value("subject_term_type", json.term_type)

      term = Term.find(:vocab_id => JSONModel(:vocabulary).id_for(json.vocabulary),
                       :term => json.term,
                       :term_type_id => term_type_id)

      if !term
        # The term exists but we can't find it.  This could mean it was
        # created in a currently running transaction.  Abort this one to trigger
        # a retry.
        Log.info("Term '#{json.term}' seems to have been created by a currently running transaction.  Restarting this one.")
        sleep 5
        raise RetryTransaction.new
      end

      term
    }
  end

  def self.broadcast_changes
    Notifications.notify("VOCABULARY_CHANGED")
  end
end
