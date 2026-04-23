# frozen_string_literal: true

require_relative '../../locale_utils/replacement'

RSpec.describe LocaleUtils::Replacement do
  describe '#initialize' do
    it 'creates a Replacement with old line, new line, and key path' do
      old_line = "  title: 'Found %{рахувати} items'\n"
      new_line = "  title: 'Found %{count} items'\n"
      key_path = 'uk.search_results.title'

      replacement = described_class.new(old_line, new_line, key_path)

      expect(replacement.old_line).to eq(old_line)
      expect(replacement.new_line).to eq(new_line)
      expect(replacement.key_path).to eq(key_path)
    end

    it 'handles multiline values' do
      old_line = "  message: |\n    Multiple lines with %{переменная}\n"
      new_line = "  message: |\n    Multiple lines with %{variable}\n"
      key_path = 'uk.error.message'

      replacement = described_class.new(old_line, new_line, key_path)

      expect(replacement.old_line).to eq(old_line)
      expect(replacement.new_line).to eq(new_line)
      expect(replacement.key_path).to eq(key_path)
    end
  end
end
