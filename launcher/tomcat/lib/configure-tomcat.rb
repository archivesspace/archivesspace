require_relative '../../launcher_init'
require 'java'

require 'fileutils'
require 'uri'
require 'securerandom'


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
     {:service => 'solr', :root_war => 'solr', :extra_wars => ['indexer']}].each do |service|

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


  def copy_libs
    jars = Dir.glob(File.join(@base_dir, "gems", "gems", "jruby-jars*", "lib", "*.jar"))
    jars += Dir.glob(File.join(@base_dir, "lib", "*.jar"))
    jars += Dir.glob(File.join(@base_dir, "gems", "gems", "jruby-rack*", "lib", "*.jar"))

    jars.each do |jar|
      loud_cp(jar, File.join(@tomcat_dir, "lib"))
    end

    loud_cp_r(File.join(@base_dir, "gems"), File.join(@tomcat_dir, "lib"))
  end


  def port_for(service)
    URI(AppConfig["#{service}_url".intern]).port
  end


  def copy_config
    Dir.glob(File.join(@base_dir, "launcher", "tomcat", "files", "setenv*")).each do |setenv|
      loud_cp(setenv, File.join(@tomcat_dir, "bin"))
    end


    server_xml = File.read(File.join(@base_dir, "launcher", "tomcat", "files", "server.xml"))

    ['backend', 'frontend', 'public', 'solr'].each do |service|
      server_xml = server_xml.gsub(/%#{service.upcase}_PORT%/,
                                   port_for(service).to_s)
    end

    puts "Writing server.xml"
    File.write(File.join(@tomcat_dir, "conf", "server.xml"), server_xml)

    config = <<EOF
AppConfig[:search_user_secret] = "#{SecureRandom.hex}"
AppConfig[:public_user_secret] = "#{SecureRandom.hex}"

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
    copy_config
  end

end


TomcatSetup.new(ARGV).setup
