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
        add_issue_if_matches(line, line_num, /%\s+\{/, :space_after_percent, issues)

        # Find full-width percent sign
        add_issue_if_matches(line, line_num, /％\{[^}]+\}/, :fullwidth_percent, issues)

        # Find missing space before %{ (only after word characters)
        add_issue_if_matches(line, line_num, /[a-zA-Z0-9\u00C0-\u024F\u1E00-\u1EFF]%\{[^}]+\}/, :no_space_before_percent, issues)

        # Find unwanted space after opening quote: ' %{var}' → '%{var}'
        add_issue_if_matches(line, line_num, /'\s+%\{[^}]+\}'/, :space_after_quote, issues)
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
      changes += apply_fix(content, /([^\s:\[\({"'])%\s+\{/, '\1 %{')

      # Case 2a: colon directly before % whitespace { → add space after colon and remove space after %
      #
      # Pattern 1: Inside quoted strings
      # "text:% {var}" or 'text:% {var}' → "text: %{var}" or 'text: %{var}'
      changes += apply_fix(content, /(['"])([^'"]*):(%\s*\{[^}]+\}[^'"]*)\1/) do
        quote = $1
        before = $2
        var_part = $3.gsub(/\s+\{/, '{')
        "#{quote}#{before}: #{var_part}#{quote}"
      end

      # Pattern 2: Unquoted single-line values with ": %{" or ":% {" pattern
      # Add quotes to ensure valid YAML when strings include interpolation after colons
      # Only handles single-line values to avoid interfering with multi-line quoted strings
      changes += apply_fix(content, /^(\s+\w+:) ([^"'\n][^\n]*:\s*%\s*\{[^}]+\}[^\n]*)$/) do
        key_part = $1
        value_text = $2
        # Fix spacing in variables: :% { → : %{
        fixed_value = value_text.gsub(/:\s*%\s*\{/, ': %{')
        "#{key_part} \"#{fixed_value}\""
      end

      # Case 2b: space, colon with space, or opening punctuation before % whitespace { → just remove space after %
      changes += apply_fix(content, /([\s\[\({"'])%\s+\{/, '\1%{')

      # Fix full-width percent sign while ensuring space before %
      # Case 1: non-space, non-colon followed by full-width %
      changes += apply_fix(content, /([^\s:])％\{/, '\1 %{')

      # Case 2: After ": " (colon space) followed by full-width % at start of unquoted value
      # Need to add quotes to avoid YAML syntax error (% has special meaning at value start)
      changes += apply_fix(content, /(:\s+)％\{([^}]+)\}([^\n"]*)/) do
        # Add quotes around the entire value if it's not already quoted
        "#{$1}\"%{#{$2}}#{$3}\""
      end

      # Case 3: Other whitespace before full-width % (spaces, tabs, etc)
      changes += apply_fix(content, /(?<!:)(\s)％\{/, '\1%{')

      # Fix missing space before %{ (but not after colons, quotes, brackets, or tabs)
      # Only add space after alphanumeric characters or closing punctuation
      # Use negative lookbehind to exclude escape sequences like \t, \n, \r
      changes += apply_fix(content, /(?<!\\)([a-zA-Z0-9\u00C0-\u024F\u1E00-\u1EFF])(%\{)/, '\1 \2')

      # Fix unwanted spaces after opening quotes where variable is enclosed in quotes
      # Pattern: ' %{var}' → '%{var}'
      changes += apply_fix(content, /'\s+(%\{[^}]+\})'/, "'\\1'")

      if content != original_content
        File.write(file_path, content, encoding: 'utf-8')
      end

      changes
    end

    private

    def add_issue_if_matches(line, line_num, pattern, issue_type, issues)
      if line.match(pattern)
        issues << { type: issue_type, line_num: line_num, line: line }
      end
    end

    def apply_fix(content, pattern, replacement = nil, &block)
      count = content.scan(pattern).length
      if block_given?
        content.gsub!(pattern, &block)
      else
        content.gsub!(pattern, replacement)
      end
      count
    end
  end
end
