# Drop all environment variables so they don't interfere with our war file gem loading.
java.lang.System.set_property("aspace.launcher.base", ENV['ASPACE_LAUNCHER_BASE'])

require 'aspace_gems'
ASpaceGems.setup

require_relative 'launcher_init'
require 'asutils'
require 'fileutils'
require 'securerandom'
require 'uri'


$server_prepare_hooks = []


# Add a new hook that will be called as a Jetty server is prepared.
# Each hook will be called with:
#
#   hook.call(server, port, [{:war => '/path/to/app.war', :path => '/uri'}, ...])
#
# Nothing uses this feature by default, but you could use it for performing
# further configuration on the Jetty server object (such as sizing thread pools)
# by adding a hook from code in your ASPACE_LAUNCHER_BASE/launcher_rc.rb file.
                                                                      #
def add_server_prepare_hook(callback)
  $server_prepare_hooks << callback
end


def start_server(port, *webapps)
  server = org.eclipse.jetty.server.Server.new
  server.send_date_header = true

  connector = org.eclipse.jetty.server.nio.SelectChannelConnector.new
  connector.port = port

  contexts = webapps.map do |webapp|
    if webapp[:war]
      context = org.eclipse.jetty.webapp.WebAppContext.new
      context.server = server
      context.context_path = webapp[:path]
      context.war = webapp[:war]
      context.class_loader = org.eclipse.jetty.webapp.WebAppClassLoader.new(JRuby.runtime.jruby_class_loader, context)

      context
    elsif webapp[:static_dirs]
      handlers = org.eclipse.jetty.server.handler.HandlerList.new

      Array(webapp[:static_dirs]).each do |static_dir|
        handler = org.eclipse.jetty.server.handler.ResourceHandler.new
        handler.set_resource_base(static_dir)

        handlers.add_handler(handler)
      end

      ctx = org.eclipse.jetty.server.handler.ContextHandler.new(webapp[:path])
      ctx.set_handler(handlers)

      ctx
    else
      raise "Unrecognised webapp definition: #{webapp.inspect}"
    end
  end

  server.add_connector(connector)
  collection = org.eclipse.jetty.server.handler.ContextHandlerCollection.new
  collection.handlers = contexts
  server.handler = collection

  $server_prepare_hooks.each do |hook|
    hook.call(server, port, webapps)
  end

  server.start
end


def generate_secret_for(secret)
  file = File.join(AppConfig[:data_directory], "#{secret}_cookie_secret.dat")

  if !File.exists?(file)
    File.write(file, SecureRandom.hex)

    puts "****"
    puts "**** INFO: Generated a secret key for AppConfig[:#{secret}]"
    puts "****       and stored it in #{file}."
    puts "****"
    puts "**** If you're running ArchivesSpace in a clustered setup, you will"
    puts "**** need to make sure that all instances share the same value for this"
    puts "**** setting.  You can do that by setting a value for AppConfig[:#{secret}]"
    puts "**** in your config.rb file."
    puts "****"
    puts ""
  end

  File.read(file)
end


def main
  java.lang.System.set_property("org.eclipse.jetty.webapp.LEVEL", "WARN")
  java.lang.System.set_property("org.eclipse.jetty.server.handler.LEVEL", "WARN")


  String tempdir = File.join(AppConfig[:data_directory], "tmp")

  FileUtils.mkdir_p(tempdir)

  java.lang.System.set_property("java.io.tmpdir", tempdir)
  java.lang.System.set_property("solr.data.dir", AppConfig[:solr_index_directory])
  java.lang.System.set_property("solr.solr.home", AppConfig[:solr_home_directory])

  [:search_user_secret, :public_user_secret, :staff_user_secret].each do |property|
    if !AppConfig.has_key?(property)
      java.lang.System.set_property("aspace.config.#{property}", SecureRandom.hex)
    end
  end

  cookie_secrets = [:frontend_cookie_secret, :public_cookie_secret].each do |secret|
    if !AppConfig.has_key?("#{secret}_cookie_secret".intern)
      java.lang.System.set_property("aspace.config.#{secret}",
                                    generate_secret_for(secret))
    end
  end

  begin
	  aspace_base = java.lang.System.get_property("ASPACE_LAUNCHER_BASE")
    start_server(URI(AppConfig[:backend_url]).port, {:war => File.join(aspace_base, 'wars', 'backend.war'), :path => '/'}) if AppConfig[:enable_backend]
    start_server(URI(AppConfig[:solr_url]).port,
                 {:war => File.join(aspace_base,'wars', 'solr.war'), :path => '/'},
                 {:war => File.join(aspace_base,'wars', 'indexer.war'), :path => '/aspace-indexer'}) if AppConfig[:enable_indexer]
    start_server(URI(AppConfig[:frontend_url]).port,
                 {:war => File.join(aspace_base,'wars', 'frontend.war'), :path => '/'},
                 {:static_dirs => ASUtils.find_local_directories("frontend/assets"),
                       :path => "#{AppConfig[:frontend_prefix]}assets"}) if AppConfig[:enable_frontend]
    start_server(URI(AppConfig[:public_url]).port,
                 {:war => File.join(aspace_base,'wars', 'public.war'), :path => '/'},
                 {:static_dirs => ASUtils.find_local_directories("public/assets"),
                        :path => "#{AppConfig[:public_prefix]}assets"}) if AppConfig[:enable_public]
  rescue
    # If anything fails on startup, dump a diagnostic file.
    ASUtils.dump_diagnostics($!)
  end

  puts <<EOF
************************************************************
  Welcome to ArchivesSpace!
  You can now point your browser to #{AppConfig[:frontend_url]}
************************************************************
EOF

end


launcher_rc = File.join(java.lang.System.get_property("ASPACE_LAUNCHER_BASE"), "launcher_rc.rb")

if java.lang.System.get_property("ASPACE_LAUNCHER_BASE") && File.exists?(launcher_rc)
  load File.absolute_path(launcher_rc)
end

main
