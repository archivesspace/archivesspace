module ASpaceImport
  class ParseQueue < Array
    
    @repo_id = '1'


    def pop
      if self.length > 0
        self.last.save_or_wait(@opts)        
        super
      end
    end
  
    def initialize(opts)
      @repo_id = opts[:repo_id] if opts[:repo_id]
      @opts = opts
    end
  end
end