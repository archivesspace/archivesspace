require 'java'
require 'rubygems'
require 'config/config-distribution'
require 'fileutils'
require 'securerandom'
require 'uri'


def start_server(war, path, port)
  server = org.eclipse.jetty.server.Server.new
  server.send_date_header = true

  connector = org.eclipse.jetty.server.nio.SelectChannelConnector.new
  connector.port = port

  context = org.eclipse.jetty.webapp.WebAppContext.new
  context.server = server
  context.context_path = path
  context.war = war
  context.class_loader = org.eclipse.jetty.webapp.WebAppClassLoader.new(JRuby.runtime.jruby_class_loader, context)

  server.add_connector(connector)
  collection = org.eclipse.jetty.server.handler.ContextHandlerCollection.new
  collection.handlers = [context]
  server.handler = collection
  server.start
end


def main
  java.lang.System.set_property("ASPACE_LAUNCHER_BASE",
                                File.realpath(File.join(File.dirname(__FILE__), "..")))

  AppConfig.reload


  java.lang.System.set_property("org.eclipse.jetty.webapp.LEVEL", "WARN")
  java.lang.System.set_property("org.eclipse.jetty.server.handler.LEVEL", "WARN")


  String tempdir = File.join(AppConfig[:data_directory], "tmp")

  FileUtils.mkdir_p(tempdir)

  java.lang.System.set_property("java.io.tmpdir", tempdir)
  java.lang.System.set_property("solr.data.dir", AppConfig[:solr_index_directory])
  java.lang.System.set_property("solr.solr.home", AppConfig[:solr_home_directory])

  [:search_user_secret, :public_user_secret].each do |secret|
    if !AppConfig.has_key?(secret)
      java.lang.System.set_property("aspace.config.#{secret}", SecureRandom.hex)
    end
  end

  start_server(File.join('wars', 'backend.war'), '/', URI(AppConfig[:backend_url]).port)
  start_server(File.join('wars', 'frontend.war'), '/', URI(AppConfig[:frontend_url]).port)
  start_server(File.join('wars', 'public.war'), '/', URI(AppConfig[:public_url]).port)
  start_server(File.join('wars', 'solr.war'), '/', URI(AppConfig[:solr_url]).port)
  start_server(File.join('wars', 'indexer.war'), '/', URI(AppConfig[:indexer_url]).port)

  puts <<EOF
************************************************************
  Welcome to ArchivesSpace!
  You can now point your browser to #{AppConfig[:frontend_url]}
************************************************************
EOF

end


main
