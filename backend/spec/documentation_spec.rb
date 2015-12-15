require 'pp'
require 'spec_helper'

describe "Generate REST Documentation" do


 it "gets all the endpoints and makes something can write documentation for" do

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
          if klass.is_a?(Symbol)
            record = klass
          elsif klass.respond_to?(:record_type)
            r = JSON.parse(build("json_#{klass.record_type}".to_sym).to_json)
            record = JSON.pretty_generate(r)
          elsif klass.is_a?(Array)
            record = generate(klass.first.name.downcase.to_sym)
          elsif klass == RESTHelpers::BooleanParam
            record = false
          elsif klass == Integer
            record = 1
          else
            record = generate(klass.name.downcase.to_sym)
          end

          output[e[:uri]][e[:method]][p[0]] = pp(record)
        rescue => err
          # $stderr.puts "problem with #{e[:uri]} #{e[:method]}"
          problems << klass 
          # raise err 
        end
      end

    end
    File.open(File.join( '.', 'spec',"endpoint_examples.json"), "w") {  |file| file <<  output.to_json } 
    $stderr.puts problems.inspect
 end

end
