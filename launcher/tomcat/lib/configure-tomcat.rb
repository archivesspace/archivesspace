require_relative '../../launcher_init'
require 'java'

require 'fileutils'
require 'uri'
require 'securerandom'
require 'nokogiri'

class TomcatSetup

  def initialize(args)

    if args.length != 1
      puts "Usage: configure-tomcat.rb </path/to/tomcat7>"
      exit
    end

    @tomcat_dir = File.expand_path(args[0])
    @base_dir = java.lang.System.getProperty("ASPACE_LAUNCHER_BASE")

    if !Dir.exists?(@tomcat_dir) || !Dir.exists?(File.join(@tomcat_dir, "conf")) || !Dir.exists?(File.join(@tomcat_dir, "bin"))
      raise "Directory '#{@tomcat_dir}' doesn't look like a Tomcat directory."
    end
  end


  def loud_cp(source, target)
    puts "Copying '#{source}' to '#{target}'"
    FileUtils.cp(source, target)
  end


  def loud_cp_r(source, target)
    puts "Copying '#{source}' to '#{target}'"
    FileUtils.cp_r(source, target)
  end



  def copy_wars
    [{:service => 'backend', :root_war => 'backend'},
     {:service => 'frontend', :root_war => 'frontend'},
     {:service => 'public', :root_war => 'public'},
     {:service => 'solr', :root_war => 'solr'},
     {:service => 'indexer', :root_war => 'indexer'}].each do |service|
      next if service[:service] == "solr" and not AppConfig[:enable_solr]

      webapps = File.join(@tomcat_dir, "webapps-#{service[:service]}")
      FileUtils.mkdir_p(webapps)

      (Array(service[:extra_wars]) + [service[:root_war]]).each do |war|
        source = File.join(@base_dir, 'wars', "#{war}.war")

        if war == service[:root_war]
          target = File.join(webapps, 'ROOT.war')
        else
          target = webapps
        end

        loud_cp(source, target)
      end
    end
  end

  def service_xml(service_name, port)
<<EOF
   <Service name="ArchivesSpace#{service_name}">
    <Connector port="#{port}" protocol="HTTP/1.1" connectionTimeout="20000" />
    <Engine name="ArchivesSpace#{service_name}" defaultHost="localhost">
       <Host name="localhost" appBase="webapps-#{service_name.downcase}" unpackWARs="true" autoDeploy="false">
       <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
       prefix="#{service_name.downcase}_access_log." suffix=".txt"
       pattern="%h %l %u %t &quot;%r&quot; %s %b" />
       </Host>
    </Engine>
   </Service>
EOF
  end


  def copy_libs
    jars = Dir.glob(File.join(@base_dir, "gems", "gems", "jruby-jars*", "lib", "*.jar"))
    jars += Dir.glob(File.join(@base_dir, "lib", "*.jar"))
    jars += Dir.glob(File.join(@base_dir, "gems", "gems", "jruby-rack*", "lib", "*.jar"))

    jars.each do |jar|
      loud_cp(jar, File.join(@tomcat_dir, "lib"))
    end

    loud_cp_r(File.join(@base_dir, "gems"), File.join(@tomcat_dir, "lib"))
  end


  def copy_plugins
    loud_cp_r(File.join(@base_dir, "plugins"), @tomcat_dir)
  end
  
  def copy_stylesheets
    loud_cp_r(File.join(@base_dir, "stylesheets"), @tomcat_dir)
  end


  def port_for(service)
    URI(AppConfig["#{service}_url".intern]).port
  end


  def copy_locales
    loud_cp_r(File.join(@base_dir, "locales"), @tomcat_dir)
  end


  def copy_reports
    loud_cp_r(File.join(@base_dir, "reports"), @tomcat_dir)
  end
  
  def backup_config
    server_file = File.join(@tomcat_dir, "conf", "server.xml")
    backup_file = "#{server_file}.#{Time.now.to_i}" 
    $stderr.puts "~~~  Backing up Tomcat server.xml to #{backup_file}  ~~~" 
    FileUtils.cp(server_file, backup_file) 
  end

  def copy_config
    Dir.glob(File.join(@base_dir, "launcher", "tomcat", "files", "setenv*")).each do |setenv|
      loud_cp(setenv, File.join(@tomcat_dir, "bin"))
    end

    server_file = File.join(@tomcat_dir, "conf", "server.xml")
    server_xml = Nokogiri::XML(open(server_file))

    ['Backend', 'Frontend', 'Public', 'Solr', 'Indexer'].each do |service|
      service_name = "ArchivesSpace#{service}"
      port = port_for(service.downcase).to_s
      
      if server_xml.search("//Service[@name = '#{service_name}']").length > 0 
        $stderr.puts "EXISTING CONFIGURATION FOR ArchivesSpace#{service_name}. NOT UPDATING"
      elsif server_xml.search("//Connector[@port = '#{port}' ]").length > 0 
        $stderr.puts "*" * 100 
        $stderr.puts "YOUR TOMCAT CONFIGURATION ALREADY HAS A CONNECTOR DEFINED AT PORT #{port}. " 
        $stderr.puts "PLEASE REVIEW YOUR TOMCAT CONFIGURATION ( #{server_file} ) AND EITHER REMOVE THE CONNECTOR OR CHANGE"  
        $stderr.puts "ASPACE PORT DEFINITIONS IN YOUR CONFIG.RB FOR #{service_name}" 
        $stderr.puts "*" * 100 
        abort("CONFIGURATION NOT SUCCESSFUL" ) 
      else
        server_xml.search("//Server").first << service_xml(service, port )
      end
    end
    
    backup_config 
    puts "Writing server.xml"
    File.write(File.join(@tomcat_dir, "conf", "server.xml"), server_xml.to_xml)


    config = <<EOF
AppConfig[:search_user_secret] = "#{SecureRandom.hex}"
AppConfig[:public_user_secret] = "#{SecureRandom.hex}"
AppConfig[:staff_user_secret] = "#{SecureRandom.hex}"

AppConfig[:frontend_cookie_secret] = "#{SecureRandom.hex}"
AppConfig[:public_cookie_secret] = "#{SecureRandom.hex}"

EOF

    if File.exists?(AppConfig.get_preferred_config_path)
      config += File.read(AppConfig.get_preferred_config_path)
    end

    config_path = File.join(@tomcat_dir, "conf", "config.rb")
    puts "Writing skeleton config file to #{config_path}"
    File.write(config_path, config)
  end


  def setup
    copy_wars
    copy_libs
    copy_plugins
    copy_stylesheets 
    copy_reports
    copy_locales
    copy_config
  end

end


TomcatSetup.new(ARGV).setup
