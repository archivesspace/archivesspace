# frozen_string_literal: true

module LocaleUtils
  class MalformedVariableFixer
    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
    end

    def find_malformed
      issues = []
      content = File.read(file_path, encoding: 'utf-8')
      lines = content.lines

      lines.each_with_index do |line, idx|
        line_num = idx + 1

        # Find space/newline between % and {
        if line.match(/%\s+\{/)
          issues << { type: :space_after_percent, line_num: line_num, line: line }
        end

        # Find full-width percent sign
        if line.match(/％\{[^}]+\}/)
          issues << { type: :fullwidth_percent, line_num: line_num, line: line }
        end

        # Find missing space before %{ (only after word characters)
        if line.match(/[a-zA-Z0-9\u00C0-\u024F\u1E00-\u1EFF]%\{[^}]+\}/)
          issues << { type: :no_space_before_percent, line_num: line_num, line: line }
        end

        # Find unwanted space after opening quote: ' %{var}' → '%{var}'
        if line.match(/'\s+%\{[^}]+\}'/)
          issues << { type: :space_after_quote, line_num: line_num, line: line }
        end
      end

      issues
    end

    def fix_malformed
      content = File.read(file_path, encoding: 'utf-8')
      original_content = content.dup
      changes = 0

      # Fix space/newline between % and { while ensuring space before %
      # Case 1: non-space, non-colon, non-bracket followed by % whitespace { → add space before %
      # (exclude colon to avoid YAML parsing issues with unquoted values)
      # (exclude brackets, parentheses, quotes to avoid adding unwanted spaces in patterns like [%{var}])
      # \s+ matches one or more whitespace characters including newlines
      no_space_count = content.scan(/([^\s:\[\({"'])%\s+\{/).length
      content.gsub!(/([^\s:\[\({"'])%\s+\{/, '\1 %{')
      changes += no_space_count

      # Case 2a: colon directly before % whitespace { → add space after colon and remove space after %
      #
      # Pattern 1: Inside quoted strings
      # "text:% {var}" or 'text:% {var}' → "text: %{var}" or 'text: %{var}'
      colon_in_quotes_count = content.scan(/(['"])([^'"]*):(%\s*\{[^}]+\}[^'"]*)\1/).length
      content.gsub!(/(['"])([^'"]*):(%\s*\{[^}]+\}[^'"]*)\1/) do
        quote = $1
        before = $2
        var_part = $3.gsub(/\s+\{/, '{')
        "#{quote}#{before}: #{var_part}#{quote}"
      end
      changes += colon_in_quotes_count

      # Pattern 2: Unquoted single-line values with ": %{" or ":% {" pattern
      # Add quotes to ensure valid YAML when strings include interpolation after colons
      # Only handles single-line values to avoid interfering with multi-line quoted strings
      unquoted_colon_count = content.scan(/^(\s+\w+:) ([^"'\n][^\n]*:\s*%\s*\{[^}]+\}[^\n]*)$/).length
      content.gsub!(/^(\s+\w+:) ([^"'\n][^\n]*:\s*%\s*\{[^}]+\}[^\n]*)$/) do
        key_part = $1
        value_text = $2
        # Fix spacing in variables: :% { → : %{
        fixed_value = value_text.gsub(/:\s*%\s*\{/, ': %{')
        "#{key_part} \"#{fixed_value}\""
      end
      changes += unquoted_colon_count

      # Case 2b: space, colon with space, or opening punctuation before % whitespace { → just remove space after %
      with_space_count = content.scan(/([\s\[\({"'])%\s+\{/).length
      content.gsub!(/([\s\[\({"'])%\s+\{/, '\1%{')
      changes += with_space_count

      # Fix full-width percent sign while ensuring space before %
      # Case 1: non-space, non-colon followed by full-width %
      no_space_fw_count = content.scan(/([^\s:])％\{/).length
      content.gsub!(/([^\s:])％\{/, '\1 %{')
      changes += no_space_fw_count

      # Case 2: After ": " (colon space) followed by full-width % at start of unquoted value
      # Need to add quotes to avoid YAML syntax error (% has special meaning at value start)
      colon_space_fw_count = content.scan(/:\s+％\{[^}]+\}[^\n"]*/).length
      content.gsub!(/(:\s+)％\{([^}]+)\}([^\n"]*)/) do
        # Add quotes around the entire value if it's not already quoted
        "#{$1}\"%{#{$2}}#{$3}\""
      end
      changes += colon_space_fw_count

      # Case 3: Other whitespace before full-width % (spaces, tabs, etc)
      other_space_fw_count = content.scan(/(?<!:)(\s)％\{/).length
      content.gsub!(/(?<!:)(\s)％\{/, '\1%{')
      changes += other_space_fw_count

      # Fix missing space before %{ (but not after colons, quotes, brackets, or tabs)
      # Only add space after alphanumeric characters or closing punctuation
      # Use negative lookbehind to exclude escape sequences like \t, \n, \r
      no_space_before_count = content.scan(/(?<!\\)([a-zA-Z0-9\u00C0-\u024F\u1E00-\u1EFF])(%\{)/).length
      content.gsub!(/(?<!\\)([a-zA-Z0-9\u00C0-\u024F\u1E00-\u1EFF])(%\{)/, '\1 \2')
      changes += no_space_before_count

      # Fix unwanted spaces after opening quotes where variable is enclosed in quotes
      # Pattern: ' %{var}' → '%{var}'
      quote_space_count = content.scan(/'\s+%\{[^}]+\}'/).length
      content.gsub!(/'\s+(%\{[^}]+\})'/, "'\\1'")
      changes += quote_space_count

      if content != original_content
        File.write(file_path, content, encoding: 'utf-8')
      end

      changes
    end
  end
end
