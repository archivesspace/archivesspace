# frozen_string_literal: true

require_relative '../../locale_utils/locale_file'
require_relative '../../locale_utils/locale_entry'
require_relative '../../locale_utils/line_info'

RSpec.describe LocaleUtils::LocaleFile do
  let(:fixtures_path) { File.join(__dir__, 'fixtures') }
  let(:en_file_path) { File.join(fixtures_path, 'en.yml') }
  let(:uk_file_path) { File.join(fixtures_path, 'uk.yml') }
  let(:empty_file_path) { File.join(fixtures_path, 'empty.yml') }

  let(:temp_file) do
    file = Tempfile.new(['test', '.yml'])
    file.close
    file
  end

  after do
    temp_file.unlink if temp_file
  end


  describe '#initialize' do
    it 'loads and parses a locale file' do
      locale_file = described_class.new(en_file_path)

      expect(locale_file.file_path).to eq(en_file_path)
      expect(locale_file.lines).to be_an(Array)
      expect(locale_file.structure).to be_a(Hash)
    end

    it 'extracts entries' do
      locale_file = described_class.new(en_file_path)

      expect(locale_file.structure.keys).to include(
        'en.search.results',
        'en.search.filters',
        'en.errors.not_found',
        'en.errors.invalid',
        'en.nested.deep.value',
        'en.greeting'
      )
    end

    it 'includes entries with malformed variables but extracts no variables' do
      locale_file = described_class.new(uk_file_path)

      entry = locale_file.structure['uk.errors.malformed']
      expect(entry).not_to be_nil
      expect(entry.variables).to eq([])
    end

    it 'creates LocaleEntry objects for each entry' do
      locale_file = described_class.new(en_file_path)

      entry = locale_file.structure['en.search.results']
      expect(entry).to be_a(LocaleUtils::LocaleEntry)
      expect(entry.value).to eq('Found %{count} results')
      expect(entry.variables).to eq(['count'])
    end

    it 'includes line information for entries' do
      locale_file = described_class.new(en_file_path)

      entry = locale_file.structure['en.search.results']
      expect(entry.line_info).to be_a(LocaleUtils::LineInfo)
      expect(entry.line_info.full_line).to include('Found %{count} results')
    end
  end

  describe '#language_code' do
    it 'extracts language code from filename' do
      locale_file = described_class.new(en_file_path)
      expect(locale_file.language_code).to eq('en')

      locale_file = described_class.new(uk_file_path)
      expect(locale_file.language_code).to eq('uk')
    end
  end

  describe '#empty?' do
    context 'when file has entries' do
      it 'returns false' do
        locale_file = described_class.new(en_file_path)

        expect(locale_file.empty?).to be false
      end
    end

    context 'when file has no entries' do
      let(:empty_file_path) do
        content = <<~YAML
          gr:
        YAML
        File.write(temp_file.path, content)

        temp_file.path
      end

      it 'returns true' do
        locale_file = described_class.new(empty_file_path)

        expect(locale_file.empty?).to be true
      end
    end
  end

  describe 'variable extraction' do
    it 'extracts variables from nested structures' do
      locale_file = described_class.new(en_file_path)

      entry = locale_file.structure['en.nested.deep.value']
      expect(entry.variables).to eq(['user_name', 'item_count'])
    end

    it 'handles multiple variables in one value' do
      locale_file = described_class.new(en_file_path)

      entry = locale_file.structure['en.nested.deep.value']
      expect(entry.value).to include('%{user_name}')
      expect(entry.value).to include('%{item_count}')
    end
  end

  describe 'translated variable names' do
    it 'detects translated variable names in Ukrainian file' do
      locale_file = described_class.new(uk_file_path)

      entry = locale_file.structure['uk.search.results']
      expect(entry.variables).to eq(['підрахунок'])
    end

    it 'extracts mixed translated and untranslated variables' do
      locale_file = described_class.new(uk_file_path)

      entry = locale_file.structure['uk.nested.deep.value']
      # user_name is untranslated, кількість_елементів is translated
      expect(entry.variables).to eq(['user_name', 'кількість_елементів'])
    end
  end

  describe 'multiline values' do
    it 'handles literal block scalar (|) with variables' do
      locale_file = described_class.new(en_file_path)

      entry = locale_file.structure['en.messages.multiline_literal']
      expect(entry).not_to be_nil
      expect(entry.value).to include('multiline message')
      expect(entry.value).to include('%{variable_name}')
      expect(entry.value).to include('%{line_count}')
      expect(entry.variables).to eq(['variable_name', 'line_count'])
    end

    it 'handles folded block scalar (>) with variables' do
      locale_file = described_class.new(en_file_path)

      entry = locale_file.structure['en.messages.multiline_folded']
      expect(entry).not_to be_nil
      expect(entry.variables).to eq(['count', 'status'])
    end

    it 'extracts translated variables from multiline literal blocks' do
      locale_file = described_class.new(uk_file_path)

      entry = locale_file.structure['uk.messages.multiline_literal']
      expect(entry.variables).to eq(['назва_змінної', 'кількість_рядків'])
    end

    it 'extracts translated variables from multiline folded blocks' do
      locale_file = described_class.new(uk_file_path)

      entry = locale_file.structure['uk.messages.multiline_folded']
      # підрахунок is translated (should be count), статус is translated (should be status)
      expect(entry.variables).to eq(['підрахунок', 'статус'])
    end

    it 'includes line information for multiline entries' do
      locale_file = described_class.new(en_file_path)

      entry = locale_file.structure['en.messages.multiline_literal']
      expect(entry.has_line_info?).to be true
      expect(entry.line_info).to be_a(LocaleUtils::LineInfo)
    end
  end
end
