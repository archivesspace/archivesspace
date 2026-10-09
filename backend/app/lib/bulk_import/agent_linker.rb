require_relative "agent_builder"
require_relative "agent_reference_resolver"
require_relative "repeatable_field_classifier"

class AgentLinker
  def initialize(report:, field_classifier:, agent_handler:, created_refs:, validate_only:, controlled_value_resolver:)
    @report = report
    @field_classifier = field_classifier
    @agent_handler = agent_handler
    @created_refs = created_refs
    @validate_only = validate_only
    @controlled_value_resolver = controlled_value_resolver
  end

  def link_agents(row_hash)
    agent_links = []

    @field_classifier.groups("agent").each do |num, columns|
      values = columns.each_with_object({}) do |column, by_path|
        by_path[column.relative_path] = row_hash[column.original]
      end
      next if values.values.all?(&:nil?)

      agent_type = values["agent_type"]
      record_id = values["record_id"]
      header = values["header"]
      role = values["role"]
      relator = values["relator"]

      creating = columns.any? { |column| (column.nested? || column.relative_path == "publish") && !row_hash[column.original].nil? }
      agent_reference = agent_reference_resolver.parse_agent_reference(record_id, agent_type) unless record_id.nil?
      conflicts = agent_mode_conflicts(num, creating, header, record_id, agent_reference)
      relationship_errors = []
      link = @agent_handler.validate_link(relator, role || "creator", relationship_errors)
      errors = conflicts + relationship_errors
      @report.add_errors(errors) unless errors.empty?
      next unless conflicts.empty?

      if creating
        link = create_and_link_agent(num, columns, row_hash, agent_type: agent_type, link: link)
        agent_links.push link if link && !@validate_only
        next
      end

      if record_id.nil? && header.nil?
        @report.add_errors(I18n.t("bulk_import.error.agent_missing_identity", :num => num))
        next
      end

      unless record_id.nil?
        resolution = agent_reference_resolver.resolve(record_id, agent_type) if link && !agent_reference[:errors]
        unless resolution && unmatched_numeric_id?(resolution)
          existing = link_existing_agent(num, agent_reference: agent_reference, resolution: resolution, link: link)
          agent_links.push existing if existing && !@validate_only
          next
        end
      end

      legacy = find_or_create_legacy_agent(num, agent_type: agent_type, record_id: record_id, header: header, relator: relator, role: role, link: link)
      agent_links.push legacy if legacy && !@validate_only
    end

    agent_links
  end

  private

  def find_or_create_legacy_agent(num, agent_type:, record_id:, header:, relator:, role:, link:)
    if agent_type.nil?
      @report.add_errors(I18n.t("bulk_import.error.agent_missing_type", :num => num))
      return nil
    end

    type = handler_agent_type(agent_type)
    if type.nil?
      @report.add_errors(I18n.t("bulk_import.error.agent_unsupported_type", :num => num, :agent_type => agent_type))
      return nil
    end

    return nil unless link

    @agent_handler.get_or_create(
      type,
      record_id,
      header,
      relator,
      role, @report,
      created_refs: @created_refs
    )
  rescue BulkImportException => e
    @report.add_errors(I18n.t("bulk_import.error.process_error", :type => I18n.t("bulk_import.agent"), :num => num, :why => e.message))
    nil
  end

  def agent_mode_conflicts(num, creating, header, record_id, agent_reference)
    if creating
      { "record_id" => record_id, "header" => header }.reject { |_path, value| value.nil? }.keys.map do |path|
        I18n.t("bulk_import.error.agent_mode_conflict", :num => num, :field => @field_classifier.field_code("agent", num, path))
      end
    elsif agent_reference && agent_reference[:mode] == :uri && !header.nil?
      [I18n.t(
        "bulk_import.error.agent_uri_header_conflict",
        :num => num,
        :record_field => @field_classifier.field_code("agent", num, "record_id"),
        :header_field => @field_classifier.field_code("agent", num, "header")
      )]
    else
      []
    end
  end

  # Legacy behavior decided by archivists: a numeric ID that matches no stored agent and
  # falls through to the Header String path, which creates an unpublished placeholder.
  def unmatched_numeric_id?(resolution)
    resolution[:mode] == :numeric && resolution[:errors]
  end

  def link_existing_agent(num, agent_reference:, resolution:, link:)
    if agent_reference[:errors]
      agent_reference[:errors].each { |error| report_agent_reference_error(error, num) }
      return nil
    end
    return nil unless link

    if resolution[:errors]
      resolution[:errors].each { |error| report_agent_reference_error(error, num) }
      return nil
    end

    link["ref"] = resolution[:uri]
    link
  end

  def agent_reference_resolver
    @agent_reference_resolver ||= AgentReferenceResolver.new(allowed_types: AgentBuilder::SUPPORTED_AGENT_TYPES)
  end

  def report_agent_reference_error(error, num)
    key = if error[:code] == :unsupported
            error[:attribute] == :agent_type ? "agent_unsupported_type" : "agent_unsupported_uri"
          else
            {
              :invalid => "agent_invalid_record_id",
              :forbidden => "agent_type_with_uri",
              :required => "agent_missing_type",
              :not_found => "agent_not_found",
            }.fetch(error[:code])
          end

    @report.add_errors(I18n.t(
      "bulk_import.error.#{key}",
      :num => num,
      :field => @field_classifier.field_code("agent", num, error[:attribute].to_s),
      :value => error[:value],
      :agent_type => error[:value]
    ))
  end

  def create_and_link_agent(num, columns, row_hash, agent_type:, link:)
    builder = AgentBuilder.new(
      :attributes => agent_builder_attributes(columns, row_hash, agent_type),
      :controlled_value_resolver => @controlled_value_resolver
    )
    unless builder.errors.empty?
      builder.errors.each { |error| report_agent_builder_error(error, num, agent_type) }
      return nil
    end
    return nil unless link

    link = @agent_handler.create_linked(builder.to_h, link, @report, num)
    @created_refs << link["ref"] if link && !@validate_only
    link
  end

  def agent_builder_attributes(columns, row_hash, agent_type)
    attributes = { :agent_type => agent_type }
    columns.each do |column|
      value = row_hash[column.original]
      if column.nested?
        *parents, leaf = column.nested_path
        parents.inject(attributes) { |record, key| record[key] ||= {} }[leaf] = value
      elsif column.relative_path == "publish"
        attributes[:publish] = value
      end
    end
    attributes
  end

  def report_agent_builder_error(error, num, agent_type)
    attribute = error[:attribute]
    property = error[:nested] ? "#{error[:nested]}_1_#{attribute}" : attribute.to_s
    field = @field_classifier.field_code("agent", num, property, :inner_key => error[:record]&.to_s)

    case error[:code]
    when :required
      @report.add_errors(I18n.t("bulk_import.error.agent_required_field", :num => num, :field => field))
    when :unsupported
      @report.add_errors(I18n.t("bulk_import.error.agent_unsupported_type", :num => num, :agent_type => error[:value]))
    when :invalid
      key = attribute == :publish ? "agent_unrecognized_boolean" : "agent_invalid_value"
      @report.add_errors(I18n.t("bulk_import.error.#{key}", :num => num, :field => field, :value => error[:value]))
    when :incompatible
      @report.add_errors(I18n.t("bulk_import.error.agent_incompatible_field", :num => num, :field => field, :agent_type => agent_type))
    else
      raise KeyError, "Unhandled AgentBuilder error code: #{error[:code]}"
    end
  end

  # TODO: Replace with AgentManager.model_for once AgentHandler#get_or_create
  # accepts agent_* type names. The archival object importer still passes
  # "people"/"families"/"corporate_entities", so will fix when we address AO bulk import.
  def handler_agent_type(agent_type)
    case agent_type
    when "agent_person"
      "people"
    when "agent_family"
      "families"
    when "agent_corporate_entity"
      "corporate_entities"
    end
  end
end
