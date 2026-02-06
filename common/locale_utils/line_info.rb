# frozen_string_literal: true

module LocaleUtils
  class LineInfo
    attr_reader :line_num, :full_line

    def initialize(line_num, full_line)
      @line_num = line_num
      @full_line = full_line
    end
  end
end
