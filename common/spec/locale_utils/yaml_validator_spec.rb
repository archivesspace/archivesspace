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
