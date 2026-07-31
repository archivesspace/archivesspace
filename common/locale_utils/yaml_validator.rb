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
        duplicates = find_duplicate_keys(file_path)
      rescue Psych::SyntaxError => e
        puts "  ✗ Invalid YAML: #{e.message}"

        error_context = extract_error_context(file_path, e)
        @errors[file_path] = {
          message: e.message,
          context: error_context
        }
        @invalid_count += 1
        return
      rescue => e
        puts "  ✗ Error: #{e.class} - #{e.message}"
        @errors[file_path] = {
          message: "#{e.class}: #{e.message}",
          context: nil
        }
        @invalid_count += 1
        return
      end

      if duplicates.empty?
        puts '  ✓ Valid YAML'
        @valid_count += 1
      else
        puts "  ✗ Duplicate keys: #{duplicates.length}"

        @errors[file_path] = {
          message: "#{duplicates.length} duplicate #{duplicates.length == 1 ? 'key' : 'keys'} found",
          context: format_duplicates(duplicates)
        }
        @invalid_count += 1
      end
    end

    def find_duplicate_keys(file_path)
      document = Psych.parse_file(file_path)
      return [] unless document

      root = document.respond_to?(:root) ? document.root : document
      duplicates = []
      collect_duplicate_keys(root, [], duplicates)
      duplicates
    end

    def collect_duplicate_keys(node, path, duplicates)
      case node
      when Psych::Nodes::Mapping
        seen = {}

        node.children.each_slice(2) do |key, value|
          key_path = path

          if key.is_a?(Psych::Nodes::Scalar)
            key_path = path + [key.value]

            if seen.key?(key.value)
              duplicates << {
                key: key_path.join('.'),
                line: key.start_line + 1,
                first_line: seen[key.value]
              }
            else
              seen[key.value] = key.start_line + 1
            end
          end

          collect_duplicate_keys(value, key_path, duplicates) if value
        end
      when Psych::Nodes::Sequence
        node.children.each_with_index do |child, index|
          collect_duplicate_keys(child, path + ["[#{index}]"], duplicates)
        end
      end
    end

    def format_duplicates(duplicates)
      duplicates.map do |duplicate|
        "    line #{duplicate[:line]}: '#{duplicate[:key]}' is already defined on line #{duplicate[:first_line]}"
      end.join("\n")
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
