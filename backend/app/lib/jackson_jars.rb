# Loads Jackson JSON processor JARs

jackson_jars_dir = File.join(File.dirname(__FILE__), 'jars')

# Load in dependency order
require File.join(jackson_jars_dir, 'jackson-annotations-2.17.2.jar')
require File.join(jackson_jars_dir, 'jackson-core-2.17.2.jar')
require File.join(jackson_jars_dir, 'jackson-databind-2.17.2.jar')
