# frozen_string_literal: true

require 'yaml'

module LocaleUtils
  class YamlValidator
    attr_reader :directories, :errors, :valid_count, :invalid_count

    def initialize(directories)
      @directories = directories
      @errors = {}
      @valid_count = 0
      @invalid_count = 0
    end

    def validate
      directories.each do |locale_dir|
        next unless Dir.exist?(locale_dir)

        validate_directory(locale_dir)
      end

      print_summary
      invalid_count
    end

    private

    def validate_directory(locale_dir)
      Dir.glob(File.join(locale_dir, '*.yml')).sort.each do |yml_file|
        validate_file(yml_file)
      end
    end

    def validate_file(file_path)
      puts "\nValidating: #{file_path}"

      begin
        YAML.load_file(file_path, aliases: true)
        puts '  ✓ Valid YAML'
        @valid_count += 1
      rescue Psych::SyntaxError => e
        puts "  ✗ Invalid YAML: #{e.message}"

        error_context = extract_error_context(file_path, e)
        @errors[file_path] = {
          message: e.message,
          context: error_context
        }
        @invalid_count += 1
      rescue => e
        puts "  ✗ Error: #{e.class} - #{e.message}"
        @errors[file_path] = {
          message: "#{e.class}: #{e.message}",
          context: nil
        }
        @invalid_count += 1
      end
    end

    def extract_error_context(file_path, error)
      if error.message =~ /at line (\d+) column (\d+)/
        line_num = $1.to_i
        column = $2.to_i

        lines = File.readlines(file_path)

        start_line = [line_num - 3, 0].max
        end_line = [line_num + 2, lines.length - 1].min

        context_lines = []
        (start_line..end_line).each do |i|
          line_number = i + 1
          prefix = line_number == line_num ? '>>> ' : '    '
          context_lines << "#{prefix}#{line_number}: #{lines[i]}"

          if line_number == line_num && column > 0
            pointer = ' ' * (prefix.length + line_number.to_s.length + 2 + column - 1) + '^'
            context_lines << pointer
          end
        end

        context_lines.join
      else
        nil
      end
    end

    def print_summary
      puts 'VALIDATION SUMMARY'
      puts "Valid files:   #{valid_count}"
      puts "Invalid files: #{invalid_count}"

      if errors.any?
        puts 'ERRORS'
        errors.each do |file, error_info|
          puts "\n#{file}:"
          puts "  #{error_info[:message]}"
          if error_info[:context]
            puts "\n#{error_info[:context]}"
          end
        end
      end
    end
  end
end
