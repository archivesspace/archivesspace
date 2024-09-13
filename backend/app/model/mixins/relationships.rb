# A relationship is a one-to-one/one-to-many/many-to-many link between two
# records, where the link can have properties of its own.
#
# Each relationship generates a dynamic model class that represents the
# relationship and stores its properties in the database.  This code takes care
# of managing those relationship instances.  It:
#
#   * Generates classes in response to a 'define_relationship' definition
#
#   * Creates relationship instances for incoming JSON records (and linking up
#     the related objects
#
#   * Turns those relationships back into JSON when sequel_to_json is called
#
# Some bits of terminology used here:
#
#   * Referents -- the objects that an instance of a relationship refers to.
#     For example, if the relationship is "linked agent", the two referents will
#     be agent records.
#
#     Note that a relationship can refer to two objects of the same type.  This
#     leads to some awkwardness when trying to distinguish between the two.  As
#     a result, there's a common pattern of using "other_referent_than(obj)" to
#     mean "the referred record that isn't this one".
#
#   * Reference columns -- In the DB, each relationship is a row in a table.
#     The row contains columns for the relationship's properties, plus several
#     "reference columns".  These columns are foreign key references to records
#     in other tables.
#
#     Relationships between records of the same type create some awkwardness
#     here too, since links between two resource records (for example) require
#     two foreign key columns like 'resource_id_0' and 'resource_id_1'.  Now to
#     answer the question "Which resources involve the resource whose ID is 5?"
#     we need to check in both reference columns.
#
#     So, you'll see the "reference_columns_for(someclass)" helper used here.
#     This returns a list of the columns that might contain references to a
#     given record type.
#

# We'll create a concrete instance of this class for each defined relationship.
AbstractRelationship = Class.new(Sequel::Model) do

  include ObjectGraph

  # Create a relationship instance between two objects with a defined set of properties.
  def self.relate(obj1, obj2, properties)
    columns = if obj1.class == obj2.class
      # If our two related objects are of the same type, we'll get back multiple
      # columns here anyway
                raise ReferenceError.new("Can't relate an object to itself") if obj1.id == obj2.id

                self.reference_columns_for(obj1.class)
              else
                [self.reference_columns_for(obj1.class).first, self.reference_columns_for(obj2.class).first]
              end

    if columns.include?(nil)
      raise ("One of the relationship columns for #{obj1} and #{obj2} couldn't be found." +
             "  (Have you created the '#{table_name}' table?)")
    end

    values = Hash[columns.zip([obj1.id, obj2.id])].merge(properties)

    if [obj1, obj2].any? {|obj| obj.class.suppressible? && obj.suppressed == 1}
      # Suppress this new relationship if it points to a suppressed record
      values[:suppressed] = 1
    end

    # some objects ( like events? ) seem to leak their ids into the mix.
    values.reject! { |key| key == :id or key == "id"  }
    if ( obj1.is_a?(Location) or obj2.is_a?(Location) )
      values.reject! { |key| key == :jsonmodel_type or key == "jsonmodel_type" }
    end
    self.create(values)
  end


  # True if this relationship relates to obj
  def relates_to?(obj)
    self.class.reference_columns_for(obj.class).any? {|col|
      self[col] == obj.id
    }
  end


  # Find any relationship instances that reference 'merge_candidates' and modify them to
  # refer to 'merge_destination' instead.
  def self.transfer(merge_destination, merge_candidates)
    merge_destination_columns = self.reference_columns_for(merge_destination.class)

    merge_candidates_by_model = merge_candidates.reject {|v| (v.class == merge_destination.class) && (v.id == merge_destination.id)}.group_by(&:class)

    # We're going to have to handle container profiles separately since merge_candidate
    # cp relationships have to be compared against one another prior to merging.
    # We'll just use this method to store container profile relationships then
    # actually handle container profile relationships in the separate
    # `cleanup_container_profile_relationships` method below
    merge_candidate_container_profiles = []

    merge_candidates_by_model.each do |merge_candidate_model, vics|

      confirm_accepts_merge_destination(merge_candidate_model, vics)
      merge_candidate_columns = self.reference_columns_for(merge_candidate_model)

      merge_candidate_columns.each do |merge_candidate_col|

        vics.each do |merge_candidate|

          who_participates_with(merge_candidate).each do |parent|
            parent_col = reference_columns_for(parent.class).first
            # Find any relationship where the current column contains a reference to
            # our merge_candidate
            self.exclude(parent_col => nil).filter(merge_candidate_col => vics.map(&:id)).each do |relationship|
              merge_destination_pre = find_by_participant(merge_destination)

              # Remove this relationship's reference to the merge_candidate
              relationship[merge_candidate_col] = nil

              # When merging top containers, you also have to deal with the fact
              # that subcontainers and instances may also need to be deleted.  This
              # array stores records that will be deleted in cleanup_duplicates.
              dups = []

              # Now add a new reference to the merge_destination (which, if the merge_candidate and
              # merge_destination are of different types, might require updating a different
              # column to the one we just set to NULL)
              merge_destination_columns.each do |merge_destination_col|

                if relationship[merge_destination_col]
                  # This column is already used to reference the other record in our
                  # relationship so we'll skip over it.  But while we're here, make
                  # sure we're not about to create a circular relationship.

                  if relationship[merge_destination_col] == merge_destination.id
                    raise "Transfer would create a circular relationship!"
                  end

                elsif relationship.is_a?(Relationships::SubContainerTopContainerLink) && !find_by_participant(merge_destination).empty?
                  identify_duplicate_containers(merge_destination, relationship, merge_destination_col, dups)

                elsif relationship.is_a?(Relationships::ContainerProfileTopContainerProfile)
                  merge_candidate_container_profiles << relationship

                else
                  merge_destination_pre.each do |pre|
                    if pre[parent_col] == relationship[parent_col]
                      dups << relationship
                    end
                  end
                  transfer_relationship_to_merge_destination(relationship, merge_destination_col, merge_destination, true)
                  break
                end

              end

              relationship[:system_mtime] = Time.now
              relationship[:user_mtime] = Time.now

              relationship.save

              cleanup_duplicates(dups)
            end
          end
        end
      end
    end

    cleanup_container_profile_relationships(merge_candidate_container_profiles, merge_destination)

    # Finally, reindex the merge_destination record for good measure (and, in the case of
    # top containers, to update the associated collections)
    merge_destination[:system_mtime] = Time.now
    merge_destination[:user_mtime] = Time.now

    merge_destination.save
  end


  # If we're merging a record of type A with relationship R into a record of
  # type B, type B must also support that relationship type.  If it doesn't,
  # we risk losing data through the merge and should abort.
  def self.confirm_accepts_merge_destination(merge_candidate_model, vics)
    unless participating_models.include?(merge_candidate_model)
      found = self.find_by_participant_ids(merge_candidate_model, vics.map(&:id))

      unless found.empty?
        raise ReferenceError.new("#{merge_candidate_model} to be merged has data for relationship #{self}, but merge_destination record doesn't support it.")
      end
    end
  end


  def self.transfer_relationship_to_merge_destination(relationship, merge_destination_col, merge_destination, skip_refresh=false)
    relationship[merge_destination_col] = merge_destination.id
    unless skip_refresh
      relationship[:system_mtime] = Time.now
      relationship[:user_mtime] = Time.now

      relationship.save
    end
  end


  # ANW-952: After merging objects together you may be left with two
  # relationships that link to the same post-merge record.  This deletes
  # those duplicated relationships after the merge process is complete.
  def self.cleanup_duplicates(dups)
    if !dups.empty?
      dups.each {|d| d.delete}
    end
  end


  def self.identify_duplicate_containers(merge_destination, relationship, merge_destination_col, dups)
    find_by_participant(merge_destination).each do |merge_destination_relationship|
      subcontainer = SubContainer[relationship[:sub_container_id]]
      merge_destination_subcontainer = SubContainer[merge_destination_relationship[:sub_container_id]]
      # Only proceed if the subcontainer record is empty
      if [:type_2_id, :indicator_2, :type_3_id, :indicator_3].map {|k| subcontainer[k]}.compact.empty?
        instance = Instance[subcontainer[:instance_id]]
        merge_destination_instance = Instance[merge_destination_subcontainer[:instance_id]]
        [:accession_id, :archival_object_id, :resource_id].each do |p|
          next if instance[p].nil?
          # If subcontainer is empty and if the subcontainer's instance
          # record links to the same parent record (ao, accession, or
          # resource), delete the subcontainer and the instance.
          if instance[p] == merge_destination_instance[p]
            dups << subcontainer
            dups << instance
            break
          else
            transfer_relationship_to_merge_destination(relationship, merge_destination_col, merge_destination, true)
            break
          end
        end
      else
        transfer_relationship_to_merge_destination(relationship, merge_destination_col, merge_destination, true)
        break
      end
    end
  end


  # When merging top containers there is the possibility that multiple container
  # profiles might be relinked to the surviving top container, despite the fact
  # that top containers should only ever have on linked container profile.
  # While future work should actually make db-level/schema-level changes to
  # prohibit linking multiple container profiles to a single top container, in the
  # interim, this method ensures that container profile relationships are handled
  # separately from other linked record transfers and ensures only one container
  # profile (or, conditionally, no container profiles) survives the merge process.
  def self.cleanup_container_profile_relationships(merge_candidate_container_profiles, merge_destination)
    merge_destination_relationship = nil
    find_by_participant(merge_destination).each do |merge_destination_rlshp|
      if !merge_destination_rlshp.nil? && merge_destination_rlshp.is_a?(Relationships::ContainerProfileTopContainerProfile)
        merge_destination_relationship = merge_destination_rlshp
      end
    end
    merge_candidate_container_profiles_unique = merge_candidate_container_profiles.map {|v| v[:container_profile_id]}
    # If the merge_destination has a linked container profile already, delete all merge_candidate
    # container profile relationships
    if !merge_destination_relationship.nil?
      cleanup_duplicates(merge_candidate_container_profiles)
    else
      # If the array of merge_candidates only has one container profile relationship
      # transfer that relationship over to the merge merge_destination
      if merge_candidate_container_profiles.count == 1
        merge_candidate_container_profile = merge_candidate_container_profiles.first
        transfer_relationship_to_merge_destination(merge_candidate_container_profile, :top_container_id, merge_destination)
      elsif merge_candidate_container_profiles.count > 1
        # If the array of merge_candidates has multiple container profile relationships
        # but they all link to the same container profile, transfer the first
        # relationship to the merge merge_destination and delete the rest
        if merge_candidate_container_profiles_unique.uniq.count == 1
          merge_candidate_container_profile = merge_candidate_container_profiles.first
          transfer_relationship_to_merge_destination(merge_candidate_container_profile, :top_container_id, merge_destination)
          merge_candidate_container_profiles.shift
          cleanup_duplicates(merge_candidate_container_profiles)
        # If the array of merge_candidates has multiple container profile relationships
        # and they link to different container profiles, delete all merge_candidate
        # container profile relationships
        else
          cleanup_duplicates(merge_candidate_container_profiles)
        end
      end
    end
  end

  # Return the value of 'property' for any relationship involving 'obj'.
  def self.values_for_property(obj, property)
    result = []

    self.reference_columns_for(obj.class).each do |col|
      self.filter(col => obj.id).select(property).distinct.each do |relationship|
        result << relationship[property]
      end
    end

    result
  end


  def self.to_s
    "<#Relationship #{table_name}>"
  end

  # Methods for defining relationships
  def self.set_json_property(property); @json_property = property; end

  def self.json_property; @json_property; end


  def self.set_participating_models(models); @participating_models = models; end

  def self.participating_models; @participating_models or raise "No participating models set"; end


  def self.set_wants_array(val); @wants_array = val; end

  def self.wants_array?; @wants_array; end


  # Return a list of the relationship instances that refer to 'obj'.
  def self.find_by_participant(obj)
    # Find all columns in our relationship's table that are named after obj's table
    # These will contain references to instances of obj's class
    reference_columns = self.reference_columns_for(obj.class)
    filters = reference_columns.map {|col| { col => obj.id }}

    return [] if filters.empty?

    matching_relationships = self.filter(Sequel.|(*filters)).all
    our_columns = participating_models.map {|m| reference_columns_for(m)}.flatten(1)

    # Reject any relationship that links to obj.id but not another model we're interested in.
    matching_relationships.reject! {|relationship|
      !our_columns.any? {|c|
        relationship[c] && (!reference_columns_for(obj.class).include?(c) || relationship[c] != obj.id)
      }
    }

    matching_relationships.sort_by {|relationship| relationship[:aspace_relationship_position]}
  end


  # Return the list of relationships involving any of the records named in
  # 'participant_ids'
  def self.find_by_participant_ids(participant_model, participant_ids)
    result = []

    return result if participant_ids.empty?
    reference_columns = self.reference_columns_for(participant_model)

    filters = reference_columns.map {|col| { col => participant_ids }}

    return [] if filters.empty?

    self.filter(Sequel.|(*filters)).each do |relationship|
      result << relationship
    end

    result
  end


  # Return a mapping of records and the relationships they participate in.
  # Input is a list like:
  #
  #  [rec1, rec2, ...]
  #
  # and the result is:
  #
  #  { rec1 => [relationship1, relationship2, ...],
  #    rec2 => [relationship3, ...],
  #    ...}
  #
  def self.find_by_participants(objs)
    result = {}

    return result if objs.empty?
    reference_columns = self.reference_columns_for(objs.first.class)

    objects_by_id = objs.group_by {|obj| obj.id}


    reference_columns.each do |col|
      self.eager(self.associations).filter(col => objects_by_id.keys).all.each do |relationship|
        obj = objects_by_id[relationship[col]].first
        result[obj] ||= []
        result[obj] << relationship
      end
    end

    result.each do |obj, relationships|
      relationships.sort_by! {|relationship| relationship[:aspace_relationship_position]}
    end

    result
  end


  # Return a list of the objects that are related to 'obj' via one of our
  # relationships
  def self.who_participates_with(obj)
    # Find all relationships involving obj
    relationships = self.find_by_participant(obj)

    relationships.map {|relationship|
      relationship.other_referent_than(obj)
    }
  end


  # A list of all DB columns that might contain a foreign key reference to a
  # record of type 'model'.
  MODEL_COLUMNS_CACHE = java.util.concurrent.ConcurrentHashMap.new(128)

  def self.reference_columns_for(model)
    key = [self, model]

    if columns = MODEL_COLUMNS_CACHE.get(key)
      columns
    else
      MODEL_COLUMNS_CACHE.put(key,
                              self.db_schema.keys.select { |column_name|
                                [
                                  model.table_name.downcase.to_s + "_id",
                                  model.table_name.downcase.to_s + "_id_0",
                                  model.table_name.downcase.to_s + "_id_1",
                                ].include?(column_name.to_s.downcase)
                              })

      MODEL_COLUMNS_CACHE.get(key)
    end
  end


  def self.handle_suppressed(ids, val)
    ASModel.update_suppressed_flag(self.filter(:id => ids), val)
  end


  def self.handle_delete(ids)
    self.filter(:id => ids).delete
  end


  def self.my_jsonmodel(ok_if_missing = false)
    raise("No corresponding JSONModel set for model #{self.inspect}") unless ok_if_missing
  end

  def self.publishable?
    self.columns.include?(:publish)
  end

  # The properties for this relationship instance
  def properties
    self.values
  end


  # The record referred to by the current relationship that isn't 'obj'.
  def other_referent_than(obj)
    self.class.participating_models.each {|model|
      self.class.reference_columns_for(model).each {|column|
        if self[column] && (model != obj.class || self[column] != obj.id)
          return model.respond_to?(:any_repo) ? model.any_repo[self[column]] : model[self[column]]
        end
      }
    }

    nil
  end


  # The URI of the record referred to by the current relationship that isn't
  # 'obj'.
  def uri_for_other_referent_than(obj)
    self.class.participating_models.each {|model|
      self.class.reference_columns_for(model).each {|column|
        if self[column] && (model != obj.class || self[column] != obj.id)
          return model.my_jsonmodel.uri_for(self[column],
                                            :repo_id => RequestContext.get(:repo_id))
        end
      }
    }

    raise "Failed to find a URI for other referent in #{self}: #{obj.id}"
  end


  def self.is_relationship?
    true
  end

end


module Relationships

  def self.included(base)
    base.instance_eval do
      @relationships ||= {}
      @relationship_dependencies ||= {}
    end

    base.extend(ClassMethods)
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    obj = super

    # Call this before and after the change since relationships might have been
    # removed and the previously linked objects might need reindexing.
    trigger_reindex_of_dependants
    self.class.apply_relationships(obj, json, opts)
    trigger_reindex_of_dependants

    obj
  end


  # Store a list of the relationships that this object participates in.  Saves
  # looking up the DB for each one.
  attr_reader :cached_relationships

  def cache_relationships(relationship_defn, relationship_objects)
    @cached_relationships ||= {}
    @cached_relationships[relationship_defn] = relationship_objects
  end


  def trigger_reindex_of_dependants
    # Update the mtime of any record with a relationship to this one.  This
    # encourages the indexer to reindex records when, say, a subject is renamed.
    #
    # Once we have our list of unique models, inform each of them that our
    # instance has been updated (using a class method defined below).
    self.class.dependent_models.each do |model|
      model.touch_mtime_of_anyone_related_to(self)
    end
  end


  # Added to the mixed in class itself: return a list of the relationship
  # instances involving this object
  def my_relationships(name)
    self.class.find_relationship(name).find_by_participant(self)
  end


  # Return all object instances that are related to the current record by the
  # relationship named by 'name'.
  def related_records(name)
    relationship = self.class.find_relationship(name)
    records = relationship.who_participates_with(self)

    relationship.wants_array? ? records : records.first
  end


  # Find all relationships involving the records in 'merge_candidates' and rewrite them
  # to refer to us instead.
  def assimilate(merge_candidates)
    merge_candidates = merge_candidates.reject {|v| (v.class == self.class) && (v.id == self.id)}

    self.class.relationship_dependencies.each do |relationship, models|
      models.each do |model|
        model.transfer(relationship, self, merge_candidates)
      end
    end

    DB.attempt {
      merge_candidates.each(&:delete)
    }.and_if_constraint_fails {
      raise MergeRequestFailed.new("Can't complete merge: record still in use")
    }

    trigger_reindex_of_dependants
  end


  def transfer_to_repository(repository, transfer_group = [])
    if transfer_group.empty?
      do_id = self.class == DigitalObject ? self[:id] : 0
    else
      do_id = transfer_group.first.class == DigitalObject ? transfer_group.first[:id] : 0
    end

    unless do_id == 0
      return unless do_transferable?(do_id)
    end

    # When a record is being transferred to another repository, any
    # relationships it has to records within the current repository must be
    # cleared.

    predicate = proc {|relationship|
      referent = relationship.other_referent_than(self)

      # Delete the relationship if we're repository-scoped and the referent is
      # in the old repository.  Don't worry about relationships to any of the
      # records that are going to be transferred along with us (listed in
      # transfer_group)
      (referent.class.model_scope == :repository &&
       referent.repo_id != repository.id &&
       !transfer_group.any? {|obj| obj.id == referent.id && obj.model == referent.model})
    }


    ([self.class] + self.class.dependent_models).each do |model|
      model.delete_existing_relationships(self, false, false, predicate)
    end

    super
  end


  def do_transferable?(do_id)
    # ANW-151: Digital objects should not be transferable if they have instance links to other repository-scoped record types. If not transferrable, we throw an error and abort the transfer.
    do_relationship = DigitalObject.find_relationship(:instance_do_link)

    instances = do_relationship
    .select(:instance_id).filter(:digital_object_id => do_id)
    .map {|row| row[:instance_id]}

    if instances.empty?
      true
    else
      do_has_link_error(instances)
      false
    end
  end


  def do_has_link_error(instances)
    # Abort the transfer and provide the list of top-level records that are preventing it from completing.
    exception = TransferConstraintError.new

    ASModel.all_models.each do |model|
      next unless model.associations.include?(:instance)

      model
        .eager_graph(:instance)
        .filter(:instance__id => instances)
        .select(Sequel.qualify(model.table_name, :id))
        .each do |row|
          exception.add_conflict(model.my_jsonmodel.uri_for(row[:id], :repo_id => self.class.active_repository),
                          {:json_property => 'instances',
                           :message => "DIGITAL_OBJECT_HAS_LINK"})
        end
    end

    raise exception
    return
  end


  module ClassMethods


    def calculate_object_graph(object_graph, opts = {})
      # For each relationship involving a resource
      self.relationships.each do |relationship_defn|
        # Find any relationship of this type involving any record mentioned in
        # object graph

        object_graph.each do |model, id_list|
          next unless relationship_defn.participating_models.include?(model)

          linked_relationships = relationship_defn.find_by_participant_ids(model, id_list).map {|row|
            row[:id]
          }

          object_graph.add_objects(relationship_defn, linked_relationships)
        end
      end

      super
    end


    # Reset relationship definitions for the current class
    def clear_relationships
      @relationships = {}
    end


    def relationships
      @relationships.values
    end


    def relationship_dependencies
      @relationship_dependencies
    end


    def dependent_models
      @relationship_dependencies.values.flatten.uniq
    end


    def find_relationship(name, noerror = false)
      @relationships[name] or (noerror ? nil : raise("Couldn't find #{name} in #{@relationships.inspect}"))
    end

    # Define a new relationship.
    def define_relationship(opts)
      [:name, :contains_references_to_types].each do |p|
        opts[p] or raise "No #{p} given"
      end

      base = self

      ArchivesSpaceService.loaded_hook do
        # We hold off actually setting anything up until all models have been
        # loaded, since our relationships may need to reference a model that
        # hasn't been loaded yet.
        #
        # This is also why the :contains_references_to_types property is a proc
        # instead of a regular array--we don't want to blow up with a NameError
        # if the model hasn't been loaded yet.


        related_models = opts[:contains_references_to_types].call

        clz = Class.new(AbstractRelationship) do
          table = "#{opts[:name]}_rlshp".intern
          set_dataset(table)
          set_primary_key(:id)

          if !self.db.table_exists?(self.table_name)
            Log.warn("Table doesn't exist: #{self.table_name}")
          end

          set_participating_models([base, *related_models].uniq)
          set_json_property(opts[:json_property])
          set_wants_array(opts[:is_array].nil? || opts[:is_array])
        end

        opts[:class_callback].call(clz) if opts[:class_callback]

        @relationships[opts[:name]] = clz

        related_models.each do |model|
          model.include(Relationships)
          model.add_relationship_dependency(opts[:name], base)
        end

        # Give the new relationship class a name to help with debugging
        # Example: Relationships::ResourceSubject
        Relationships.const_set(self.name + opts[:name].to_s.camelize, clz)

      end
    end


    # Delete all existing relationships for 'obj'.
    def delete_existing_relationships(obj, bump_lock_version_on_referent = false, force = false, predicate = nil)
      relationships.each do |relationship_defn|

        next if (!relationship_defn.json_property && !force)

        if (relationship_defn.json_property &&
            (!self.my_jsonmodel.schema['properties'][relationship_defn.json_property] ||
             self.my_jsonmodel.schema['properties'][relationship_defn.json_property]['readonly'] === 'true'))

          # Don't delete instances of relationships that are read-only in this direction.
          next
        end


        relationship_defn.find_by_participant(obj).each do |relationship|

          # If our predicate says to spare this relationship, leave it alone
          next if predicate && !predicate.call(relationship)

          # If we're deleting a relationship without replacing it, bump the lock
          # version on the referent object so it doesn't accidentally get
          # re-added.
          #
          # This will also encourage the indexer to pick up changes on deletion
          # (e.g. a subject gets deleted and we want to reindex the records that
          # reference it)
          if bump_lock_version_on_referent
            referent = relationship.other_referent_than(obj)
            DB.increase_lock_version_or_fail(referent) if referent
          end

          relationship.delete
        end
      end
    end


    # Create set of relationships for a given update
    def apply_relationships(obj, json, opts, new_record = false)
      delete_existing_relationships(obj) if !new_record

      @relationships.each do |relationship_name, relationship_defn|
        property_name = relationship_defn.json_property

        # If there's no property name, the relationship is just read-only
        next if !property_name

        # For each record reference in our JSON data
        ASUtils.as_array(json[property_name]).each_with_index do |reference, idx|
          record_type = parse_reference(reference['ref'], opts)

          referent_model = relationship_defn.participating_models.find {|model|
            model.my_jsonmodel.record_type == record_type[:type]
          } or raise "Couldn't find model for #{record_type[:type]}"

          referent = referent_model[record_type[:id]]

          if !referent
            raise ReferenceError.new("Can't relate to non-existent record: #{reference['ref']}")
          end

          # Create a new relationship instance linking us and them together, and
          # add the properties from the JSON request to the relationship
          properties = reference.clone.tap do |properties|
            properties.delete('ref')
          end

          properties[:aspace_relationship_position] = idx
          properties[:system_mtime] = Time.now
          properties[:user_mtime] = Time.now

          relationship_defn.relate(obj, referent, properties)

          # If this is a reciprocal relationship (defined on both participating
          # models), update the referent's lock version to ensure that a
          # concurrent update to that object won't clobber our changes.

          if referent_model.find_relationship(relationship_name, true) && !opts[:system_generated]
            DB.increase_lock_version_or_fail(referent)
          end
        end
      end
    end


    # Find all of the relationships involving 'objects' and tell each object to
    # cache its relationships.  This is an optimisation: avoids the need for one
    # SELECT for every relationship lookup by pulling back all relationships at
    # once.
    def eager_load_relationships(objects, relationships_to_load = nil)
      relationships_to_load = relationships unless relationships_to_load

      relationships_to_load.each do |relationship_defn|
        # For each defined relationship
        relationships_map = relationship_defn.find_by_participants(objects)

        objects.each do |obj|
          obj.cache_relationships(relationship_defn, relationships_map[obj])
        end
      end
    end


    def create_from_json(json, opts = {})
      obj = super
      apply_relationships(obj, json, opts, true)
      obj
    end


    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      return jsons if opts[:skip_relationships]

      eager_load_relationships(objs, relationships.select {|relationship_defn| relationship_defn.json_property})

      jsons.zip(objs).each do |json, obj|
        relationships.each do |relationship_defn|
          property_name = relationship_defn.json_property

          # If we don't need this property in our return JSON, skip it.
          next unless property_name

          # For each defined relationship
          relationships = if obj.cached_relationships
                            # Use the eagerly fetched relationships if we have them
                            Array(obj.cached_relationships[relationship_defn])
                          else
                            relationship_defn.find_by_participant(obj)
                          end

          json[property_name] = relationships.map {|relationship|
            next if RequestContext.get(:enforce_suppression) && relationship.suppressed == 1

            # Return the relationship properties, plus the URI reference of the
            # related object
            values = ASUtils.keys_as_strings(relationship.properties)
            values['ref'] = relationship.uri_for_other_referent_than(obj)

            values
          }

          if !relationship_defn.wants_array?
            json[property_name] = json[property_name].first
          end
        end
      end

      jsons
    end


    # Find all instances of the referring class that have a relationship with 'obj'
    # Spans all defined relationships.
    def instances_relating_to(obj)
      relationships.map {|relationship_defn|
        relationship_defn.who_participates_with(obj)
      }.flatten
    end


    def add_relationship_dependency(relationship_name, clz)
      @relationship_dependencies[relationship_name] ||= []
      @relationship_dependencies[relationship_name] << clz
    end


    def transfer(relationship_name, merge_destination, merge_candidates)
      relationship = find_relationship(relationship_name)
      relationship.transfer(merge_destination, merge_candidates)
    end

    # This notifies the current model that an instance of a related model has
    # been changed.  We respond by finding any of our own instances that refer
    # to the updated instance and update their mtime.
    def touch_mtime_of_anyone_related_to(obj)
      now = Time.now

      relationships.map do |relationship_defn|
        models = relationship_defn.participating_models

        # If this relationship doesn't link to records of type `obj`, we're not
        # interested.
        next unless models.include?(obj.class)

        their_ref_columns = relationship_defn.reference_columns_for(obj.class)
        my_ref_columns = relationship_defn.reference_columns_for(self)
        their_ref_columns.each do |their_col|
          my_ref_columns.each do |my_col|

            # This one type of relationship (between the software agent and
            # anything else) was a particular hotspot when analyzing real-world
            # performance.
            #
            # Terrible to have to do this, but the MySQL optimizer refuses
            # to use the primary key on agent_software because it (often)
            # only has one row.
            #
            if DB.supports_join_updates? &&
               self.table_name == :agent_software &&
               relationship_defn.table_name == :linked_agents_rlshp

              DB.open do |db|
                id_str = Integer(obj.id).to_s

                db.run("UPDATE `agent_software` FORCE INDEX (PRIMARY) " +
                       " INNER JOIN `linked_agents_rlshp` " +
                       "ON (`linked_agents_rlshp`.`agent_software_id` = `agent_software`.`id`) " +
                       "SET `agent_software`.`system_mtime` = NOW() " +
                       "WHERE (`linked_agents_rlshp`.`archival_object_id` = #{id_str})")
              end

              return
            end

            # Example: if we're updating a subject record and want to update
            # the timestamps of any linked archival object records:
            #
            #  * self = ArchivalObject
            #  * relationship_defn is subject_rlshp
            #  * obj = #<Subject instance that was updated>
            #  * their_col = subject_rlshp.subject_id
            #  * my_col = subject_rlshp.archival_object_id


            # Join our model class table to the relationship that links it to `obj`
            #
            # For example: join ArchivalObject to subject_rlshp
            #              join Instance to instance_do_link_rlshp
            base_ds = self.join(relationship_defn.table_name,
                                Sequel.qualify(relationship_defn.table_name, my_col) =>
                                       Sequel.qualify(self.table_name, :id))

            # Limit only to the object of interest--we only care about records
            # involved in a relationship with the record that was updated (obj)
            base_ds = base_ds.filter(Sequel.qualify(relationship_defn.table_name, their_col) => obj.id)

            # Now update the mtime of any top-level record that links to that
            # relationship.
            self.update_toplevel_mtimes(base_ds, now)
          end
        end
      end
    end

    # Given a `dataset` that links the current record type to some relationship
    # type, set the modification time of the nearest top-level record to
    # `new_mtime`.
    #
    # If the current record type links directly to the relationship (such as an
    # Archival Object linking to a Subject), then this is easy: we just update
    # the modification time of the Archival Object.
    #
    # If the current record is a nested record (such as an Instance linked to a
    # Digital Object), we want to continue up the chain, linking the Instance
    # nested record to its Accession/Resource/Archival Object parent record, and
    # then update the modification time of that parent.
    #
    # And if the nested record has a nested record has a nested record has a
    # relationship... well, you get the idea.  We handle the recursive case too!
    #
    def update_toplevel_mtimes(dataset, new_mtime)
      if self.enclosing_associations.empty?
        # If we're not enclosed by anything else, we're a top-level record.  Do the final update.
        if DB.supports_join_updates?
          # Fast path!  Use a join update.
          dataset.update(Sequel.qualify(self.table_name, :system_mtime) => new_mtime)
        else
          # Slow path.  Subselect.
          ids_to_touch = dataset.select(Sequel.qualify(self.table_name, :id))
          self.filter(:id => ids_to_touch).update(:system_mtime => new_mtime)
        end
      else
        # Otherwise, we're a nested record
        self.enclosing_associations.each do |association|
          parent_model = association[:model]

          # Link the parent into the current dataset
          parent_ds = dataset.join(parent_model.table_name,
                                   Sequel.qualify(self.table_name, association[:key]) =>
                                          Sequel.qualify(parent_model.table_name, :id))

          # and tell it to continue!
          parent_model.update_toplevel_mtimes(parent_ds, new_mtime)
        end
      end
    end

  end
end
