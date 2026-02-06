# frozen_string_literal: true

module LocaleUtils
  class LocaleEntry
    attr_reader :value, :variables, :line_info

    def initialize(value, line_info)
      @value = value
      @line_info = line_info
      @variables = extract_variables(value)
    end

    def line_num
      line_info&.line_num
    end

    def full_line
      line_info&.full_line
    end

    def has_line_info?
      !line_info.nil?
    end

    private

    def extract_variables(text)
      text.scan(/%\{([^}]+)\}/).flatten
    end
  end
end
