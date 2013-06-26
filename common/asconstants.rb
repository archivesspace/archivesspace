module ASConstants

  @VERSION

  module Group

    def self.GLOBAL
      '_archivesspace'
    end

  end

  def self.VERSION
    return @VERSION if @VERSION

    version_file = File.join("..", "common", "VERSION")
    @VERSION = File.exists?(version_file) ? File.open(version_file).read : "NO VERSION"
  end

end
