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


  module Solr

    # bundle exec rake http:checksum:solr["http://localhost:8983/solr/archivesspace","schema"]
    def self.SCHEMA
      '9f607fc5968c26fd69d247b1b314db3285eeb7a4430d45b62281482b9ba64fd6'
    end

    # bundle exec rake http:checksum:solr["http://localhost:8983/solr/archivesspace","config"]
    def self.SOLRCONFIG
      'a30987c15d987c5f56d4048e6d447a76792e7fd944cf305fc78591d891da293e'
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
        fallback_version = "v2.8.1-rc1.a"
        @VERSION = fallback_version
      end
    rescue
      @VERSION = "NO VERSION"
    end
  end

end
