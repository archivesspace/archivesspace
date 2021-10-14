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
    begin
      find_version
    rescue Exception => ex
      $stderr.puts("Unable to determine ArchivesSpace version: #{ex.message}")
      'NO VERSION'
    end
  end

  private

  def self.find_version
    # give priority to env, if this is set there's a reason for it
    return ENV['ARCHIVESSPACE_VERSION'] if ENV['ARCHIVESSPACE_VERSION']

    # should be safe to assume that if we're a devserver we have git and would prefer the branch ...
    return `git symbolic-ref --short HEAD`.chomp if java.lang.System.get_property('aspace.devserver')

    version = java.lang.ClassLoader.getSystemClassLoader.getResourceAsStream("ARCHIVESSPACE_VERSION")
    return version.to_io.read.strip if version

    version = File.join(*[ ASUtils.find_base_directory, 'ARCHIVESSPACE_VERSION'])
    return File.read(version).chomp if File.file? version

    # well, we tried our best
    raise 'ARCHIVESSPACE_VERSION not found'
  end

end
