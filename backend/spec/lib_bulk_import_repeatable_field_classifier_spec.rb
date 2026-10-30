require "spec_helper"
require_relative "../app/lib/bulk_import/repeatable_field_classifier"

describe RepeatableFieldClassifier do
  def classifier_for(headers)
    described_class.new(
      :vocabulary => %w[
        agent_1_agent_type
        agent_1_record_id
        agent_1_agent_name_1_primary_name
        agent_1_agent_name_1_subordinate_name_1
        agent_1_note_1_content
        date_1_begin
      ],
      :families => [{ :namespace => "agent" }, { :namespace => "date" }],
      :headers => headers
    )
  end

  def column_for(classifier, namespace, index, original)
    classifier.groups(namespace).to_h.fetch(index).find { |column| column.original == original }
  end

  describe "inner records" do
    it "splits an inner record's key, index, and path from the relative path" do
      classifier = classifier_for(%w[agent_2_agent_name_1_primary_name])
      column = column_for(classifier, "agent", 2, "agent_2_agent_name_1_primary_name")

      expect(column).to be_nested
      expect(column.relative_path).to eq("agent_name_1_primary_name")
      expect([column.inner_key, column.inner_index, column.inner_path]).to eq(["name", 1, "primary_name"])
    end

    it "keeps a native numeric leaf inside the inner path" do
      classifier = classifier_for(%w[agent_1_agent_name_1_subordinate_name_1])
      column = column_for(classifier, "agent", 1, "agent_1_agent_name_1_subordinate_name_1")

      expect(column.inner_path).to eq("subordinate_name_1")
    end

    it "returns the inner record key and leaf as symbols for a one-level column" do
      classifier = classifier_for(%w[agent_1_agent_name_1_subordinate_name_1])
      column = column_for(classifier, "agent", 1, "agent_1_agent_name_1_subordinate_name_1")

      expect(column.nested_path).to eq([:name, :subordinate_name_1])
    end

    it "returns the nested record between the inner key and the leaf for a two-level column" do
      classifier = described_class.new(
        :vocabulary => %w[agent_1_contact_1_telephone_1_number],
        :families => [{ :namespace => "agent" }],
        :headers => %w[agent_1_contact_1_telephone_1_number]
      )
      column = column_for(classifier, "agent", 1, "agent_1_contact_1_telephone_1_number")

      expect(column.nested_path).to eq([:contact, :telephone, :number])
    end

    it "keeps the inner namespace whole when it does not start with the outer one" do
      classifier = classifier_for(%w[agent_1_note_1_content])

      expect(column_for(classifier, "agent", 1, "agent_1_note_1_content").inner_key).to eq("note")
    end

    it "does not treat a group-level field as an inner record" do
      classifier = classifier_for(%w[agent_1_agent_type date_1_begin])

      expect(column_for(classifier, "agent", 1, "agent_1_agent_type")).not_to be_nested
      expect(column_for(classifier, "date", 1, "date_1_begin")).not_to be_nested
    end
  end

  describe "structural indices" do
    it "classifies the canonical _1 header as itself at index 1" do
      classification = classifier_for(%w[agent_1_agent_type]).classify("agent_1_agent_type")

      expect([classification.representative, classification.namespace, classification.index]).to eq(["agent_1_agent_type", "agent", 1])
    end

    it "normalizes a higher index to its canonical _1 representative" do
      classification = classifier_for(%w[agent_42_agent_type]).classify("agent_42_agent_type")

      expect([classification.representative, classification.index]).to eq(["agent_1_agent_type", 42])
    end

    it "normalizes only the structural index of an inner record column" do
      classification = classifier_for(%w[agent_7_agent_name_1_subordinate_name_1]).classify("agent_7_agent_name_1_subordinate_name_1")

      expect(classification.representative).to eq("agent_1_agent_name_1_subordinate_name_1")
    end

    it "returns noncontiguous groups in numeric order, not header or text order" do
      classifier = classifier_for(%w[agent_10_agent_type agent_2_record_id agent_1_agent_type agent_30_record_id])

      expect(classifier.groups("agent").map(&:first)).to eq([1, 2, 10, 30])
    end

    it "keeps each index's columns in its own group" do
      classifier = classifier_for(%w[agent_3_agent_type agent_3_record_id agent_9_agent_type])

      expect(classifier.groups("agent").to_h.transform_values { |columns| columns.map(&:relative_path) }).to eq(
        3 => %w[agent_type record_id], 9 => %w[agent_type]
      )
    end

    it "reports no unknown header for any positive index" do
      expect(classifier_for(%w[agent_1_agent_type agent_2_agent_type agent_99_agent_type]).unknown_headers).to eq([])
    end
  end

  describe "headers outside the vocabulary" do
    it "treats a zero index as unknown" do
      expect(classifier_for(%w[agent_0_agent_type]).unknown_headers).to eq(["agent_0_agent_type"])
    end

    it "treats a zero-padded index as unknown" do
      expect(classifier_for(%w[agent_01_agent_type]).unknown_headers).to eq(["agent_01_agent_type"])
    end

    it "treats a leaf missing from the vocabulary as unknown at any index" do
      expect(classifier_for(%w[agent_1_bogus agent_3_bogus]).unknown_headers).to eq(%w[agent_1_bogus agent_3_bogus])
    end

    it "treats a header without an index as unknown" do
      expect(classifier_for(%w[agent_agent_type]).unknown_headers).to eq(["agent_agent_type"])
    end

    it "treats a non-numeric or negative index as unknown" do
      expect(classifier_for(%w[agent_x_agent_type agent_-1_agent_type]).unknown_headers).to eq(%w[agent_x_agent_type agent_-1_agent_type])
    end

    it "does not add an unknown header to any group" do
      expect(classifier_for(%w[agent_0_agent_type agent_2_bogus agent_2_agent_type]).groups("agent").map(&:first)).to eq([2])
    end
  end

  describe "#field_code" do
    it "returns the canonical code at the requested index for a group-level field" do
      expect(classifier_for([]).field_code("agent", 3, "agent_type")).to eq("agent_3_agent_type")
    end

    it "returns the canonical code at the requested index for an inner record field" do
      code = classifier_for([]).field_code("agent", 3, "primary_name", :inner_key => "name")

      expect(code).to eq("agent_3_agent_name_1_primary_name")
    end

    it "returns nil for a field the vocabulary does not contain" do
      expect(classifier_for([]).field_code("agent", 1, "missing")).to be_nil
    end
  end
end
