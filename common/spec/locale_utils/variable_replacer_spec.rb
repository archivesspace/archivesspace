# frozen_string_literal: true

require_relative '../../locale_utils/variable_replacer'
require_relative '../../locale_utils/locale_file'
require_relative '../../locale_utils/locale_entry'
require_relative '../../locale_utils/line_info'
require_relative '../../locale_utils/replacement'
require 'tempfile'

RSpec.describe LocaleUtils::VariableReplacer do
  let(:fixtures_path) { File.join(__dir__, 'fixtures') }
  let(:en_file_path) { File.join(fixtures_path, 'en.yml') }
  let(:uk_file_path) { File.join(fixtures_path, 'uk.yml') }

  let(:english_file) { LocaleUtils::LocaleFile.new(en_file_path) }
  let(:ukrainian_file) { LocaleUtils::LocaleFile.new(uk_file_path) }
  let(:replacer) { described_class.new(ukrainian_file, english_file) }

  describe '#find_replacements' do
    it 'finds replacements for translated variables' do
      replacements = replacer.find_replacements

      expect(replacements).to be_an(Array)
      expect(replacements).not_to be_empty
    end

    it 'creates Replacement objects' do
      replacements = replacer.find_replacements

      expect(replacements.first).to be_a(LocaleUtils::Replacement)
    end

    it 'identifies the correct variable to fix' do
      replacements = replacer.find_replacements

      results_replacement = replacements.find { |r| r.key_path.include?('search.results') }
      expect(results_replacement).not_to be_nil
      expect(results_replacement.old_line).to include('%{підрахунок}')
      expect(results_replacement.new_line).to include('%{count}')
    end

    it 'does not create replacements for correct variables' do
      replacements = replacer.find_replacements

      filter_replacement = replacements.find { |r| r.new_line.include?('%{filter_name}') }
      field_replacement = replacements.find { |r| r.new_line.include?('%{field}') }

      expect(filter_replacement).to be_nil
      expect(field_replacement).to be_nil
    end

    it 'does not create replacements for entries with malformed variables' do
      replacements = replacer.find_replacements

      malformed_replacement = replacements.find { |r| r.key_path.include?('errors.malformed') }
      expect(malformed_replacement).to be_nil
    end

    it 'handles multiple variables in one entry' do
      replacements = replacer.find_replacements

      nested_replacement = replacements.find { |r| r.key_path.include?('nested.deep.value') }
      expect(nested_replacement).not_to be_nil
      expect(nested_replacement.new_line).to include('%{user_name}')
      expect(nested_replacement.new_line).to include('%{item_count}')
    end
  end

  describe '#apply_replacements' do
    let(:temp_file) do
      file = Tempfile.new(['uk', '.yml'])
      File.write(file.path, File.read(uk_file_path))
      file
    end

    after do
      temp_file.close
      temp_file.unlink
    end

    it 'applies replacements to the file' do
      temp_locale_file = LocaleUtils::LocaleFile.new(temp_file.path)
      temp_replacer = described_class.new(temp_locale_file, english_file)
      replacements = temp_replacer.find_replacements

      changes = temp_replacer.apply_replacements(replacements)

      expect(changes).to be > 0
    end

    it 'actually modifies the file content' do
      temp_locale_file = LocaleUtils::LocaleFile.new(temp_file.path)
      temp_replacer = described_class.new(temp_locale_file, english_file)
      replacements = temp_replacer.find_replacements

      temp_replacer.apply_replacements(replacements)

      updated_content = File.read(temp_file.path)

      aggregate_failures do
        expect(updated_content).to include('Знайдено %{count} результатів')
        expect(updated_content).to include('%{user_name}')
      end
    end

    it 'returns 0 when there are no replacements' do
      temp_locale_file = LocaleUtils::LocaleFile.new(en_file_path)
      temp_replacer = described_class.new(temp_locale_file, english_file)

      changes = temp_replacer.apply_replacements([])

      expect(changes).to eq(0)
    end

    it 'preserves file structure and formatting' do
      original_lines = File.readlines(temp_file.path)

      temp_locale_file = LocaleUtils::LocaleFile.new(temp_file.path)
      temp_replacer = described_class.new(temp_locale_file, english_file)
      replacements = temp_replacer.find_replacements
      temp_replacer.apply_replacements(replacements)

      updated_lines = File.readlines(temp_file.path)

      expect(updated_lines.length).to eq(original_lines.length)
      expect(updated_lines[0]).to eq(original_lines[0])
    end
  end

  describe 'private methods' do
    describe 'matching logic' do
      it 'matches entries by full path' do
        replacements = replacer.find_replacements

        expect(replacements).not_to be_empty
      end

      it 'handles entries without line info gracefully' do
        replacements = replacer.find_replacements

        aggregate_failures do
          replacements.each do |replacement|
            expect(replacement.old_line).not_to be_nil
            expect(replacement.new_line).not_to be_nil
          end
        end
      end
    end
  end

  describe 'multiline value handling' do
    it 'finds replacements in multiline literal blocks' do
      replacements = replacer.find_replacements

      multiline_replacement = replacements.find { |r| r.key_path.include?('messages.multiline_literal') }
      expect(multiline_replacement).not_to be_nil

      expect(multiline_replacement.old_line).to include('%{назва_змінної}')
      expect(multiline_replacement.new_line).to include('%{variable_name}')
    end

    it 'extracts variables from multiline folded blocks' do
      uk_entry = ukrainian_file.structure['uk.messages.multiline_folded']
      en_entry = english_file.structure['en.messages.multiline_folded']

      expect(uk_entry).not_to be_nil
      expect(en_entry).not_to be_nil
      expect(uk_entry.variables).not_to be_empty
      expect(en_entry.variables).not_to be_empty
    end

    context 'in multiline values' do
      let(:temp_file) do
        file = Tempfile.new(['uk', '.yml'])
        File.write(file.path, File.read(uk_file_path))
        file
      end

      after do
        temp_file.close
        temp_file.unlink
      end

      it 'replaces variables' do
        temp_locale_file = LocaleUtils::LocaleFile.new(temp_file.path)

        temp_replacer = described_class.new(temp_locale_file, english_file)
        replacements = temp_replacer.find_replacements

        temp_replacer.apply_replacements(replacements)

        updated_content = File.read(temp_file.path)

        expect(updated_content).to include('%{variable_name}')
        expect(updated_content).to include('%{count}')
      end
    end
  end
end
