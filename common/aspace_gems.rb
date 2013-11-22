require "rubygems"

class ASpaceGems

  def self.setup
    if ENV['ASPACE_LAUNCHER_BASE']
      # When running from the launcher, use its gems
      ENV['GEM_HOME'] = File.join(ENV['ASPACE_LAUNCHER_BASE'], "gems")
    elsif java.lang.System.get_property("catalina.base")
      ENV['GEM_HOME'] = File.join(java.lang.System.get_property("catalina.base"), "lib", "gems")
    else
      # If we're not running in either environment, leave everything alone
      return
    end

    ENV['GEM_PATH'] = nil
    Gem.use_paths(nil, File.expand_path(ENV['GEM_HOME']))
  end

end
