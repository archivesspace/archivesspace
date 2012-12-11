require_relative 'term'
require 'digest/sha1'

class Subject < Sequel::Model(:subject)
  include ASModel
  include ExternalDocuments

  set_model_scope :global
  corresponds_to JSONModel(:subject)

  many_to_many :term, :join_table => :subject_term
  many_to_many :archival_object, :join_table => :subject_archival_object

  jsonmodel_hint(:the_property => :terms,
                 :contains_records_of_type => :term,
                 :corresponding_to_association  => :term,
                 :always_resolve => true)


  def self.set_vocabulary(json, opts)
    opts["vocab_id"] = nil

    if json.vocabulary
      opts["vocab_id"] = parse_reference(json.vocabulary, opts)[:id]
    end
  end


  def self.generate_terms_sha1(json)
    return nil if json.terms.empty?
    Digest::SHA1.hexdigest(json.terms.inspect)
  end


  def self.create_from_json(json, opts = {})
    set_vocabulary(json, opts)
    obj = super

    # add a terms sha1 hash to allow for uniqueness test
    obj.terms_sha1 = generate_terms_sha1(json)
    obj.save

    obj
  end


  def update_from_json(json, opts = {})
    self.class.set_vocabulary(json, opts)
    obj = super

    # add a terms sha1 hash to allow for uniqueness test
    obj.terms_sha1 = self.class.generate_terms_sha1(json)
    obj.save

    obj
  end


  def self.sequel_to_jsonmodel(obj, opts = {})
    json = super

    json.vocabulary = uri_for(:vocabulary, obj.vocab_id)

    json
  end


  def validate
    super
    validates_unique([:vocab_id, :terms_sha1], :message => "Subject must be unique")
    validates_unique([:vocab_id, :ref_id], :message => "Subject heading identifier must be unique")
    map_validation_to_json_property([:vocab_id, :terms_sha1], :terms)
  end

end
