module Lib
  module Resource
    class Duplicate
      attr_reader :resource_id, :errors, :resource

      def initialize(resource_id)
        @errors = []
        @resource_id = resource_id
      end

      def duplicate
        if resource_source.nil?
          @errors.push({ error: I18n.t('resource_duplicate_job.success_reload_message', resource_id: @resource_id) })
          return false
        end

        begin
          DB.open(DB.supports_mvcc?, :retry_on_optimistic_locking_fail => true, :isolation_level => :committed) do
            duplicate_resource

            raise Sequel::Rollback if !@errors.empty?
          end
        rescue
          last_error = $!
          @errors.push({ error: "last_error #{last_error.inspect}." }) if @errors.empty?

          return false
        end

        return false if @errors.length > 0
        return true
      end

      def resource_source_json_model
        return @resource_source_json_model if instance_variable_defined?(:@resource_source_json_model)

        @resource_source_json_model = ::Resource.to_jsonmodel(resource_source)
      end

      def resource_source
        return @resource_source if instance_variable_defined?(:@resource_source)

        @resource_source = ::Resource.where(id: @resource_id).first
      end

      private

      def duplicate_resource
        resource_source_json_model.id = nil
        resource_source_json_model.id_0 = "[Duplicated] #{resource_source_json_model.id_0}"
        resource_source_json_model.title = "[Duplicated] #{resource_source_json_model.title}"
        resource_source_json_model.ead_id = "[Duplicated] #{resource_source_json_model.ead_id}" if resource_source_json_model.ead_id.present?

        resource_source_json_model.linked_agents.each do |linked_agent|
          linked_agent['id'] = nil
          linked_agent['resource_id'] = nil
        end

        resource_source_json_model.subjects.each do |subject|
          subject['id'] = nil
          subject['resource_id'] = nil
        end

        resource_source_json_model.related_accessions.each do |accession|
          accession['id'] = nil
          accession['resource_id'] = nil
        end

        resource_source_json_model.classifications.each do |classification|
          classification['id'] = nil
          classification['resource_id'] = nil
        end

        # Set publish to false to create a new unpublished resource
        resource_source_json_model.publish = false

        begin
          @resource = ::Resource.create_from_json(resource_source_json_model)
        rescue Sequel::ValidationFailed => e
          @errors.push({ error: I18n.t('resource_duplicate_job.resource_failure_message', resource_id: @resource_id, message: e.message) })

          return false
        end

        archival_objects = resource_source.children.to_a

        return true if archival_objects.count == 0

        duplicate_archival_objects(archival_objects, nil)
      end

      # Recursively parse and create archival objects from top to bottom.
      def duplicate_archival_objects(archival_objects, parent_uri)
        archival_objects.each do |archival_object|
          archival_object_source_json_model = ::ArchivalObject.to_jsonmodel(archival_object.id)

          archival_object_source_json_model.id = nil
          archival_object_source_json_model.ref_id = nil
          archival_object_source_json_model.display_string = nil
          archival_object_source_json_model.resource = { :ref => @resource.uri }
          archival_object_source_json_model.parent = { :ref => parent_uri } unless parent_uri.nil?

          archival_object_source_json_model.linked_agents.each do |linked_agent|
            linked_agent['id'] = nil
            linked_agent['archival_object_id'] = nil
          end

          archival_object_source_json_model.accession_links.each do |accession|
            accession['id'] = nil
            accession['archival_object_id'] = nil
          end

          archival_object_source_json_model.subjects.each do |subject|
            subject['id'] = nil
            subject['archival_object_id'] = nil
          end

          begin
            archival_object_duplicated = ::ArchivalObject.create_from_json(archival_object_source_json_model)
          rescue Sequel::ValidationFailed => e
            message = @errors.push({
              error: I18n.t(
                'resource_duplicate_job.archival_object_failure_message',
                archival_object_id: archival_object.id,
                resource_id: @resource_id,
                message: e.message
              )
            })

            @errors.push({ error: message})
            @errors.push({ error: I18n.t('resource_duplicate_job.archival_object_failure_message', source_archival_object_inspect: archival_object.inspect) })

            return false
          end

          if archival_object.children.count > 0
            current_archival_object_children = archival_object.children.all.to_a

            duplicate_archival_objects(current_archival_object_children, archival_object_duplicated.uri)
          end
        end
      end
    end
  end
end
