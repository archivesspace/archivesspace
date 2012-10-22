require_relative 'term'
require 'digest/sha1'

class Subject < Sequel::Model(:subjects)
  plugin :validation_helpers
  include ASModel
  include ExternalDocuments

  many_to_many :terms
  many_to_many :archival_objects

  jsonmodel_hint(:the_property => :terms,
                 :contains_records_of_type => :term,
                 :corresponding_to_association  => :terms,
                 :always_resolve => true)


  def self.set_vocabulary(json, opts)
    opts["vocab_id"] = nil

    if json.vocabulary
      opts["vocab_id"] = JSONModel::parse_reference(json.vocabulary, opts)[:id]
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
    obj.terms_sha1 = generate_terms_sha1(json)
    obj.save

    obj
  end


  def self.sequel_to_jsonmodel(obj, type, opts = {})
    json = super

    json.vocabulary = JSONModel(:vocabulary).uri_for(obj.vocab_id)

    json
  end


  def validate
    super
    validates_unique([:vocab_id, :terms], :message => "Subject must be unique")
    map_validation_to_json_property([:vocab_id, :terms], :terms)
  end

end
