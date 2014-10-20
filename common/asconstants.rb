module ASConstants

  @VERSION

  module Repository

    def self.GLOBAL
      '_archivesspace'
    end

  end


  def self.VERSION
    return @VERSION if @VERSION

    begin
      @VERSION = Thread.currentThread.getSystemClassLoader.getResourceAsStream("ARCHIVESSPACE_VERSION").to_io.read.strip
      
    rescue
      @VERSION = "NO VERSION"
    end
  end

end
