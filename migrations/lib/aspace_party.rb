require 'httparty'

class ASpaceParty
  include HTTParty
  base_uri ASpaceImportConfig::ASPACE_BASE
  default_timeout 5

  def initialize(repo_key, dry = false)
    @repo_key = repo_key
    puts "REPO #{@repo_key}"
    @dry = dry
  end

  def post(jo)
    options = { :body => jo.to_json }
    post_uri = jo.class.uri_for( nil,  :repo_id => @repo_key )
    if @dry
      puts "(Not) Posting to #{post_uri}: #{jo.to_json}"
      { :key => 9999 }
    else
      begin
      response = self.class.post( post_uri, options )
      puts response.code
      rescue Timeout::Error => e
        puts "Timout: #{e.message}"
      end        
    end
  end
  
end

