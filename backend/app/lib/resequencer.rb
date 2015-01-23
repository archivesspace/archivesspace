#
# This will resquence tree_nodes, which can cause problems if the object loses it Sequence
# ( this can happen in transfers and whatnot ) 

require 'atomic'

class Resequencer
  
  @running = Atomic.new(false)
  @@klasses = [ :ArchivalObject, :DigitalObjectComponent, :ClassificationTerm]


  class << self

    def running?
      @running
    end

    def resequence(klass)
      repos = Repository.dataset.select(:id).map {|rec| rec[:id]} 
      repos.each do |r|
        DB.attempt {
          Kernel.const_get(klass).resequence(r)
        }.and_if_constraint_fails {
          return 
          # if there's a failure, just keep going.  
        } 
      end
    end

    def resequence_all
      @@klasses.each do |klass|
        self.resequence(klass)
      end
    end


    def run(klasses = @@klasses )
      $stderr.puts "*" * 100
      $stderr.puts "*\t\t STARTING RESEQUENCER  \t\t*"
      $stderr.puts "*\t\t This is a utility that will organize and compact objects trees to ensure their validity. \t\t *" 
      $stderr.puts "*\t\t Duration of this process depends on the size of your data. \t\t *" 
      $stderr.puts "*\t\t It should NOT be used on every startup and instead should only be run in rare occassions that require data maintance. \t\t *" 
      $stderr.puts "*" * 100
      begin
        @running.update { |r| r = true }  
        klasses = klasses & @@klasses 
        $stderr.puts klasses 
        klasses.each do |klass|
          $stderr.puts klass
          self.resequence(klass) 
        end 
      ensure
        @running.update { |r| r =  false } 
      end
      $stderr.puts "*" * 100
      $stderr.puts "*\t\t RESEQUENCER COMPLETE  \t\t*"
      $stderr.puts "*\t\t Be sure to set the AppConfig[:resequence_on_startup] to false to ensure quicker startups in the future. \t\t*"
      $stderr.puts "*" * 100
    
    end

  end
end
