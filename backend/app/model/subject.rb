require_relative 'term'
require 'digest/sha1'
require_relative 'auto_generator'

class Subject < Sequel::Model(:subject)
  include ASModel
  corresponds_to JSONModel(:subject)

  include ExternalDocuments
  include ExternalIDs
  include AutoGenerator

  set_model_scope :global

  many_to_many :term, :join_table => :subject_term, :order => :subject_term__id

  def_nested_record(:the_property => :terms,
                    :contains_records_of_type => :term,
                    :corresponding_to_association  => :term,
                    :always_resolve => true)

  auto_generate :property => :title, 
                :generator => proc  { |json|
                                json["terms"].map do |t|
                                  if t.kind_of? String
                                    Term[JSONModel(:term).id_for(t)].term
                                  else
                                    t["term"]
                                  end
                                end.join(" -- ")
                              }


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

    obj.terms_sha1 = generate_terms_sha1(json) # add a terms sha1 hash to allow for uniqueness test

    obj.save

    obj
  end


  def update_from_json(json, opts = {}, apply_linked_records = true)
    self.class.set_vocabulary(json, opts)
    obj = super

    obj.terms_sha1 = self.class.generate_terms_sha1(json) # add a terms sha1 hash to allow for uniqueness test

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
