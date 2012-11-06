module ASpaceImport
  class ParseQueue < Array
    
    def pop
      if self.length > 0
        self.last.queue_save       
        super
      end
      
      if self.length == 0
        JSONModel::Queueable.save_all
      end
    end
  
    def initialize(opts)
      @repo_id = opts[:repo_id] if opts[:repo_id]
      @opts = opts
    end
  end
end