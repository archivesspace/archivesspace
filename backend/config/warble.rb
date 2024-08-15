# https://github.com/jruby/warbler/issues/508
class Warbler::Traits::War::WebxmlOpenStruct
  def new_ostruct_member(name)
    return if name.nil?

    unless @table.key?(name) || is_method_protected!(name)
      getter_proc = Proc.new { @table[name] }
      setter_proc = Proc.new {|x| @table[name] = x}
      if defined?(::Ractor)
        ::Ractor.make_shareable(getter_proc)
        ::Ractor.make_shareable(setter_proc)
      end
      define_singleton_method!(name, &getter_proc)
      define_singleton_method!("#{name}=", &setter_proc)
    end
  end
end


# Disable Rake-environment-task framework detection by uncommenting/setting to false
# Warbler.framework_detection = false

# Warbler web application assembly configuration file
Warbler::Config.new do |config|
  # Features: additional options controlling how the jar is built.
  # Currently the following features are supported:
  # - gemjar: package the gem repository in a jar file in WEB-INF/lib
  # - executable: embed a web server and make the war executable
  # - compiled: compile .rb files to .class files
  config.features = []

  # Application directories to be included in the webapp.
  # We need .bundle (and Gemfile.lock) because Bundler.require uses .bundle to determine
  # gem groups
  config.dirs = %w(app .bundle)

  # Additional files/directories to include, above those in config.dirs
  config.includes = FileList["Gemfile", "Gemfile.lock"]

  # Additional files/directories to exclude
  # config.excludes = FileList["lib/tasks/*"]
  config.excludes = FileList["app/exporters/examples/**/*", ".bundle/install.log"]

  # Additional Java .jar files to include.  Note that if .jar files are placed
  # in lib (and not otherwise excluded) then they need not be mentioned here.
  # JRuby and JRuby-Rack are pre-loaded in this list.  Be sure to include your
  # own versions if you directly set the value
  # config.java_libs += FileList["lib/java/*.jar"]

  config.java_libs.reject! {|jar| jar =~ /jruby-(complete|core|stdlib|rack)/}

  # Loose Java classes and miscellaneous files to be included.
  # config.java_classes = FileList["target/classes/**.*"]

  # One or more pathmaps defining how the java classes should be copied into
  # the archive. The example pathmap below accompanies the java_classes
  # configuration above. See http://rake.rubyforge.org/classes/String.html#M000017
  # for details of how to specify a pathmap.
  # config.pathmaps.java_classes << "%{target/classes/,}p"

  # Bundler support is built-in. If Warbler finds a Gemfile in the
  # project directory, it will be used to collect the gems to bundle
  # in your application. If you wish to explicitly disable this
  # functionality, uncomment here.
  config.bundler = false

  # An array of Bundler groups to avoid including in the war file.
  # Defaults to ["development", "test"].
  # config.bundle_without = []

  # Other gems to be included. If you don't use Bundler or a gemspec
  # file, you need to tell Warbler which gems your application needs
  # so that they can be packaged in the archive.
  # For Rails applications, the Rails gems are included by default
  # unless the vendor/rails directory is present.
  # config.gems += ["activerecord-jdbcmysql-adapter", "jruby-openssl"]
  # config.gems << "tzinfo"

  # Uncomment this if you don't want to package rails gem.
  # config.gems -= ["rails"]

  # The most recent versions of gems are used.
  # You can specify versions of gems by using a hash assignment:
  # config.gems["rails"] = "2.3.10"

  # You can also use regexps or Gem::Dependency objects for flexibility or
  # finer-grained control.
  # config.gems << /^merb-/
  # config.gems << Gem::Dependency.new("merb-core", "= 0.9.3")

  # Include gem dependencies not mentioned specifically. Default is
  # true, uncomment to turn off.
  config.gem_dependencies = false

  # Don't bundle the JRuby jars twice--Warbler will make sure we get it.
  #config.gem_excludes = [/jruby-(core|stdlib).*jar/]

  # Pathmaps for controlling how application files are copied into the archive
  # config.pathmaps.application = ["WEB-INF/%p"]

  # Name of the archive (without the extension). Defaults to the basename
  # of the project directory.
  # config.jar_name = "mywar"

  # Name of the MANIFEST.MF template for the war file. Defaults to a simple
  # MANIFEST.MF that contains the version of Warbler used to create the war file.
  # config.manifest_file = "config/MANIFEST.MF"

  # When using the 'compiled' feature and specified, only these Ruby
  # files will be compiled. Default is to compile all \.rb files in
  # the application.
  # config.compiled_ruby_files = FileList['app/**/*.rb']

  # === War files only below here ===

  # Path to the pre-bundled gem directory inside the war file. Default
  # is 'WEB-INF/gems'. Specify path if gems are already bundled
  # before running Warbler. This also sets 'gem.path' inside web.xml.
  # config.gem_path = "WEB-INF/vendor/bundler_gems"

  # Files for WEB-INF directory (next to web.xml). This contains
  # web.xml by default. If there is an .erb-File it will be processed
  # with webxml-config. You may want to exclude this file via
  # config.excludes.
  # config.webinf_files += FileList["jboss-web.xml"]

  # Files to be included in the root of the webapp.  Note that files in public
  # will have the leading 'public/' part of the path stripped during staging.
  # config.public_html = FileList["public/**/*", "doc/**/*"]

  # Pathmaps for controlling how public HTML files are copied into the .war
  # config.pathmaps.public_html = ["%{public/,}p"]

  # Value of RAILS_ENV for the webapp -- default as shown below
  # config.webxml.rails.env = ENV['RAILS_ENV'] || 'production'

  # Application booter to use, one of :rack, :rails, or :merb (autodetected by default)
  config.webxml.booter = :rack

  # Set JRuby to run in 1.9 mode.
  # config.webxml.jruby.compat.version = "1.9"

  # When using the :rack booter, "Rackup" script to use.
  # - For 'rackup.path', the value points to the location of the rackup
  # script in the web archive file. You need to make sure this file
  # gets included in the war, possibly by adding it to config.includes
  # or config.webinf_files above.
  # - For 'rackup', the rackup script you provide as an inline string
  #   is simply embedded in web.xml.
  # The script is evaluated in a Rack::Builder to load the application.
  # Examples:
  # config.webxml.rackup.path = 'WEB-INF/hello.ru'
  # config.webxml.rackup = %{require './lib/demo'; run Rack::Adapter::Camping.new(Demo)}
  # config.webxml.rackup = require 'cgi' && CGI::escapeHTML(File.read("config.ru"))

  # See ./web.xml for jetty configuration

  config.override_gem_home = true
end
