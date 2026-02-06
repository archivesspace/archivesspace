# frozen_string_literal: true

require_relative '../../locale_utils/malformed_variable_fixer'
require 'tempfile'

RSpec.describe LocaleUtils::MalformedVariableFixer do
  let(:temp_file) do
    file = Tempfile.new(['test', '.yml'])
    file.close
    file
  end

  after do
    temp_file.unlink if temp_file
  end

  describe '#find_malformed' do
    it 'finds variables with space after percent' do
      File.write(temp_file.path, "test: \"Result% {count} items\"\n")
      fixer = described_class.new(temp_file.path)

      issues = fixer.find_malformed

      expect(issues).not_to be_empty
      expect(issues.first[:type]).to eq(:space_after_percent)
      expect(issues.first[:line]).to include('% {count}')
    end

    it 'finds variables with full-width percent sign' do
      File.write(temp_file.path, "test: \"結果％{count}項目\"\n")
      fixer = described_class.new(temp_file.path)

      issues = fixer.find_malformed

      expect(issues).not_to be_empty
      expect(issues.first[:type]).to eq(:fullwidth_percent)
      expect(issues.first[:line]).to include('％{count}')
    end

    it 'finds multiple malformed patterns in one file' do
      content = <<~YAML
        test1: "Result% {count} items"
        test2: "結果％{total}項目"
        test3: "Valid %{valid} variable"
      YAML
      File.write(temp_file.path, content)
      fixer = described_class.new(temp_file.path)

      issues = fixer.find_malformed

      expect(issues.length).to eq(2)
      expect(issues.map { |i| i[:type] }).to contain_exactly(:space_after_percent, :fullwidth_percent)
    end

    it 'returns empty array when no malformed variables found' do
      File.write(temp_file.path, "test: \"Valid %{count} variable\"\n")
      fixer = described_class.new(temp_file.path)

      issues = fixer.find_malformed

      expect(issues).to be_empty
    end

    it 'finds unwanted space after opening quote' do
      File.write(temp_file.path, "test: \"Username ' %{username}' is in use\"\n")
      fixer = described_class.new(temp_file.path)

      issues = fixer.find_malformed

      expect(issues).not_to be_empty
      expect(issues.first[:type]).to eq(:space_after_quote)
      expect(issues.first[:line]).to include("' %{username}'")
    end

    it 'finds multiple issues including quote spaces' do
      content = <<~YAML
        test1: "Result% {count} items"
        test2: "Username ' %{username}' used"
        test3: "Valid %{valid} variable"
      YAML
      File.write(temp_file.path, content)
      fixer = described_class.new(temp_file.path)

      issues = fixer.find_malformed

      expect(issues.length).to eq(2)
      types = issues.map { |i| i[:type] }
      expect(types).to include(:space_after_percent)
      expect(types).to include(:space_after_quote)
    end
  end

  describe '#fix_malformed' do
    it 'fixes space after percent and ensures space before percent' do
      File.write(temp_file.path, "test: \"Result% {count} items\"\n")
      fixer = described_class.new(temp_file.path)

      changes = fixer.fix_malformed

      expect(changes).to eq(1)
      updated_content = File.read(temp_file.path)
      expect(updated_content).to include(' %{count}')
      expect(updated_content).not_to include('% {count}')
    end

    it 'fixes full-width percent sign without adding space for Japanese text' do
      File.write(temp_file.path, "test: \"結果％{count}項目\"\n")
      fixer = described_class.new(temp_file.path)

      changes = fixer.fix_malformed

      expect(changes).to eq(1)
      updated_content = File.read(temp_file.path)
      expect(updated_content).to include('結果%{count}項目')
      expect(updated_content).not_to include('％{count}')
      expect(updated_content).not_to include(' %{count}')  # No space for Japanese
    end

    it 'fixes multiple malformed patterns with language-appropriate spacing' do
      content = <<~YAML
        test1: "Result% {count} items"
        test2: "結果％{total}項目"
        test3: "Another% {value} here"
      YAML
      File.write(temp_file.path, content)
      fixer = described_class.new(temp_file.path)

      changes = fixer.fix_malformed

      expect(changes).to eq(3)
      updated_content = File.read(temp_file.path)
      # Latin text should have space before %{var}
      expect(updated_content).to include('Result %{count}')
      expect(updated_content).to include('Another %{value}')
      # Japanese text should NOT have space before %{var}
      expect(updated_content).to include('結果%{total}項目')
      expect(updated_content).not_to include('% {')
      expect(updated_content).not_to include('％{')
    end

    it 'returns 0 when no malformed variables found' do
      File.write(temp_file.path, "test: \"Valid %{count} variable\"\n")
      fixer = described_class.new(temp_file.path)

      changes = fixer.fix_malformed

      expect(changes).to eq(0)
    end

    it 'preserves file structure and valid variables' do
      content = <<~YAML
        en:
          valid: "Valid %{count} items"
          malformed: "Bad% {value} here"
          another_valid: "Another %{test} variable"
      YAML
      File.write(temp_file.path, content)
      fixer = described_class.new(temp_file.path)

      fixer.fix_malformed

      updated_content = File.read(temp_file.path)
      expect(updated_content).to include('Valid %{count} items')
      expect(updated_content).to include('Bad %{value} here')
      expect(updated_content).to include('Another %{test} variable')
    end

    it 'preserves existing space before percent when fixing' do
      File.write(temp_file.path, "test: \"Text % {count} items\"\n")
      fixer = described_class.new(temp_file.path)

      changes = fixer.fix_malformed

      expect(changes).to eq(1)
      updated_content = File.read(temp_file.path)
      expect(updated_content).to include(' %{count}')
    end

    it 'adds space before percent when missing' do
      File.write(temp_file.path, "test: \"consulte%{ref_id} en la fila\"\n")
      fixer = described_class.new(temp_file.path)

      changes = fixer.fix_malformed

      expect(changes).to eq(1)
      updated_content = File.read(temp_file.path)
      expect(updated_content).to include('consulte %{ref_id}')
      expect(updated_content).not_to include('consulte%{ref_id}')
    end

    it 'removes unwanted space after opening quote' do
      File.write(temp_file.path, "test: \"Username ' %{username}' is in use\"\n")
      fixer = described_class.new(temp_file.path)

      changes = fixer.fix_malformed

      expect(changes).to eq(1)
      updated_content = File.read(temp_file.path)
      expect(updated_content).to include("'%{username}'")
      expect(updated_content).not_to include("' %{username}'")
    end

    it 'fixes multiple unwanted spaces after quotes' do
      content = <<~YAML
        test1: "Value ' %{value}' here"
        test2: "Label ' %{label}' invalid"
        test3: "ID ' %{id}' exists"
      YAML
      File.write(temp_file.path, content)
      fixer = described_class.new(temp_file.path)

      changes = fixer.fix_malformed

      expect(changes).to eq(3)
      updated_content = File.read(temp_file.path)
      expect(updated_content).to include("'%{value}'")
      expect(updated_content).to include("'%{label}'")
      expect(updated_content).to include("'%{id}'")
      expect(updated_content).not_to include("' %{")
    end

    it 'does not modify variables not enclosed in quotes' do
      File.write(temp_file.path, "test: \"Text %{value} here\"\n")
      fixer = described_class.new(temp_file.path)

      changes = fixer.fix_malformed

      expect(changes).to eq(0)
      updated_content = File.read(temp_file.path)
      expect(updated_content).to include("Text %{value} here")
    end
  end
end
