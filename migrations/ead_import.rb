# written for Ruby 1.9.3

require_relative "lib/classes.rb"

input_file = ARGV[0]


if input_file != nil and File.exists? input_file
  puts input_file.inspect
  e = EADReader.new
  e.read(input_file)
end
