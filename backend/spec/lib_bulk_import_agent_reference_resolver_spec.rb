require "spec_helper"
require_relative "../app/lib/bulk_import/agent_reference_resolver"

describe AgentReferenceResolver do
  let(:resolver) { AgentReferenceResolver.new }
  let(:restricted) do
    AgentReferenceResolver.new(allowed_types: %w[agent_person agent_family agent_corporate_entity])
  end

  describe "#parse_agent_reference" do
    context "with a numeric ID" do
      it "returns the canonical URI for a positive integer and a type" do
        expect(resolver.parse_agent_reference("156", "agent_person")).to eq(
          :mode => :numeric, :type => "agent_person", :id => 156, :uri => "/agents/people/156"
        )
      end

      it "trims surrounding whitespace" do
        expect(resolver.parse_agent_reference("  156 ", "agent_family")).to eq(
          :mode => :numeric, :type => "agent_family", :id => 156, :uri => "/agents/families/156"
        )
      end

      it "requires an agent type" do
        expect(resolver.parse_agent_reference("156", nil)).to eq(
          :errors => [{ :code => :required, :attribute => :agent_type, :value => nil }]
        )
      end

      it "reports an unknown agent type as unsupported" do
        expect(resolver.parse_agent_reference("156", "agent_bogus")).to eq(
          :errors => [{ :code => :unsupported, :attribute => :agent_type, :value => "agent_bogus" }]
        )
      end

      it "reports a type outside the allowed list as unsupported" do
        expect(restricted.parse_agent_reference("156", "agent_software")).to eq(
          :errors => [{ :code => :unsupported, :attribute => :agent_type, :value => "agent_software" }]
        )
      end

      ["0", "007", "-3", "abc", "5.0", "1 2", "0x1A", "1_0"].each do |bad|
        it "rejects #{bad.inspect} as an invalid record ID" do
          expect(resolver.parse_agent_reference(bad, "agent_person")).to eq(
            :errors => [{ :code => :invalid, :attribute => :record_id, :value => bad }]
          )
        end
      end
    end

    context "with a canonical URI" do
      it "derives the type from the URI when the type is blank" do
        expect(resolver.parse_agent_reference("/agents/corporate_entities/9", nil)).to eq(
          :mode => :uri, :type => "agent_corporate_entity", :id => 9, :uri => "/agents/corporate_entities/9"
        )
      end

      it "trims surrounding whitespace" do
        expect(resolver.parse_agent_reference(" /agents/people/9 ", nil)).to eq(
          :mode => :uri, :type => "agent_person", :id => 9, :uri => "/agents/people/9"
        )
      end

      it "forbids an agent type" do
        expect(resolver.parse_agent_reference("/agents/people/9", "agent_person")).to eq(
          :errors => [{ :code => :forbidden, :attribute => :agent_type, :value => "agent_person" }]
        )
      end

      it "reports a type outside the allowed list as unsupported" do
        expect(restricted.parse_agent_reference("/agents/software/9", nil)).to eq(
          :errors => [{ :code => :unsupported, :attribute => :record_id, :value => "/agents/software/9" }]
        )
      end

      ["/agents/people/0", "/agents/people/09", "/agents/people/abc", "/agents/nobody/9", "/subjects/9", "/agents/people/9/"].each do |bad|
        it "rejects #{bad.inspect} as an invalid record ID" do
          expect(resolver.parse_agent_reference(bad, nil)).to eq(
            :errors => [{ :code => :invalid, :attribute => :record_id, :value => bad }]
          )
        end
      end
    end

    it "requires a record ID" do
      expect(resolver.parse_agent_reference(nil, "agent_person")).to eq(
        :errors => [{ :code => :required, :attribute => :record_id, :value => nil }]
      )
    end
  end

  describe "#resolve" do
    def record_number(agent)
      JSONModel.parse_reference(agent.uri)[:id]
    end

    it "confirms an existing Agent found by numeric ID" do
      agent = create(:json_agent_person)
      id = record_number(agent)

      expect(resolver.resolve(id.to_s, "agent_person")).to eq(
        :mode => :numeric, :type => "agent_person", :id => id, :uri => agent.uri
      )
    end

    it "confirms an existing Agent found by canonical URI" do
      agent = create(:json_agent_family)

      expect(resolver.resolve(agent.uri, nil)).to eq(
        :mode => :uri, :type => "agent_family", :id => record_number(agent), :uri => agent.uri
      )
    end

    it "reports a missing numeric target with its agent reference" do
      expect(resolver.resolve("987654", "agent_person")).to eq(
        :mode => :numeric, :type => "agent_person", :id => 987654, :uri => "/agents/people/987654",
        :errors => [{ :code => :not_found, :attribute => :record_id, :value => "987654" }]
      )
    end

    it "reports a missing URI target with its agent reference" do
      expect(resolver.resolve("/agents/corporate_entities/987654", nil)).to eq(
        :mode => :uri, :type => "agent_corporate_entity", :id => 987654,
        :uri => "/agents/corporate_entities/987654",
        :errors => [{ :code => :not_found, :attribute => :record_id, :value => "/agents/corporate_entities/987654" }]
      )
    end

    it "returns the agent reference errors without looking up a record" do
      expect(AgentManager).not_to receive(:model_for)

      expect(resolver.resolve("abc", "agent_person")).to eq(
        :errors => [{ :code => :invalid, :attribute => :record_id, :value => "abc" }]
      )
    end
  end
end
