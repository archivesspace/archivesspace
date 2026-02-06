# frozen_string_literal: true

require_relative '../../locale_utils/locale_entry'
require_relative '../../locale_utils/line_info'

RSpec.describe LocaleUtils::LocaleEntry do
  let(:line_info) { LocaleUtils::LineInfo.new(10, "  title: 'Found %{count} items'\n") }

  describe '#initialize' do
    it 'creates a LocaleEntry with value and line info' do
      entry = described_class.new('Found %{count} items', line_info)

      expect(entry.value).to eq('Found %{count} items')
      expect(entry.line_info).to eq(line_info)
      expect(entry.variables).to eq(['count'])
    end

    it 'extracts multiple variables from value' do
      entry = described_class.new('From %{start} to %{end}', line_info)

      expect(entry.variables).to eq(['start', 'end'])
    end

    it 'handles value with no variables' do
      entry = described_class.new('No variables here', line_info)

      expect(entry.variables).to eq([])
    end

    it 'works with nil line_info' do
      entry = described_class.new('Test %{var}', nil)

      expect(entry.value).to eq('Test %{var}')
      expect(entry.line_info).to be_nil
      expect(entry.variables).to eq(['var'])
    end
  end

  describe '#line_num' do
    it 'delegates to line_info' do
      entry = described_class.new('Test %{var}', line_info)

      expect(entry.line_num).to eq(10)
    end

    it 'returns nil when line_info is nil' do
      entry = described_class.new('Test %{var}', nil)

      expect(entry.line_num).to be_nil
    end
  end

  describe '#full_line' do
    it 'delegates to line_info' do
      entry = described_class.new('Test %{var}', line_info)

      expect(entry.full_line).to eq("  title: 'Found %{count} items'\n")
    end

    it 'returns nil when line_info is nil' do
      entry = described_class.new('Test %{var}', nil)

      expect(entry.full_line).to be_nil
    end
  end

  describe '#has_line_info?' do
    it 'returns true when line_info is present' do
      entry = described_class.new('Test %{var}', line_info)

      expect(entry.has_line_info?).to be true
    end

    it 'returns false when line_info is nil' do
      entry = described_class.new('Test %{var}', nil)

      expect(entry.has_line_info?).to be false
    end
  end

  describe 'variable extraction' do
    it 'handles variables with underscores' do
      entry = described_class.new('Item: %{item_name}', line_info)

      expect(entry.variables).to eq(['item_name'])
    end

    it 'handles variables with dots (object properties)' do
      entry = described_class.new('User: %{user.name}', line_info)

      expect(entry.variables).to eq(['user.name'])
    end

    it 'handles multiple identical variables' do
      entry = described_class.new('%{count} of %{count} items', line_info)

      expect(entry.variables).to eq(['count', 'count'])
    end

    it 'handles adjacent variables' do
      entry = described_class.new('%{first}%{second}', line_info)

      expect(entry.variables).to eq(['first', 'second'])
    end

    it 'ignores malformed variables with missing closing bracket' do
      entry = described_class.new('Error with %{variable items', line_info)

      expect(entry.variables).to eq([])
    end

    it 'extracts valid variables even when malformed ones are present' do
      entry = described_class.new('Valid %{count} and malformed %{broken text', line_info)

      expect(entry.variables).to eq(['count'])
    end
  end
end
