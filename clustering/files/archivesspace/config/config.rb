# Configuration that should be applied to *all* tenants can go here.
# Need to set the data_directory config parameter to the correct location
# Default is data
AppConfig[:data_directory] = File.expand_path(File.dirname(FILE), 'data')
