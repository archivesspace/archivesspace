# frozen_string_literal: true

module LocaleUtils
  class Replacement
    attr_reader :old_line, :new_line, :key_path

    def initialize(old_line, new_line, key_path)
      @old_line = old_line
      @new_line = new_line
      @key_path = key_path
    end
  end
end
