# frozen_string_literal: true

require_relative '../../locale_utils/locale_variables'
require 'tempfile'
require 'fileutils'

RSpec.describe LocaleUtils::LocaleVariables do
  let(:fixtures_path) { File.join(__dir__, 'fixtures') }
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '#initialize' do
    it 'creates a LocaleVariables with directory list' do
      locale_vars = described_class.new([fixtures_path])

      expect(locale_vars.directories).to eq([fixtures_path])
      expect(locale_vars.total_changes).to eq(0)
    end
  end

  describe '#check' do
    context 'with no changes needed' do
      it 'returns 0 when comparing English file with itself' do
        test_dir = File.join(temp_dir, 'locales')
        FileUtils.mkdir_p(test_dir)
        FileUtils.cp(File.join(fixtures_path, 'en.yml'), test_dir)

        locale_vars = described_class.new([test_dir])

        expect { locale_vars.check }.to output(/TOTAL CHANGES: 0/).to_stdout
        expect(locale_vars.total_changes).to eq(0)
      end
    end

    context 'with translated variables' do
      it 'finds and reports changes' do
        # Set up a directory with en.yml and uk.yml
        test_dir = File.join(temp_dir, 'locales')
        FileUtils.mkdir_p(test_dir)
        FileUtils.cp(File.join(fixtures_path, 'en.yml'), test_dir)
        FileUtils.cp(File.join(fixtures_path, 'uk.yml'), test_dir)

        locale_vars = described_class.new([test_dir])

        expect { locale_vars.check }.to output(/Fixed:/).to_stdout
        expect(locale_vars.total_changes).to be > 0
      end

      it 'actually fixes the variables' do
        test_dir = File.join(temp_dir, 'locales')
        FileUtils.mkdir_p(test_dir)
        FileUtils.cp(File.join(fixtures_path, 'en.yml'), test_dir)
        uk_path = File.join(test_dir, 'uk.yml')
        FileUtils.cp(File.join(fixtures_path, 'uk.yml'), uk_path)

        locale_vars = described_class.new([test_dir])
        locale_vars.check

        updated_content = File.read(uk_path)

        expect(updated_content).to include('Знайдено %{count} результатів')
        expect(updated_content).to include('%{type}')
      end
    end

    context 'with malformed variables' do
      it 'fixes space after percent sign and adds space before' do
        test_dir = File.join(temp_dir, 'malformed')
        FileUtils.mkdir_p(test_dir)
        FileUtils.cp(File.join(fixtures_path, 'en.yml'), test_dir)

        malformed_path = File.join(test_dir, 'es.yml')
        File.write(malformed_path, "es:\n  test: \"Result% {count} items\"\n")

        locale_vars = described_class.new([test_dir])
        locale_vars.check

        updated_content = File.read(malformed_path)
        expect(updated_content).to include(' %{count}')
        expect(updated_content).not_to include('% {count}')
      end

      it 'fixes full-width percent sign without adding space for Japanese' do
        test_dir = File.join(temp_dir, 'fullwidth')
        FileUtils.mkdir_p(test_dir)
        FileUtils.cp(File.join(fixtures_path, 'en.yml'), test_dir)

        malformed_path = File.join(test_dir, 'ja.yml')
        File.write(malformed_path, "ja:\n  test: \"結果％{count}項目\"\n")

        locale_vars = described_class.new([test_dir])
        locale_vars.check

        updated_content = File.read(malformed_path)
        expect(updated_content).to include('結果%{count}項目')
        expect(updated_content).not_to include('％{count}')
        expect(updated_content).not_to include(' %{count}')  # No space for Japanese
      end
    end

    context 'with multiple directories' do
      it 'processes all directories' do
        dir1 = File.join(temp_dir, 'locales1')
        dir2 = File.join(temp_dir, 'locales2')

        [dir1, dir2].each do |dir|
          FileUtils.mkdir_p(dir)
          FileUtils.cp(File.join(fixtures_path, 'en.yml'), dir)
          FileUtils.cp(File.join(fixtures_path, 'uk.yml'), dir)
        end

        locale_vars = described_class.new([dir1, dir2])

        expect { locale_vars.check }.to output(/.*locales1.*/).to_stdout
        expect { locale_vars.check }.to output(/.*locales2.*/).to_stdout
      end
    end

    context 'with missing English file' do
      it 'skips directories without en.yml' do
        test_dir = File.join(temp_dir, 'no_english')
        FileUtils.mkdir_p(test_dir)
        FileUtils.cp(File.join(fixtures_path, 'uk.yml'), test_dir)

        locale_vars = described_class.new([test_dir])

        expect { locale_vars.check }.not_to output(/Processing:/).to_stdout
        expect(locale_vars.total_changes).to eq(0)
      end
    end
  end

  describe 'error handling' do
    it 'handles malformed YAML files gracefully' do
      test_dir = File.join(temp_dir, 'bad_yaml')
      FileUtils.mkdir_p(test_dir)
      FileUtils.cp(File.join(fixtures_path, 'en.yml'), test_dir)

      bad_yaml = File.join(test_dir, 'bad.yml')
      File.write(bad_yaml, "invalid: yaml: content:\n  bad indentation")

      locale_vars = described_class.new([test_dir])

      expect { locale_vars.check }.to output(/mapping values are not allowed here at line 1 column 14/).to_stdout
    end
  end
end
