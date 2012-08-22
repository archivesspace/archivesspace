require 'net/http'
require 'json'

class Subject < JSONModel(:subject)
   attr_accessor :display_string


   def display_string
      return @display_string if @display_string
      @display_string = terms.collect {|t| t["term"]}.join(" -- ")
      @display_string
   end


   def available_terms
      return @available_terms if @available_terms
      terms_uri = URI("#{ArchivesSpace::Application.config.backend_url}/vocabularies/#{vocab_id}/terms")
      response = Net::HTTP.get(terms_uri)
      @available_terms = JSON.parse(response)
      @available_terms
   end


    def to_hash     
       hash = super
       hash["display_string"] = display_string
       hash
    end


end
