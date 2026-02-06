# frozen_string_literal: true

require 'yaml'

module LocaleUtils
  class LocaleFile
    attr_reader :file_path, :lines, :structure

    def initialize(file_path)
      @file_path = file_path
      @lines = File.readlines(file_path, encoding: 'utf-8')
      @structure = parse_structure
    end

    def language_code
      @language_code ||= File.basename(file_path, '.yml')
    end

    def empty?
      structure.empty?
    end

    private

    def parse_structure
      yaml_data = YAML.load_file(file_path, aliases: true)
      return {} if yaml_data.nil? || yaml_data.empty?

      lang_key = yaml_data.keys.first
      content = yaml_data[lang_key]
      return {} if content.nil?

      result = {}
      flatten_hash(content, lang_key).each do |key_path, value|
        result[key_path] = LocaleEntry.new(value, find_line_for_value(value, key_path))
      end
      result
    end

    def flatten_hash(hash, lang_key = '')
      result = {}

      hash.each do |key, value|
        full_key = lang_key.empty? ? key.to_s : "#{lang_key}.#{key}"

        if value.is_a?(Hash)
          result.merge!(flatten_hash(value, full_key))
        else
          result[full_key] = value.to_s
        end
      end

      result
    end

    def find_line_for_value(value, key_path)
      key_name = key_path.split('.').last

      lines.each_with_index do |line, idx|
        next if line.strip.empty? || line.strip.start_with?('#')

        if line =~ /^\s*#{Regexp.escape(key_name)}:/
          if line.strip.end_with?('|', '>')
            return collect_multiline_block_lines(idx, line)
          end

          if value.length > line.length
            return collect_inline_multiline_lines(idx, line, value)
          end

          return LineInfo.new(idx + 1, line)
        end
      end

      search_value = value.split("\n").first&.strip
      return nil if search_value.nil? || search_value.empty?

      lines.each_with_index do |line, idx|
        next if line.strip.empty? || line.strip.start_with?('#')

        if line.include?(search_value)
          return LineInfo.new(idx + 1, line)
        end
      end

      nil
    end

    # For | or > block scalars, collect all subsequent indented lines
    def collect_multiline_block_lines(start_idx, first_line)
      collected_lines = []
      base_indent = first_line[/^\s*/].length

      (start_idx + 1...lines.length).each do |idx|
        line = lines[idx]

        # Stop if we hit an empty line followed by a non-indented line
        # or a line with a new key at the same or lower indentation
        if line.strip.empty?
          next if idx + 1 < lines.length && lines[idx + 1][/^\s*/].length > base_indent
          break
        end

        current_indent = line[/^\s*/].length
        if current_indent <= base_indent && line =~ /^\s*\w+:/
          break
        end

        collected_lines << line
      end

      return nil if collected_lines.empty?

      full_line = collected_lines.join
      LineInfo.new(start_idx + 2, full_line) # +2 because we skip the key line
    end

    # For inline multi-line values (quoted strings that span lines)
    def collect_inline_multiline_lines(start_idx, first_line, full_value)
      collected_lines = [first_line]
      base_indent = first_line[/^\s*/].length

      return LineInfo.new(start_idx + 1, first_line) if first_line.include?(full_value)

      (start_idx + 1...lines.length).each do |idx|
        line = lines[idx]
        break if line.strip.empty?

        current_indent = line[/^\s*/].length

        # Stop if we hit a line at the same or lower indentation that starts a new key
        if current_indent <= base_indent && line =~ /^\s*\w+:/
          break
        end

        if current_indent > base_indent
          collected_lines << line
          break if collected_lines.join('').include?(full_value[0...[full_value.length, 100].min])
        else
          break
        end
      end

      full_line = collected_lines.join
      LineInfo.new(start_idx + 1, full_line)
    end
  end
end
