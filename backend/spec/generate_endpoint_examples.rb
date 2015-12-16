require 'pp'
require 'spec_helper'

describe "Generate REST Documentation" do


 it "gets all the endpoints and makes something can write documentation for" do

    models = {}
    JSONModel.models.each_pair do |type, klass| 
      begin
        models[type] = JSON.parse( build("json_#{type}".to_sym).to_json )
      rescue => err
        $stderr.puts "Model problem with #{klass} : #{err.message}"
      end
    end


    problems = []
    output = {}
    endpoints = ArchivesSpaceService::Endpoint.all.sort{|a,b| a[:uri] <=> b[:uri]}                                                                                                      
    endpoints.each do |e|
  
      output[e[:uri]] = {}
      output[e[:uri]][e[:method]] = {}
      e[:params].each do |p|
        begin       
          output[e[:uri]][e[:method]] = p[0]

          klass = p[1]
          klass = klass.first if klass.is_a?(Array) 
          
          if klass.is_a?(Symbol)
            record = klass.to_s
          elsif klass.respond_to?(:record_type)
            r = models[klass.record_type] || [ "Example Missing" ]
            $stderr.puts "Add factory for #{klass}" if r.is_a?(Array) 
            record = JSON.pretty_generate(r)
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
          problems << { :class => klass, :message => err.message }
          # raise err 
        end
      end

    end
    File.open(File.join( '..', 'docs',"endpoint_examples.json"), "w") {  |file| file <<  JSON.pretty_generate(output) } 
    $stderr.puts problems.inspect
 end

end
