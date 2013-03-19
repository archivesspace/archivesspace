require 'config/config-distribution'

def main
  if ARGV.length != 1
    raise "No output file given"
  end

  output_file = ARGV[0]

  File.write(output_file, "# Configuration defaults are shown below\n\n" + AppConfig.read_defaults.gsub(/^/, "#"))
end


main

