require 'spec_helper'

describe "Generate REST Documentation" do


 it "gets all the endpoints and makes something can write documentation for" do
 
 
endpoints = ArchivesSpaceService::Endpoint.all.sort{|a,b| a[:uri] <=> b[:uri]}                                                                                                      
output = {}
problems = []

models = {}
    JSONModel.models.each_pair do |type, klass| 
      begin
        models[type] = JSON.parse( build("json_#{type}".to_sym).to_json )
      rescue => err
        # if you want a verbose output of the issues, you can set an ENV  
        $stderr.puts "Model problem with #{klass} : #{err.message}" if ENV["BUILD_DOCUMENTATION"]
      end
    end

endpoints.each do |e|

      output[e[:uri]] ||= {}
      output[e[:uri]][e[:method]] = {}
      e[:params].each do |p|
        begin       
          klass = p[1]
          klass = klass.first if klass.is_a?(Array) 
          
          if klass.is_a?(Symbol)
            record = klass.to_s
          elsif klass.respond_to?(:record_type)
            r = models[klass.record_type] || [ "Example Missing" ]
            record = r
          elsif klass.to_s.include?("RESTHelpers")
            record = klass.to_s.split("::").last
          elsif klass == Integer
            record = "1"
          else
            record = generate(klass.name.downcase.to_sym)
          end
          output[e[:uri]][e[:method]][p[0]] = record
        rescue => err
          # $stderr.puts "problem with #{e[:uri]} #{e[:method]}"
          problems << { :class => klass, :backtrace => err.backtrace,  :message => err.message }
          next 
          # raise err 
        end
      end

end
    
    file = File.join(File.dirname(__FILE__), '../../', "endpoint_examples.json")
    file_problems = File.join(File.dirname(__FILE__), '../../', "endpoint_examples_problems.json")
    File.open(file, "w") {  |f| f << output.to_json }
    File.open(file_problems, "w") {  |f| f << JSON.pretty_generate(problems) }
    $stderr.puts "example file put at #{file}. Problems logged in #{file_problems}" 
    


end
end 
