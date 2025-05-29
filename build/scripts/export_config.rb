require 'config/config-distribution'

def main
  if ARGV.length < 1
    raise "No output file given"
  end

  output_file = ARGV[0]
  apply_env_overrides = ARGV[1]

  config = AppConfig.read_defaults.gsub(/^/, "#")

  if apply_env_overrides
    ENV.select { |key, _value| key =~ /^APPCONFIG_/ }.each do |envvar, value|
      property = envvar.partition('_').last.downcase.to_sym
      property_value = AppConfig.parse_value(value)
      property_value = "'#{property_value}'" if property_value.is_a?(String)

      config = config.gsub(/^#AppConfig\[:#{property}\].*/, "AppConfig[:#{property}] = #{property_value}")
    end
  end

  File.write(output_file, "# Configuration defaults are shown below\n\n" + config )
end

main
