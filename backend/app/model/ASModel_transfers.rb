module ASModel
  # Code for moving records between repositories
  module RepositoryTransfers

    def self.included(base)
      base.extend(ClassMethods)
    end


    def transfer_to_repository(target_repository, transfer_group = [])
      if self.class.columns.include?(:repo_id)

        source_repository = Repository[self.repo_id]

        # Do the update in the cheapest way possible (bypassing save hooks, etc.)
        self.class.filter(id: self.id).update(repo_id: target_repository.id,
                                                 system_mtime: Time.now)

        # Mark the old URI as deleted (if we can locate the source repo)
        if source_repository
          RequestContext.open(repo_id: source_repository.id) do
            Tombstone.create(uri: self.uri)
            DB.after_commit do
              RealtimeIndexing.record_delete(self.uri)
            end
          end
        end

        RequestContext.open(repo_id: target_repository.id) do
          # if this record has been in the target_repository before, it might have
          # an old tombstone lying around.
          Tombstone.filter(uri: self.uri).delete
          # Create an event if this is the top-level record being transferred.
          if transfer_group.empty?
            Event.for_repository_transfer(source_repository, target_repository, self)
          end
        end
      end

      # Tell any nested records to transfer themselves too
      self.class.nested_records.each do |nested_record_defn|
        association = nested_record_defn[:association][:name]
        association_dataset = self.send("#{association}_dataset".intern)
        nested_model = Kernel.const_get(nested_record_defn[:association][:class_name])

        association_dataset.select(Sequel.qualify(nested_model.table_name, :id)).all.each do |nested_record|
          nested_record.transfer_to_repository(target_repository, transfer_group + [self])
        end
      end
    end


    module ClassMethods

      def report_incompatible_constraints(source_repository, target_repository)
        problems = {}

        repo_unique_constraints.each do |constraint|
          target_repo_values = self.filter(:repo_id => target_repository.id).
                                    select(constraint[:property])

          overlapping_in_source = self.filter(:repo_id => source_repository.id,
                                              constraint[:property] => target_repo_values).
                                       select(:id)

          if overlapping_in_source.count > 0
            overlapping_in_source.each do |obj|
              problems[obj.uri] ||= []
              problems[obj.uri] << {
                :json_property => constraint[:json_property],
                :message => constraint[:message]
              }
            end
          end
        end

        if !problems.empty?
          raise TransferConstraintError.new(problems)
        end
      end


      def transfer_all(source_repository, target_repository)
        if self.columns.include?(:repo_id)

          report_incompatible_constraints(source_repository, target_repository)


          # One delete marker per URI
          if self.has_jsonmodel?
            jsonmodel = self.my_jsonmodel
            self.filter(:repo_id => source_repository.id).select(:id).each do |row|
              Tombstone.filter(uri: jsonmodel.uri_for(row[:id], repo_id: target_repository.id)).delete
              Tombstone.create(uri: jsonmodel.uri_for(row[:id], repo_id: source_repository.id))
            end
          end

          self.filter(:repo_id => source_repository.id).
               update(:repo_id => target_repository.id,
                      :system_mtime => Time.now)
        end
      end

    end

  end
end
