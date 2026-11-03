require "date"
require_relative "bulk_import/agent_reference_resolver"

class EventBuilder
  attr_reader :errors, :explicit_agent_ref

  def self.agent_types
    AgentHandler.import_agent_types + ["software"]
  end

  def initialize(attributes:, controlled_value_resolver:)
    @errors = []
    @explicit_agent_ref = nil
    canonicalize(attributes, controlled_value_resolver)
    @errors.freeze
  end

  def to_h(source_uri:, system_agent_ref:)
    raise ArgumentError, "EventBuilder#to_h requires an error-free builder" unless @errors.empty?
    raise ArgumentError, "EventBuilder#to_h requires source_uri" unless present_binding?(source_uri)
    raise ArgumentError, "EventBuilder#to_h requires system_agent_ref" unless present_binding?(system_agent_ref)

    event = {
      "event_type" => @event_type,
      "linked_records" => [
        { "role" => "source", "ref" => source_uri },
      ],
      "linked_agents" => [linked_agent(system_agent_ref)],
    }

    if @date
      event["date"] = {
        "jsonmodel_type" => "date",
        "label" => @date_label,
        "date_type" => "single",
        "begin" => @date,
      }
    end

    event["outcome"] = @outcome if @outcome
    event["outcome_note"] = @outcome_note if @outcome_note
    event
  end

  private

  def canonicalize(attributes, resolver)
    canonicalize_event_type(attributes[:event_type], resolver)
    canonicalize_date(attributes[:date], attributes[:date_label], resolver)
    canonicalize_outcome(attributes[:outcome], attributes[:outcome_note], resolver)
    canonicalize_agent(
      attributes[:agent_record_id],
      attributes[:agent_type],
      attributes[:agent_role],
      resolver
    )
  end

  def canonicalize_event_type(event_type, resolver)
    if blank?(event_type)
      add_error(:required, :event_type)
      return
    end

    canonical_type = resolver.call("event_event_type", event_type)
    if canonical_type.nil?
      add_error(:invalid, :event_type, event_type)
    else
      @event_type = freeze_copy(canonical_type)
    end
  end

  def canonicalize_date(date, date_label, resolver)
    date_present = !blank?(date)
    label_present = !blank?(date_label)

    if date_present
      if valid_date?(date)
        @date = freeze_copy(date)
      else
        add_error(:invalid, :date, date)
      end
    elsif label_present
      add_error(:requires_date, :date_label, date_label)
    else
      add_error(:required, :date)
    end

    if label_present
      canonical_label = resolver.call("date_label", date_label)
      if canonical_label.nil?
        add_error(:invalid, :date_label, date_label)
      elsif @date
        @date_label = freeze_copy(canonical_label)
      end
    elsif @date
      @date_label = freeze_copy("other")
    end
  end

  def canonicalize_outcome(outcome, outcome_note, resolver)
    unless blank?(outcome)
      canonical_outcome = resolver.call("event_outcome", outcome)
      if canonical_outcome.nil?
        add_error(:invalid, :outcome, outcome)
      else
        @outcome = freeze_copy(canonical_outcome)
      end
    end

    @outcome_note = freeze_copy(outcome_note) unless blank?(outcome_note)
  end

  def canonicalize_agent(record_id, agent_type, role, resolver)
    return if blank?(record_id) && blank_type?(agent_type) && blank?(role)

    canonicalize_agent_role(role, resolver)
    canonicalize_agent_target(record_id, agent_type)
  end

  def canonicalize_agent_role(role, resolver)
    if blank?(role)
      add_error(:required, :agent_role)
      return
    end

    canonical_role = resolver.call("linked_agent_event_roles", role)
    if canonical_role.nil?
      add_error(:invalid, :agent_role, role)
    else
      @agent_role = freeze_copy(canonical_role)
    end
  end

  def canonicalize_agent_target(record_id, agent_type)
    agent_reference = AgentReferenceResolver.new(:allowed_types => self.class.agent_types).parse_agent_reference(record_id, agent_type)
    if agent_reference[:errors]
      agent_reference[:errors].each do |error|
        attribute = error[:attribute] == :record_id ? :agent_record_id : error[:attribute]
        add_error(error[:code], attribute, error[:value])
      end
      add_unsupported_agent_type(agent_type) if agent_reference[:errors].any? { |error| error[:attribute] == :record_id }
    else
      @explicit_agent_ref = freeze_copy(agent_reference[:uri])
    end
  end

  def add_unsupported_agent_type(agent_type)
    return if blank_type?(agent_type) || event_agent_type(agent_type)

    add_error(:unsupported, :agent_type, agent_type)
  end

  def event_agent_type(agent_type)
    AgentHandler.import_agent_type(agent_type, self.class.agent_types)
  end

  def valid_date?(value)
    return false unless value.is_a?(String)

    match = /\A(\d{4})(?:-(\d{2})(?:-(\d{2}))?)?\z/.match(value)
    return false unless match

    year = match[1].to_i
    month = match[2] ? match[2].to_i : 1
    day = match[3] ? match[3].to_i : 1
    Date.valid_date?(year, month, day)
  end

  def add_error(code, attribute, value = nil)
    @errors << {
      :code => code,
      :attribute => attribute,
      :value => freeze_copy(value),
    }.freeze
  end

  def linked_agent(system_agent_ref)
    if @explicit_agent_ref
      { "role" => @agent_role, "ref" => @explicit_agent_ref }
    else
      { "role" => "executing_program", "ref" => system_agent_ref }
    end
  end

  def present_binding?(value)
    value.is_a?(String) && !value.strip.empty?
  end

  def blank?(value)
    value.nil? || value == ""
  end

  def blank_type?(value)
    blank?(value) || (value.is_a?(String) && value.strip.empty?)
  end

  def freeze_copy(value)
    value.is_a?(String) ? -value : value
  end
end
