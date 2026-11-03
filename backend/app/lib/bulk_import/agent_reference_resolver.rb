class AgentReferenceResolver
  def initialize(allowed_types:, agent_handler: nil)
    @allowed_types = allowed_types
    @agent_handler = agent_handler
  end

  def parse_agent_reference(record_id, agent_type)
    submitted = record_id.to_s.strip
    return error(:required, :record_id, nil) if submitted.empty?

    if submitted.start_with?("/")
      parse_uri(submitted, record_id, agent_type)
    else
      parse_numeric_reference(submitted, record_id, agent_type)
    end
  end

  def resolve(record_id, agent_type)
    agent_reference = parse_agent_reference(record_id, agent_type)
    return agent_reference if agent_reference[:errors]
    return agent_reference if @agent_handler.get_model(agent_reference[:type])[agent_reference[:id]]

    agent_reference.merge(:errors => [{ :code => :not_found, :attribute => :record_id, :value => record_id }])
  end

  private

  def parse_uri(submitted, record_id, agent_type)
    reference = canonical_reference(submitted)
    return error(:invalid, :record_id, record_id) unless reference
    return error(:forbidden, :agent_type, agent_type) unless blank?(agent_type)
    return error(:unsupported, :record_id, record_id) unless allowed_type(reference[:type])

    result(:uri, reference[:type], reference[:id])
  end

  def parse_numeric_reference(submitted, record_id, agent_type)
    return error(:invalid, :record_id, record_id) unless submitted.match?(/\A[1-9]\d*\z/)
    return error(:required, :agent_type, nil) if blank?(agent_type)

    type = allowed_type(agent_type)
    return error(:unsupported, :agent_type, agent_type) unless type

    result(:numeric, type, submitted.to_i)
  end

  def canonical_reference(uri)
    reference = JSONModel.parse_reference(uri)
    return nil unless reference

    type = reference[:type].to_s
    return nil unless type.start_with?("agent_")

    id = reference[:id]
    return nil unless id.is_a?(Integer) && id > 0
    return nil unless uri == JSONModel(type).uri_for(id)

    { :type => type.delete_prefix("agent_"), :id => id }
  end

  def allowed_type(type)
    AgentHandler.import_agent_type(type, @allowed_types)
  end

  def result(mode, type, id)
    { :mode => mode, :type => type, :id => id, :uri => JSONModel("agent_#{type}").uri_for(id) }
  end

  def error(code, attribute, value)
    { :errors => [{ :code => code, :attribute => attribute, :value => value }] }
  end

  def blank?(value)
    value.nil? || value.to_s.strip.empty?
  end
end
