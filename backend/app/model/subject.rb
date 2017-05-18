require_relative 'term'
require 'digest/sha1'

class Subject < Sequel::Model(:subject)
  include ASModel
  corresponds_to JSONModel(:subject)

  include ExternalDocuments
  include ExternalIDs
  include AutoGenerator
  include Publishable

  set_model_scope :global


  # Once everything is loaded, have the subject model set up a reciprocal
  # relationship for any model that depends on it.
  #
  # This saves us having to duplicate the list of models in both directions.
  ArchivesSpaceService.loaded_hook do
    Subject.define_relationship(:name => :subject,
                                :contains_references_to_types => proc {Subject.relationship_dependencies[:subject]})
  end


  many_to_many :term, :join_table => :subject_term, :order => :subject_term__id

  def_nested_record(:the_property => :terms,
                    :contains_records_of_type => :term,
                    :corresponding_to_association  => :term)

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

    Digest::SHA1.hexdigest(json.terms.map {|term| [term['term'], term['term_type']]}.inspect)
  end


  def self.create_from_json(json, opts = {})
    set_vocabulary(json, opts)
    super(json, opts.merge(:terms_sha1 => generate_terms_sha1(json)))
  end


  def self.ensure_exists(json, referrer)
    DB.attempt {
      self.create_from_json(json)
    }.and_if_constraint_fails {|exception|
      subject = find_matching(json)

      if !subject
        # The subject exists but we can't find it.  This could mean it was
        # created in a currently running transaction.  Abort this one to trigger
        # a retry.
        Log.info("Subject '#{json.terms}' seems to have been created by a currently running transaction.  Restarting this one.")
        sleep 5
        raise RetryTransaction.new
      end

      subject
    }
  end


  def self.find_matching(json)
    source_id = BackendEnumSource.id_for_value("subject_source", json.source)

    Subject.find(:vocab_id => JSONModel(:vocabulary).id_for(json.vocabulary),
                 :terms_sha1 => generate_terms_sha1(json),
                 :source_id => source_id)
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    self.class.set_vocabulary(json, opts)
    self[:terms_sha1] = self.class.generate_terms_sha1(json) # add a terms sha1 hash to allow for uniqueness test
    super
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    if opts[:calculate_linked_repositories]
      subjects_to_repositories = GlobalRecordRepositoryLinkages.new(self, :subject).call(objs)

      jsons.zip(objs).each do |json, obj|
        json.used_within_repositories = subjects_to_repositories.fetch(obj, []).map {|repo| repo.uri}
        json.used_within_published_repositories = subjects_to_repositories.fetch(obj, []).select{|repo| repo.publish == 1}.map {|repo| repo.uri}
      end
    end


    publication_status = ImpliedPublicationCalculator.new.for_subjects(objs)

    jsons.zip(objs).each do |json, obj|
      json.vocabulary = uri_for(:vocabulary, obj.vocab_id)
      json.is_linked_to_published_record = publication_status.fetch(obj)
    end

    jsons
  end


  def self.handle_delete(ids_to_delete)
    self.db[:subject_term].filter(:subject_id => ids_to_delete).delete

    super
  end


  def validate
    super

    if self[:source_id]
      validates_unique([:vocab_id, :source_id, :terms_sha1], :message => "Subject must be unique")
    else
      validates_unique([:vocab_id, :terms_sha1], :message => "Subject must be unique")
    end

    validates_unique([:vocab_id, :source_id, :authority_id], :message => "Subject heading identifier must be unique within source")
    map_validation_to_json_property([:vocab_id, :source_id, :authority_id], :authority_id)
    map_validation_to_json_property([:vocab_id, :terms_sha1], :terms)
    map_validation_to_json_property([:vocab_id, :source_id, :terms_sha1], :terms)
  end

end
