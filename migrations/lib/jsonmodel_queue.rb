module JSONModel
  module Queueable
          
    @@wait_queue = Array.new # JSON objects waiting to be sent in a batch

    def self.save_all
      batch_object = JSONModel::JSONModel(:batch_import).new
      repo_id = Thread.current[:selected_repo_id]

      batch = []

      @@wait_queue.each do |obj|
        batch << obj.to_hash(true)
      end
      batch_object.set_data({:batch => batch})
      
      uri = "/repositories/#{repo_id}/batch_imports"
      url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
      
      response = JSONModel::HTTP.post_json(url, batch_object.to_json)
      
      puts "RESPONSE \n #{response.body.inspect}" if $DEBUG
    end
  
  
    def queue_save
      @@wait_queue.push(self)
    end
   
  end
end

