require "spec_helper"
require_relative "../app/lib/event_builder"

describe EventBuilder do
  CONTROLLED_LISTS = [
    "event_event_type",
    "date_label",
    "event_outcome",
    "linked_agent_event_roles",
  ].freeze

  CANONICAL_VALUES = {
    ["event_event_type", "Cataloged"] => "cataloged",
    ["event_event_type", "cataloged"] => "cataloged",
    ["event_event_type", "processed"] => "processed",
    ["date_label", "Creation"] => "creation",
    ["date_label", "creation"] => "creation",
    ["event_outcome", "Pass"] => "pass",
    ["event_outcome", "pass"] => "pass",
    ["linked_agent_event_roles", "Implementer"] => "implementer",
    ["linked_agent_event_roles", "implementer"] => "implementer",
  }.freeze

  def controlled_value_resolver
    calls = []
    resolver = lambda do |list_name, submitted|
      raise ArgumentError, "unexpected controlled-value list #{list_name}" unless CONTROLLED_LISTS.include?(list_name)

      calls << [list_name, submitted]
      CANONICAL_VALUES[[list_name, submitted]]
    end
    resolver.define_singleton_method(:calls) { calls }
    resolver
  end

  def event_attributes(overrides = {})
    {
      :event_type => "cataloged",
      :date => "1999-03-03",
      :date_label => nil,
      :outcome => nil,
      :outcome_note => nil,
      :agent_record_id => nil,
      :agent_type => nil,
      :agent_role => nil,
    }.merge(overrides)
  end

  def builder_for(resolver: nil, **overrides)
    described_class.new(
      :attributes => event_attributes(overrides),
      :controlled_value_resolver => resolver || controlled_value_resolver
    )
  end

  def source_uri(id)
    JSONModel(:digital_object).uri_for(id, :repo_id => 2)
  end

  def system_agent_ref
    "/agents/software/import_event_builder"
  end

  def materialize(builder, source_id = 15)
    builder.to_h(
      :source_uri => source_uri(source_id),
      :system_agent_ref => system_agent_ref
    )
  end

  it "canonicalizes a complete Event into a plain hash" do
    agent_uri = JSONModel(:agent_person).uri_for(15)
    resolver = controlled_value_resolver
    builder = builder_for(
      :resolver => resolver,
      :event_type => "Cataloged",
      :date => "1999-03-03",
      :date_label => "Creation",
      :outcome => "Pass",
      :outcome_note => "Kept",
      :agent_record_id => agent_uri,
      :agent_type => nil,
      :agent_role => "Implementer"
    )
    event = materialize(builder)

    aggregate_failures do
      expect(builder.errors).to eq([])
      expect(builder.explicit_agent_ref).to eq(agent_uri)
      expect(event.class).to eq(Hash)
      expect(event).to eq(
        "event_type" => "cataloged",
        "linked_records" => [
          { "role" => "source", "ref" => source_uri(15) },
        ],
        "linked_agents" => [
          { "role" => "implementer", "ref" => agent_uri },
        ],
        "date" => {
          "jsonmodel_type" => "date",
          "label" => "creation",
          "date_type" => "single",
          "begin" => "1999-03-03",
        },
        "outcome" => "pass",
        "outcome_note" => "Kept",
      )
      expect(resolver.calls).to eq([
        ["event_event_type", "Cataloged"],
        ["date_label", "Creation"],
        ["event_outcome", "Pass"],
        ["linked_agent_event_roles", "Implementer"],
      ])
    end
  end

  it "keeps an over-limit outcome note for later JSONModel validation" do
    outcome_note = "n" * 16_385
    builder = builder_for(:outcome_note => outcome_note)

    expect(builder.errors).to eq([])
    expect(materialize(builder)["outcome_note"]).to eq(outcome_note)
  end

  it "accepts a typed Event without a date" do
    builder = builder_for(:date => nil)
    event = materialize(builder)

    aggregate_failures do
      expect(builder.errors).to eq([])
      expect(event["event_type"]).to eq("cataloged")
      expect(event).not_to have_key("date")
      expect(event).not_to have_key("timestamp")
    end
  end

  it "accumulates independent failures without derivative errors" do
    builder = builder_for(
      :event_type => "nope",
      :date => "1999-02-31",
      :date_label => "nope-label",
      :outcome => "nope-outcome",
      :outcome_note => "n" * 16_385,
      :agent_record_id => "abc",
      :agent_type => "not-an-agent",
      :agent_role => nil
    )

    expect(builder.errors).to eq([
      { :code => :invalid, :attribute => :event_type, :value => "nope" },
      { :code => :invalid, :attribute => :date, :value => "1999-02-31" },
      { :code => :invalid, :attribute => :date_label, :value => "nope-label" },
      { :code => :invalid, :attribute => :outcome, :value => "nope-outcome" },
      { :code => :required, :attribute => :agent_role, :value => nil },
      { :code => :invalid, :attribute => :agent_record_id, :value => "abc" },
      { :code => :unsupported, :attribute => :agent_type, :value => "not-an-agent" },
    ])
    expect(builder.explicit_agent_ref).to be_nil
  end

  it "suppresses derivative errors whose prerequisite failed" do
    missing_type = builder_for(:event_type => nil)
    label_without_date = builder_for(
      :date => nil,
      :date_label => "creation"
    )
    invalid_date = builder_for(:date => "1999/03/03", :date_label => nil)
    uri_with_type = builder_for(
      :agent_record_id => JSONModel(:agent_person).uri_for(4),
      :agent_type => "agent_person",
      :agent_role => "implementer"
    )
    numeric_without_type = builder_for(
      :agent_record_id => "4",
      :agent_type => nil,
      :agent_role => "implementer"
    )
    resource_uri = JSONModel(:resource).uri_for(4, :repo_id => 2)
    non_agent_uri = builder_for(
      :agent_record_id => resource_uri,
      :agent_role => "implementer"
    )

    aggregate_failures do
      expect(missing_type.errors).to eq([
        { :code => :required, :attribute => :event_type, :value => nil },
      ])
      expect(label_without_date.errors).to eq([
        { :code => :requires_date, :attribute => :date_label, :value => "creation" },
      ])
      expect(invalid_date.errors).to eq([
        { :code => :invalid, :attribute => :date, :value => "1999/03/03" },
      ])
      expect(uri_with_type.errors).to eq([
        { :code => :forbidden, :attribute => :agent_type, :value => "agent_person" },
      ])
      expect(uri_with_type.explicit_agent_ref).to be_nil
      expect(numeric_without_type.errors).to eq([
        { :code => :required, :attribute => :agent_type, :value => nil },
      ])
      expect(numeric_without_type.explicit_agent_ref).to be_nil
      expect(non_agent_uri.errors).to eq([
        { :code => :invalid, :attribute => :agent_record_id, :value => resource_uri },
      ])
      expect(non_agent_uri.explicit_agent_ref).to be_nil
    end
  end

  it "builds a positive numeric Agent link from registered Agent type knowledge" do
    agent_type = "agent_software"
    expect(AgentManager.known_agent_type?(agent_type)).to eq(true)
    agent_uri = JSONModel(agent_type).uri_for(27)
    builder = builder_for(
      :date => "1999-03",
      :agent_record_id => "27",
      :agent_type => agent_type,
      :agent_role => "implementer"
    )
    event = materialize(builder)

    aggregate_failures do
      expect(builder.errors).to eq([])
      expect(builder.explicit_agent_ref).to eq(agent_uri)
      expect(event["linked_agents"]).to eq([
        { "role" => "implementer", "ref" => agent_uri },
      ])
      expect(event["date"]).to include("begin" => "1999-03", "label" => "other", "date_type" => "single")
    end
  end

  it "accepts an exact canonical Agent URI when Agent Type is blank" do
    agent_uri = JSONModel(:agent_family).uri_for(8)
    builder = builder_for(
      :agent_record_id => agent_uri,
      :agent_type => nil,
      :agent_role => "implementer"
    )
    inexact = builder_for(
      :agent_record_id => "#{agent_uri}/",
      :agent_role => "implementer"
    )

    aggregate_failures do
      expect(builder.errors).to eq([])
      expect(builder.explicit_agent_ref).to eq(agent_uri)
      expect(materialize(builder)["linked_agents"]).to eq([
        { "role" => "implementer", "ref" => agent_uri },
      ])
      expect(inexact.errors).to eq([
        { :code => :invalid, :attribute => :agent_record_id, :value => "#{agent_uri}/" },
      ])
      expect(inexact.explicit_agent_ref).to be_nil
    end
  end

  it "uses the supplied system Agent as executing_program when the Agent triplet is blank" do
    resolver = controlled_value_resolver
    builder = builder_for(
      :resolver => resolver,
      :date => "1999",
      :date_label => nil,
      :outcome_note => "Kept without an outcome",
      :agent_record_id => nil,
      :agent_type => nil,
      :agent_role => nil
    )
    event = materialize(builder)

    aggregate_failures do
      expect(builder.errors).to eq([])
      expect(builder.explicit_agent_ref).to be_nil
      expect(event["date"]).to eq(
        "jsonmodel_type" => "date",
        "label" => "other",
        "date_type" => "single",
        "begin" => "1999"
      )
      expect(event).not_to have_key("outcome")
      expect(event["outcome_note"]).to eq("Kept without an outcome")
      expect(event["linked_agents"]).to eq([
        { "role" => "executing_program", "ref" => system_agent_ref },
      ])
      expect(event["linked_records"]).to eq([
        { "role" => "source", "ref" => source_uri(15) },
      ])
      expect(resolver.calls.map(&:first)).to eq(["event_event_type"])
    end
  end

  it "materializes the same linked-record shape for a persisted or temporary source URI" do
    builder = builder_for(:outcome => "pass", :outcome_note => "Kept")
    persisted_uri = source_uri(15)
    temporary_uri = source_uri("import_00000000-0000-4000-8000-000000000001")
    persisted = builder.to_h(:source_uri => persisted_uri, :system_agent_ref => system_agent_ref)
    temporary = builder.to_h(:source_uri => temporary_uri, :system_agent_ref => system_agent_ref)

    aggregate_failures do
      expect(builder.explicit_agent_ref).to be_nil
      expect(persisted["linked_records"]).to eq([{ "role" => "source", "ref" => persisted_uri }])
      expect(temporary["linked_records"]).to eq([{ "role" => "source", "ref" => temporary_uri }])
      expect(temporary.reject { |key, _value| key == "linked_records" }).to eq(
        persisted.reject { |key, _value| key == "linked_records" }
      )
      expect(persisted["linked_agents"]).to eq([
        { "role" => "executing_program", "ref" => system_agent_ref },
      ])
    end
  end

  it "returns frozen errors with no translated or Pipeline A context" do
    submitted_type = +"nope"
    builder = builder_for(:event_type => submitted_type)
    submitted_type << "mutated"
    error = builder.errors.first
    rendered = builder.errors.map { |item| [item[:code], item[:attribute], item[:value]].inspect }.join("\n")

    aggregate_failures do
      expect(builder.errors).to be_frozen
      expect(error).to be_frozen
      expect(error.keys).to contain_exactly(:code, :attribute, :value)
      expect(error[:value]).to eq("nope")
      expect(error[:value]).to be_frozen
      expect { builder.errors << { :code => :invalid } }.to raise_error(FrozenError)
      expect(rendered).not_to include("event_1_")
      expect(rendered).not_to include("Event group")
      expect(rendered).not_to include("bulk_import")
      expect(rendered).not_to include("translation missing")
    end
  end

  it "treats invalid or unbound materialization as programmer misuse" do
    invalid = builder_for(:event_type => "nope")
    valid = builder_for
    source = source_uri(15)

    aggregate_failures do
      expect {
        invalid.to_h(:source_uri => source, :system_agent_ref => system_agent_ref)
      }.to raise_error(ArgumentError, /error-free/)
      expect(invalid.errors.map { |error| error[:code] }).to eq([:invalid])
      expect {
        valid.to_h(:source_uri => nil, :system_agent_ref => system_agent_ref)
      }.to raise_error(ArgumentError, /source_uri/)
      expect {
        valid.to_h(:source_uri => "  ", :system_agent_ref => system_agent_ref)
      }.to raise_error(ArgumentError, /source_uri/)
      expect {
        valid.to_h(:source_uri => source, :system_agent_ref => nil)
      }.to raise_error(ArgumentError, /system_agent_ref/)
      expect(valid.errors).to eq([])
    end
  end

  it "does not require a report or persistence collaborator" do
    builder = builder_for
    event = materialize(builder)

    aggregate_failures do
      expect(builder.public_methods(false)).to contain_exactly(:errors, :explicit_agent_ref, :to_h)
      expect(event.class).to eq(Hash)
      expect(event["linked_agents"].first["ref"]).to eq(system_agent_ref)
    end
  end
end
