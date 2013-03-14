require 'java'
require 'rubygems'
require 'config/config-distribution'


def init
  java.lang.System.set_property("ASPACE_LAUNCHER_BASE",
                                File.realpath(File.join(File.dirname(__FILE__), "..")))

  AppConfig.reload

  if !AppConfig.changed?(:data_directory)
    # If the user hasn't specified a directory, write to data/
    #
    # Set this as a system property to ensure it propagates to the webapps too.
    java.lang.System.set_property("aspace.config.data_directory",
                                  File.realpath(File.join(File.dirname(__FILE__), "..", "data")))
    AppConfig.reload
  end
end


init
