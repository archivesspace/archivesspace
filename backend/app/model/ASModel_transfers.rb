module ASModel
  # Code for moving records between repositories
  module RepositoryTransfers

    def self.included(base)
      base.extend(ClassMethods)
    end


    def transfer_to_repository(repository, transfer_group = [])

      if self.values.has_key?(:repo_id)
        old_uri = self.uri

        old_repo = Repository[self.repo_id]

        self.repo_id = repository.id
        self.system_mtime = Time.now
        save(:repo_id, :system_mtime)

        # Mark the (now changed) URI as deleted
        if old_uri
          Tombstone.create(:uri => old_uri)
          DB.after_commit do
            RealtimeIndexing.record_delete(old_uri)
          end

          # Create an event if this is the top-level record being transferred.
          if transfer_group.empty?
            RequestContext.open(:repo_id => repository.id) do
              Event.for_repository_transfer(old_repo, repository, self)
            end
          end
        end
      end

      # Tell any nested records to transfer themselves too
      self.class.nested_records.each do |nested_record_defn|
        association = nested_record_defn[:association][:name]
        Array(self.send(association)).each do |nested_record|
          nested_record.transfer_to_repository(repository)
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
              Tombstone.create(:uri => jsonmodel.uri_for(row[:id], :repo_id => source_repository.id))
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
