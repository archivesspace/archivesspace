#
# will be adding this file to .gitignore
# the version and schema_info values should be updated with the ant dist
# task
#
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
      version = java.lang.ClassLoader.getSystemClassLoader.getResourceAsStream("ARCHIVESSPACE_VERSION")
      if version
        @VERSION = version.to_io.read.strip
      else # some servlet containers have a hard time finding the resource...
        # fallback_version variable gets changed in dist ant task . The a is
        # just a cue that we're using this..
        fallback_version = "hm_11"
        @VERSION = fallback_version
      end
    rescue
      @VERSION = "NO VERSION"
    end
  end

end
