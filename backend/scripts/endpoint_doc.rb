require 'main'

fltr = ARGV[0] || ""

if fltr.length == 0
  puts "All endpoints"
else
  puts "Endpoints matching: #{fltr}"
end

RESTHelpers::Endpoint.all.keep_if { |e| e[:uri] =~ /#{fltr}/ }.each do |e|
  puts "\n#{e[:method]} '#{e[:uri]}':"
  puts "  Description: #{e[:description]}"
  puts "  Parameters: "

  e[:params].each do |param|
    opts = (param[3] or {})

    vs = opts[:validation] ? " -- #{opts[:validation][0]}" : ""

    if opts[:body]
      puts "    #{param[1]} <request body> -- #{param[2]}#{vs}"
    else
      puts "    #{param[1]} #{param[0]} -- #{param[2]}#{vs}"
    end
  end

  #  puts "  Returns: #{e[:returns].inspect}"
  puts "  Returns:"
  e[:returns].each do |ret|
    puts "    #{ret[0]} -- #{ret[1]}"
  end

end
