require_relative "handler"
require_relative "../event_builder"
require_relative "../../model/event"
require_relative "../../model/agent_software"

class EventHandler < Handler
  def create(event_builder:, group:, digital_object_uri:, report:)
    return if event_builder.nil?

    begin
      event_data = event_builder.to_h(
        :source_uri => digital_object_uri,
        :system_agent_ref => AgentSoftware.archivesspace_record.uri
      )
      event = JSONModel(:event).from_hash(event_data)
      return if @validate_only

      saved = save(event, Event)
    rescue JSONModel::ValidationException => validation_error
      report.add_errors(I18n.t("bulk_import.error.event_validation",
                               :group => group,
                               :type => event_data["event_type"],
                               :err => validation_error.errors))
      return
    end

    return unless saved

    report.add_info(I18n.t("bulk_import.event_created",
                           :group => group,
                           :type => event_data["event_type"]))
  end
end
