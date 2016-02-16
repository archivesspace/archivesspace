require 'spec_helper'

describe "Generate REST Documentation" do


 it "gets all the endpoints and makes something can write documentation for" do
 
endpoints = [
 {:uri=>"/users/:id", :description=>"Update a user's account", :method=>:post, :params=>[["id", Integer, "The ID of the record"], ["password", String, "The user's password", {:optional=>true}], ["groups", [String], "Array of groups URIs to assign the user to", {:optional=>true}], ["remove_groups", RESTHelpers::BooleanParam, "Remove all groups from the user for the current repo_id if true", {:optional=>true}], ["repo_id", Integer, "The Repository groups to clear", {:optional=>true}], ["user", JSONModel(:user), "The updated record", {:body=>true}]], :paginated=>false, :returns=>[[200, "{:status => \"Updated\", :id => (id of updated object)}"], [400, "{:error => (description of error)}"]]}
 ]                                                                                              
 
output = {}
problems = []

models = {}
    JSONModel.models.each_pair do |type, klass| 
      begin
        models[type] = JSON.parse( build("json_#{type}".to_sym).to_json )
      rescue => err
        $stderr.puts "Model problem with #{klass} : #{err.message}"
      end
    end

endpoints.each do |e|
  
      output[e[:uri]] = {}
      output[e[:uri]][e[:method]] = {}
      e[:params].each do |p|
        begin       
          puts p[0]
          klass = p[1]
          klass = klass.first if klass.is_a?(Array) 
          
          if klass.is_a?(Symbol)
            record = klass.to_s
          elsif klass.respond_to?(:record_type)
            r = models[klass.record_type] || [ "Example Missing" ]
            puts r.to_json 
            puts "Add factory for #{klass}" if r.is_a?(Array) 
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
          problems << { :class => klass, :backtrace => err.backtrace,  :message => err.message }
          next 
          # raise err 
        end
      end

end

puts output
File.open(File.join( "/tmp/" ,"endpoint_examples.json"), "w") {  |file| file <<  JSON.pretty_generate(output) } 
puts problems.inspect

end
end 
