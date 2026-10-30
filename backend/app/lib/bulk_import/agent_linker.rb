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

      link = link_agent_group(num, columns, values, row_hash)
      @failed = true unless link
      agent_links.push link if link && !@validate_only
    end

    agent_links
  end

  def failed?
    !!@failed
  end

  private

  def link_agent_group(num, columns, values, row_hash)
    agent_type = values["agent_type"]
    record_id = values["record_id"]
    header = values["header"]
    role = values["role"]
    relator = values["relator"]

    creation_columns = columns.select { |column| (column.nested? || column.relative_path == "publish") && !row_hash[column.original].nil? }
    creating = !creation_columns.empty?
    agent_reference = agent_reference_resolver.parse_agent_reference(record_id, agent_type) unless record_id.nil?
    conflicts = agent_mode_conflicts(num, creation_columns.map(&:original), header, record_id, agent_reference)
    relationship_errors = []
    link = @agent_handler.validate_link(relator, role || "creator", relationship_errors)
    errors = conflicts + relationship_errors
    @report.add_errors(errors) unless errors.empty?
    return nil unless conflicts.empty?

    return create_and_link_agent(num, columns, row_hash, agent_type: agent_type, link: link) if creating

    if record_id.nil? && header.nil?
      @report.add_errors(I18n.t("bulk_import.error.agent_missing_identity", :num => num))
      return nil
    end

    unless record_id.nil?
      resolution = agent_reference_resolver.resolve(record_id, agent_type) if link && !agent_reference[:errors]
      unless resolution && unmatched_numeric_id?(resolution)
        return link_existing_agent(num, agent_reference: agent_reference, resolution: resolution, link: link)
      end
    end

    find_or_create_legacy_agent(num, agent_type: agent_type, record_id: record_id, header: header, relator: relator, role: role, link: link)
  end

  def find_or_create_legacy_agent(num, agent_type:, record_id:, header:, relator:, role:, link:)
    if agent_type.nil?
      @report.add_errors(I18n.t("bulk_import.error.agent_missing_type", :num => num))
      return nil
    end

    type = AgentHandler.import_agent_type(agent_type)
    if type.nil?
      @report.add_errors(I18n.t("bulk_import.error.agent_unsupported_type", :num => num, :accepted => accepted_agent_types))
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

  def agent_mode_conflicts(num, creation_fields, header, record_id, agent_reference)
    if !creation_fields.empty?
      { "record_id" => record_id, "header" => header }.reject { |_path, value| value.nil? }.keys.map do |path|
        I18n.t(
          "bulk_import.error.agent_mode_conflict",
          :num => num,
          :field => @field_classifier.field_code("agent", num, path),
          :creation_fields => creation_fields.join(", ")
        )
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
    @agent_reference_resolver ||= AgentReferenceResolver.new(allowed_types: AgentHandler.import_agent_types, agent_handler: @agent_handler)
  end

  def accepted_agent_types
    AgentHandler.import_agent_types.join(", ")
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
      :accepted => accepted_agent_types
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

    field_for = lambda do |path|
      source = builder.source_of(path)
      source && agent_builder_field(num, source)
    end
    @agent_handler.create_linked(builder.to_h, link, @report, num, created_refs: @created_refs, field_for: field_for, supplied: builder.supplied_values)
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
    field = agent_builder_field(num, error)

    case error[:code]
    when :required
      @report.add_errors(I18n.t("bulk_import.error.agent_required_field", :num => num, :field => field))
    when :unsupported
      @report.add_errors(I18n.t("bulk_import.error.agent_unsupported_type", :num => num, :accepted => accepted_agent_types))
    when :invalid
      key = attribute == :publish ? "agent_unrecognized_boolean" : "agent_invalid_value"
      @report.add_errors(I18n.t("bulk_import.error.#{key}", :num => num, :field => field, :value => error[:value]))
    when :incompatible
      @report.add_errors(I18n.t("bulk_import.error.agent_incompatible_field", :num => num, :field => field, :agent_type => agent_type))
    else
      raise KeyError, "Unhandled AgentBuilder error code: #{error[:code]}"
    end
  end

  def agent_builder_field(num, source)
    attribute = source[:attribute]
    property = source[:nested] ? "#{source[:nested]}_1_#{attribute}" : attribute.to_s
    @field_classifier.field_code("agent", num, property, :inner_key => source[:record]&.to_s)
  end
end
