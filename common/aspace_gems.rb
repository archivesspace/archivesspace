require 'asutils'

class ASpaceGems

  def self.setup
    ENV['TMPDIR'] = java.lang.System.get_property("java.io.tmpdir")
    ENV['TEMPDIR'] = java.lang.System.get_property("java.io.tmpdir")

    if java.lang.System.get_property("aspace.launcher.base")
      # The environment will have been cleared by launcher.rb, so set
      # ASPACE_LAUNCHER_BASE so everything else can find it.
      ENV['ASPACE_LAUNCHER_BASE'] = java.lang.System.get_property("aspace.launcher.base")

      # When running from the launcher, use its gems.
      ENV['GEM_HOME'] = File.join(java.lang.System.get_property("aspace.launcher.base"), "gems")
    elsif java.lang.System.get_property("catalina.base")
      ENV['GEM_HOME'] = File.join(java.lang.System.get_property("catalina.base"), "lib", "gems")
    else
      # If we're not running in either environment, leave everything alone
      require "rubygems"
      return
    end

    ENV['GEM_PATH'] = nil
    require "rubygems"

    gem_paths = [File.expand_path(ENV['GEM_HOME'])]

    # Add plugin gem paths too
    ASUtils.find_local_directories.each do |plugin|
      gemdir = File.join(plugin, "gems")

      if gemdir && Dir.exist?(gemdir)
        gem_paths << gemdir
      end
    end

    Gem.use_paths(nil, gem_paths)
  end

end
