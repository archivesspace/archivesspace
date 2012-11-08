module ASpaceImport
  class ParseQueue < Array
    include JSONModel

    def initialize(opts)
      @repo_id = opts[:repo_id] if opts[:repo_id]
      @opts = opts
      @subqueue = Array.new # JSON objects waiting to be sent in a batch    
    end
    
    # @subqueue can be serialized to a file if necessary.
    
    def pop
      if self.length > 0
        @subqueue.push(self.last)
        super
      end
    end

    def save
      batch_object = JSONModel(:batch_import).new
      repo_id = Thread.current[:selected_repo_id]

      batch = []

      @subqueue.each do |obj|
        batch << obj.to_hash(true)
      end
      batch_object.set_data({:batch => batch})

      uri = "/repositories/#{repo_id}/batch_imports"
      url = URI("#{JSONModel::HTTP.backend_url}#{uri}")

      response = JSONModel::HTTP.post_json(url, batch_object.to_json)

      response
    end
  end
end



