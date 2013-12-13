# Boiler plate for loading the right files for a given tenant on a given server

$hostname = `hostname`.strip
load File.join(File.dirname(__FILE__), "config.rb")

host_config = File.join($basedir, "instance_#{$hostname}.rb")
if File.exists?(host_config)
  config = eval(File.read(host_config))
  config.each do |setting, value|
    AppConfig[setting] = value
  end
else
  raise "*** ERROR: Host configuration could not be found for hostname: #{$hostname}"
end

# Find the URL of each backend instance to make them available to the indexer.

AppConfig[:backend_instance_urls] = proc {
  Dir.glob(File.join($basedir, "instance_*.rb")).map do |f|
    config = eval(File.read(f))
    config[:backend_url]
  end
}
