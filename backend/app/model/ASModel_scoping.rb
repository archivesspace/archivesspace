module ASModel
  # Code that keeps the records of different repositories isolated and hiding suppressed records.

  def self.update_suppressed_flag(dataset, val)
    dataset.update(:suppressed => (val ? 1 : 0),
                   :system_mtime => Time.now)
  end


  def self.update_publish_flag(dataset, val)
    dataset.update(:publish => (val ? 1 : 0),
                   :system_mtime => Time.now)
  end



  module ModelScoping

    def self.included(base)
      base.extend(ClassMethods)
    end


    def uri
      # Bleh!
      self.class.uri_for(self.class.my_jsonmodel.record_type, self.id)
    end


    def set_suppressed(val)
      unless self.class.suppressible?
        raise "Suppression not supported for this class: #{self.class.inspect}"
      end

      object_graph = self.object_graph

      object_graph.each do |model, ids_to_change|
        model.handle_suppressed(ids_to_change, val)
      end

      RequestContext.open(:enforce_suppression => false) do
        self.class.fire_update(self.class.to_jsonmodel(self.id), self)
      end

      if model == Resource || model == Accession
        reindex_top_containers
      end

      val
    end


    # Mixins will hook in here to add their own publish actions.
    def publish!(setting = true)
      object_graph = self.object_graph

      object_graph.each do |model, ids|
        next unless model.publishable?

        model.handle_publish_flag(ids, setting)
      end

      if model == Resource || model == Accession
        reindex_top_containers
      end

    end


    def unpublish!
      publish!(false)
    end


    module ClassMethods

      def enable_suppression
        @suppressible = true
      end


      def enforce_suppression?
        RequestContext.get(:enforce_suppression)
      end


      def suppressible?
        @suppressible
      end

      def handle_suppressed(ids, val)
        if suppressible?
          ASModel.update_suppressed_flag(self.filter(:id => ids), val)
        end
      end


      def publishable?
        self.columns.include?(:publish)
      end


      def handle_publish_flag(ids, val)
        ASModel.update_publish_flag(self.filter(:id => ids), val)
      end


      def set_model_scope(value)
        if ![:repository, :global].include?(value)
          raise "Failure for #{self}: Model scope must be set as :repository or :global"
        end

        if value == :repository
          # Replace the default row_proc with one that fetches the request row,
          # but blows up if that row isn't from the currently active repository.
          #
          # The idea here is as follows:
          #
          #  * You have a repository-scoped model whose records you are going to
          #    fetch.
          #
          #  * Depending on your query, it's possible to return records that
          #    belong to a different repository to the one that's active for the
          #    current request.  We want to avoid this!
          #
          #  * So, if you use model.this_repo, we'll add the right filters to
          #    scope to the current repository and you don't have to think about
          #    it further.
          #
          #  * Or you can use model.any_repo to explicitly say that you'll be
          #    returning records from multiple repositories and know what you're
          #    doing.
          #
          #  * If you don't use either of these dataset methods, we'll fall back
          #    to checking the records pulled back at runtime to catch any
          #    cross-repository accesses.  We do this using a Sequel `row_proc`
          #    function.  If this ever fails, it's a programming error.
          #

          # First we stash away the original (unchecked) dataset for use internally.
          dataset_module do
            # Give ourselves an instance variable on the model to hang the original dataset...
            attr_accessor :raw_dataset
          end

          # ... and use it
          self.raw_dataset = self.dataset.clone

          # Then mutate the default dataset to include our row_proc that will
          # provide the fallback repository checking we want.
          orig_row_proc = self.dataset.row_proc
          repo_scoped_model = self

          self.dataset.row_proc = proc do |row|
            if row.has_key?(:repo_id) && row[:repo_id] != repo_scoped_model.active_repository
              raise ("ASSERTION FAILED: #{row.inspect} has a repo_id of " +
                     "#{row[:repo_id]} but the active repository is #{repo_scoped_model.active_repository}")
            end

            orig_row_proc.call(row)
          end

          # Finally, define our accessors.  They use the raw dataset to bypass
          # the row_proc check we just added, since they're "pre-screened".
          dataset_module do
            # Provide a new '.this_repo' method on this model class that only
            # returns records that belong to the current repository.
            def this_repo
              filter = model.columns.include?(:repo_id) ? {:repo_id => model.active_repository} : {}

              if model.suppressible? && model.enforce_suppression?
                filter[Sequel.qualify(model.table_name, :suppressed)] = 0
              end

              model.raw_dataset.filter(filter)
            end


            def any_repo(dataset = false)
              my_ds = dataset || model.raw_dataset
              if model.suppressible? && model.enforce_suppression?
                my_ds.filter(Sequel.qualify(model.table_name, :suppressed) => 0)
              else
                my_ds
              end
            end

          end

        else
          # Globally scoped models

          # These accessors are redundant, but useful in cases where we're
          # working with model classes and don't know/care whether they're
          # repository-scoped or not.  For example, when we're resolving URIs...
          def_dataset_method(:any_repo) do
            self
          end

          def_dataset_method(:this_repo) do
            self
          end

        end

        @model_scope = value
      end


      def model_scope(noerror = false)
        @model_scope or
          if noerror
            nil
          else
            raise "set_model_scope definition missing for model #{self}"
          end
      end


      # Like JSONModel.parse_reference, but enforce repository restrictions
      def parse_reference(uri, opts)
        ref = JSONModel.parse_reference(uri, opts)

        return nil if !ref

        # If the current model is repository scoped, and the reference is a
        # repository-scoped URI, make sure they're talking about the same
        # repository.
        if self.model_scope == :repository && ref[:repository] && ref[:repository] != JSONModel(:repository).uri_for(active_repository)
          raise ReferenceError.new("Invalid URI reference for this (#{active_repository}) repo: '#{uri}'")
        end

        ref
      end


      def active_repository
        repo = RequestContext.get(:repo_id)

        if model_scope == :repository and repo.nil?
          raise "Missing repo_id for request!"
        end

        repo
      end


      def uri_for(jsonmodel, id, opts = {})
        JSONModel(jsonmodel).uri_for(id, opts.merge(:repo_id => self.active_repository))
      end

    end
  end
end
