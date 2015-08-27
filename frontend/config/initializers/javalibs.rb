

puts "initialize java"
Dir.glob('/Users/hoffman/Developer/Projects/archivesspace/common/lib/*.jar') do |file|
  puts file
  require file
end
