# frozen_string_literal: true

require_relative '../../locale_utils/yaml_validator'
require 'tmpdir'
require 'fileutils'

RSpec.describe LocaleUtils::YamlValidator do
  let(:test_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(test_dir)
  end

  describe '#validate' do
    context 'with valid YAML files' do
      it 'reports all files as valid' do
        File.write(File.join(test_dir, 'en.yml'), "en:\n  key: value\n")
        File.write(File.join(test_dir, 'es.yml'), "es:\n  key: valor\n")

        validator = described_class.new([test_dir])
        result = validator.validate

        aggregate_failures do
          expect(result).to eq(0)
          expect(validator.valid_count).to eq(2)
          expect(validator.invalid_count).to eq(0)
          expect(validator.errors).to be_empty
        end
      end
    end

    context 'with invalid YAML files' do
      it 'reports syntax errors' do
        File.write(File.join(test_dir, 'bad.yml'), "en:\n  key: value: %{var}\n")

        validator = described_class.new([test_dir])
        result = validator.validate

        aggregate_failures do
          expect(result).to eq(1)
          expect(validator.valid_count).to eq(0)
          expect(validator.invalid_count).to eq(1)
          expect(validator.errors).not_to be_empty
        end
      end
    end

    context 'with mixed valid and invalid files' do
      it 'reports both counts correctly' do
        File.write(File.join(test_dir, 'valid.yml'), "en:\n  key: value\n")
        File.write(File.join(test_dir, 'invalid.yml'), "en:\n  key: [\n") # unclosed array

        validator = described_class.new([test_dir])
        result = validator.validate

        aggregate_failures do
          expect(result).to eq(1)
          expect(validator.valid_count).to eq(1)
          expect(validator.invalid_count).to eq(1)
        end
      end
    end

    context 'with duplicate keys' do
      it 'reports a nested duplicate key with both line numbers' do
        File.write(
          File.join(test_dir, 'uk.yml'),
          "uk:\n  file_version:\n    _frontend:\n      messages:\n        no_iiif_viewer: Text\n" \
          "  file_version:\n    _frontend:\n      action:\n        add: Add\n"
        )

        validator = described_class.new([test_dir])
        result = validator.validate

        aggregate_failures do
          expect(result).to eq(1)
          expect(validator.valid_count).to eq(0)
          expect(validator.invalid_count).to eq(1)

          error = validator.errors[File.join(test_dir, 'uk.yml')]
          expect(error[:message]).to eq('1 duplicate key found')
          expect(error[:context]).to include("'uk.file_version'")
          expect(error[:context]).to include('line 6')
          expect(error[:context]).to include('line 2')
        end
      end

      it 'reports every duplicate in a file' do
        File.write(
          File.join(test_dir, 'en.yml'),
          "en:\n  one: 1\n  one: 1\n  nested:\n    two: 2\n    two: 2\n"
        )

        validator = described_class.new([test_dir])
        validator.validate

        error = validator.errors[File.join(test_dir, 'en.yml')]

        aggregate_failures do
          expect(error[:message]).to eq('2 duplicate keys found')
          expect(error[:context]).to include("'en.one'")
          expect(error[:context]).to include("'en.nested.two'")
        end
      end

      it 'does not report the same key used in sibling mappings' do
        File.write(
          File.join(test_dir, 'en.yml'),
          "en:\n  accession:\n    title: Title\n  resource:\n    title: Title\n"
        )

        validator = described_class.new([test_dir])
        result = validator.validate

        aggregate_failures do
          expect(result).to eq(0)
          expect(validator.valid_count).to eq(1)
          expect(validator.errors).to be_empty
        end
      end

      it 'does not report merge keys used in separate mappings' do
        File.write(
          File.join(test_dir, 'en.yml'),
          "en:\n  defaults: &defaults\n    label: Label\n" \
          "  first:\n    <<: *defaults\n  second:\n    <<: *defaults\n"
        )

        validator = described_class.new([test_dir])
        result = validator.validate

        aggregate_failures do
          expect(result).to eq(0)
          expect(validator.valid_count).to eq(1)
        end
      end
    end

    context 'with non-existent directory' do
      it 'handles gracefully' do
        validator = described_class.new(['/nonexistent/path'])
        result = validator.validate

        aggregate_failures do
          expect(result).to eq(0)
          expect(validator.valid_count).to eq(0)
          expect(validator.invalid_count).to eq(0)
        end
      end
    end

    context 'with empty directory' do
      it 'reports no files' do
        validator = described_class.new([test_dir])
        result = validator.validate

        aggregate_failures do
          expect(result).to eq(0)
          expect(validator.valid_count).to eq(0)
          expect(validator.invalid_count).to eq(0)
        end
      end
    end
  end
end
