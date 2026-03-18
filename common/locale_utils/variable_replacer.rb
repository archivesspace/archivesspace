# frozen_string_literal: true

module LocaleUtils
  class VariableReplacer
    def initialize(locale_file, english_file)
      @locale_file = locale_file
      @english_file = english_file
    end

    def find_replacements
      replacements = []

      @locale_file.structure.each do |full_path, locale_entry|
        english_entry = find_english_match(full_path)
        next unless english_entry

        replacement = build_replacement(locale_entry, english_entry, full_path)
        replacements << replacement if replacement
      end

      replacements
    end

    def apply_replacements(replacements)
      return 0 if replacements.empty?

      content = @locale_file.lines.join
      changes = 0

      replacements.each do |replacement|
        if content.include?(replacement.old_line)
          content = content.sub(replacement.old_line, replacement.new_line)
          puts "  Fixed: #{replacement.key_path}"
          changes += 1
        end
      end

      File.write(@locale_file.file_path, content, encoding: 'utf-8')
      changes
    end

    private

    def find_english_match(full_path)
      parts = full_path.split('.', 2)

      @english_file.structure['en.' + parts[1]]
    end

    def build_replacement(locale_entry, english_entry, full_path)
      return nil unless locale_entry.has_line_info?
      return nil unless variables_differ?(locale_entry, english_entry)

      old_line = locale_entry.full_line
      new_line = replace_variables(old_line, english_entry.variables, locale_entry.variables)

      return nil if new_line == old_line

      Replacement.new(old_line, new_line, full_path)
    end

    def variables_differ?(locale_entry, english_entry)
      locale_entry.variables.length == english_entry.variables.length &&
        locale_entry.variables != english_entry.variables
    end

    def replace_variables(line, english_variables, locale_variables)
      new_line = line.dup

      english_variables.zip(locale_variables).each do |en_var, loc_var|
        if en_var != loc_var
          old_placeholder = "%{#{loc_var}}"
          new_placeholder = "%{#{en_var}}"
          new_line = new_line.sub(old_placeholder, new_placeholder)
        end
      end

      new_line
    end
  end
end
