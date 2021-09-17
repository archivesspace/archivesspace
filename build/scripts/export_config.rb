require 'config/config-distribution'

def main
  if ARGV.length != 1
    raise "No output file given"
  end

  output_file = ARGV[0]

  File.write(output_file, "# Configuration defaults are shown below\n\n" + AppConfig.read_defaults.gsub(/^/, "#")
            .gsub("#AppConfig[:enable_custom_reports] = false", "#Setting temporarily disabled")
            .gsub("#AppConfig[:display_identifiers_in_largetree_container] = false", "#Setting temporarily disabled")
            .gsub("AppConfig[:pui_display_identifiers_in_resource_tree] = false", "#Setting temporarily disabled"))
end


main
