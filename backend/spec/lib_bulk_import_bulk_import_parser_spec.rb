require "spec_helper"
require_relative "../app/lib/bulk_import/bulk_import_parser"

# Minimal synthetic parser: it supplies its own valid-code list and structural
# rules so the seam is exercised without a real template or importer subclass.
class StructuralRuleSeamParser < BulkImportParser
  START_MARKER = /\Amarker\z/.freeze

  def initialize(headers, valid_codes, rules)
    @headers = headers
    @valid_codes = valid_codes
    @rules = rules
  end

  def valid_column_codes
    @valid_codes
  end

  def structural_column_rules
    @rules
  end
end

describe "BulkImportParser exact structural-rule matcher seam" do
  # "widget" stands in for a repeatable relationship with a medial structural
  # index whose representative maintained form is always _1.
  let(:widget_rule) do
    { :pattern => /\Awidget_(?<index>[1-9]\d*)_.+\z/, :representative => "1" }
  end

  # "gizmo" stands in for a legacy family: an unindexed first group and higher
  # groups carrying a trailing index that begins at 2. Representative form _2.
  let(:gizmo_rule) do
    { :pattern => /\Agizmo_[a-z_]+_(?<index>[2-9]|[1-9]\d+)\z/, :representative => "2" }
  end

  let(:codes) do
    ["marker", "widget_1_color", "widget_1_size", "gizmo_label", "gizmo_label_2", "gadget_count_1"]
  end

  def check(headers, rules: nil, valid_codes: nil)
    rules ||= [widget_rule, gizmo_rule]
    valid_codes ||= codes
    StructuralRuleSeamParser.new(["marker"] + headers, valid_codes, rules).send(:check_unknown_columns)
  end

  it "accepts a positive structural index by normalizing it to a maintained header" do
    expect { check(["widget_1_color", "widget_7_size", "widget_42_color"]) }.not_to raise_error
  end

  it "applies the same rule mechanism to a medial index (-> 1) and a legacy trailing index (-> 2)" do
    expect { check(["widget_5_color", "gizmo_label_8"]) }.not_to raise_error
    expect { check(["gizmo_label_1"]) }.to raise_error(/gizmo_label_1/)
  end

  it "rejects an undeclared leaf even when the family and index are well formed" do
    expect { check(["widget_2_favorite_color"]) }.to raise_error(/widget_2_favorite_color/)
  end

  it "rejects zero, leading-zero, signed, negative, and decimal indices" do
    %w[widget_0_color widget_01_color widget_+1_color widget_-1_color widget_1.5_color].each do |bad|
      expect { check([bad]) }.to raise_error(/#{Regexp.escape(bad)}/)
    end
  end

  it "matches fixed native-numbered leaves only by exact membership, never by stripping the trailing number" do
    expect { check(["gadget_count_1"]) }.not_to raise_error
    expect { check(["gadget_count_2"]) }.to raise_error(/gadget_count_2/)
  end

  it "reports unknown columns in upload order" do
    expect { check(["widget_9_shape", "zeta_bad", "alpha_bad"]) }
      .to raise_error(/widget_9_shape, zeta_bad, alpha_bad/)
  end

  it "is inert for an importer that supplies no structural rules" do
    expect { check(["widget_3_color"], rules: []) }.to raise_error(/widget_3_color/)
  end

  it "defaults the structural-rule hook to an empty list on the base parser" do
    base = Class.new(BulkImportParser) { def initialize; end }
    expect(base.new.send(:structural_column_rules)).to eq([])
  end

  it "stays a no-op when the importer declares no valid column codes" do
    parser = StructuralRuleSeamParser.new(["marker", "anything_at_all"], nil, [widget_rule])
    expect { parser.send(:check_unknown_columns) }.not_to raise_error
  end
end
