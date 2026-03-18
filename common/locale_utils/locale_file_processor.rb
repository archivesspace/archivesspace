# frozen_string_literal: true

module LocaleUtils
  class LocaleFileProcessor
    attr_reader :directories, :total_changes

    def initialize(directories)
      @directories = directories
      @total_changes = 0
    end

    def check
      directories.each do |locale_dir|
        next unless Dir.exist?(locale_dir)

        en_file_path = File.join(locale_dir, 'en.yml')
        next unless File.exist?(en_file_path)

        process_locale_directory(locale_dir, en_file_path)
      end

      print_summary
      total_changes
    end

    private

    def process_locale_directory(locale_dir, en_file_path)
      english_file = LocaleFile.new(en_file_path)

      Dir.glob(File.join(locale_dir, '*.yml')).sort.each do |yml_file|
        next if File.basename(yml_file) == 'en.yml'

        changes = process_locale_file(yml_file, english_file)
        @total_changes += changes
      end
    end

    def process_locale_file(file_path, english_file)
      puts "\nProcessing: #{file_path}"

      malformed_fixer = MalformedVariableFixer.new(file_path)
      malformed_changes = malformed_fixer.fix_malformed
      if malformed_changes > 0
        puts "  Fixed #{malformed_changes} malformed variables"
      end

      locale_file = LocaleFile.new(file_path)

      if locale_file.empty?
        puts '  No variables found'
        return malformed_changes
      end

      replacer = VariableReplacer.new(locale_file, english_file)
      replacements = replacer.find_replacements

      if replacements.empty?
        puts '  No changes needed' if malformed_changes == 0
        return malformed_changes
      end

      translation_changes = replacer.apply_replacements(replacements)
      total_changes = malformed_changes + translation_changes
      puts "  Total: #{total_changes} variables fixed"
      total_changes
    rescue => e
      puts "  Error: #{e.message}"
      puts e.backtrace.first(5)

      return 0
    end

    def print_summary
      puts "TOTAL CHANGES: #{total_changes}"
    end
  end
end
