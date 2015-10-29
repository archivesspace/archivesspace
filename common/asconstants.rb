#
# will be adding this file to .gitignore 
# the version and schema_info values should be updated with the ant dist
# task
#
module ASConstants

  @VERSION
  @SCHEMA_INFO

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
        fallback_version = "v1.4.3-dev17.a"
        @VERSION = fallback_version 
      end
    rescue
      @VERSION = "NO VERSION"
    end
  end

  # Schema Info is a number set by the migration process. We need to store what
  # this value is supposed to be and check it against the value that's stored
  # in the db post-migration. Backend will not start if this value is off. 
  #
  def self.SCHEMA_INFO
    return @SCHEMA_INFO if @SCHEMA_INFO
    # this gets changed by dist ant task 
    @SCHEMA_INFO = 62
  end

end
