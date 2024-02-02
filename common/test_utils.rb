require 'rbconfig'
require 'socket'
require 'ashttp'
require 'asutils'
require 'English'
require File.expand_path('indexer/app/lib/periodic_indexer', ASUtils.find_base_directory)
require File.expand_path('indexer/app/lib/pui_indexer', ASUtils.find_base_directory)


# A set of utils to start/stop the various servers that make up Aspace.
# Used for running tests.
# rubocop:disable Lint/HandleExceptions, Lint/RescueWithoutErrorClass
module TestUtils
  def self.kill(pid)
    if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
      system("taskkill /pid #{pid} /f /t")
    else
      begin
        Process.kill(15, pid)
        Process.waitpid(pid)
      rescue
        # Already dead.
      end
    end
  end

  # rubocop:disable Metrics/MethodLength
  def self.wait_for_url(url, out = nil)
    24.times do |idx|
      begin
        uri = URI(url)
        req = Net::HTTP::Get.new(uri.request_uri)
        ASHTTP.start_uri(uri, open_timeout: 60, read_timeout: 60) do |http|
          http.request(req)
        end
        break
      rescue
        # Keep trying
        raise "Giving up waiting for #{url}" if idx > 22
        puts "Waiting for #{url} (#{$ERROR_INFO.inspect})"
        if idx == 10 && !out.nil? && File.file?(out)
          puts "Server is taking a long time to startup, dumping last 50 lines of log:"
          puts IO.readlines(out)[-50..-1]
        end
        sleep(5)
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def self.build_config_string(config)
    java_opts = ENV.fetch('JAVA_OPTS', '')
    config.each do |key, value|
      java_opts += " -Daspace.config.#{key}=#{value}"
    end

    # Pass through any system properties from the parent JVM too
    java.lang.System.getProperties.each do |property, value|
      next unless property =~ /aspace.config.(.*)/
      key = Regexp.last_match(1)
      java_opts += " -Daspace.config.#{key}=#{value}" unless config.key?(key)
    end

    ' ' + java_opts
  end

  def self.find_ant
    fullpath = ''
    [nil, '..', '../..'].each do |root|
      base = ASUtils.find_base_directory(root)
      fullpath = File.join(File.realpath(base), 'build', 'run')
      break if File.exist? fullpath
    end
    fullpath
  end

  def self.start_backend(port, config = {}, config_file = nil)
    db_url = config.delete(:db_url)
    java_opts = build_config_string(config)
    java_opts += " -Daspace.config=#{config_file}" if config_file

    # although we are testing, we need to pass the db we are using
    # through as aspace.db_url.dev because the backend:devserver
    # ant task is hardcoded to used that build arg
    build_args = ['backend:devserver:integration',
                  "-Daspace.backend.port=#{port}",
                  '-Daspace_integration_test=1',
                  "-Daspace.db_url.dev=#{db_url}"]
    java_opts += ' -Xmx1024m'

    puts "Spawning backend with opts: #{java_opts}"
    logfile = File.join(ASUtils.find_base_directory, "ci_logs", "backend_test_log.out")
    process_log = File.join(ASUtils.find_base_directory, "ci_logs", "backend_process.out")
    process_options = { :out => process_log, :err => process_log }
    env = { 'JAVA_OPTS' => java_opts, 'APPCONFIG_BACKEND_LOG' => logfile, 'INTEGRATION_LOGFILE' => process_log }
    pid = Process.spawn(env, find_ant, *build_args, process_options)

    TestUtils.wait_for_url("http://localhost:#{port}", logfile)
    puts "Backend started with pid: #{pid}"

    pid
  end

  def self.start_frontend(port, backend_url, config = {}, config_file = nil)
    java_opts = "-Daspace.config.backend_url=#{backend_url}"
    java_opts += build_config_string(config)
    java_opts += " -Daspace.config=#{config_file}" if config_file

    build_args = ['frontend:devserver:integration',
                  "-Daspace.frontend.port=#{port}"]
    java_opts += ' -Xmx1512m'

    puts "Spawning frontend with opts: #{java_opts}"
    pid = Process.spawn({ 'JAVA_OPTS' => java_opts, 'TEST_MODE' => 'true' },
                        find_ant, *build_args)

    TestUtils.wait_for_url("http://localhost:#{port}")
    puts "Frontend started with pid: #{pid}"

    pid
  end

  def self.start_public(port, backend_url, config = {})
    java_opts = "-Daspace.config.backend_url=#{backend_url}"
    config.each do |key, value|
      java_opts += " -Daspace.config.#{key}=#{value}"
    end

    pid = Process.spawn({ 'JAVA_OPTS' => java_opts, 'TEST_MODE' => 'true' },
                        find_ant, 'public:devserver:integration',
                        "-Daspace.public.port=#{port}")

    TestUtils.wait_for_url("http://localhost:#{port}")
    puts "Public started with pid: #{pid}"

    pid
  end

  def self.free_port_from(port)
    server = TCPServer.new('127.0.0.1', port)
    server.close
    port
  rescue Errno::EADDRINUSE
    port += 1
    retry
  end

  # the first time a factory is created, backend session will be set;
  # rather than have the indexer login, use the same session
  module SpecIndexing
    def self.get_indexer
      @periodic ||= PeriodicIndexer.new(AppConfig[:backend_url]).instance_eval do
        def login
          @current_session = JSONModel::HTTP.current_backend_session
          @current_session
        end

        self
      end
    end

    def self.get_pui_indexer
      @pui ||= PUIIndexer.new(AppConfig[:backend_url]).instance_eval do
        def login
          @current_session = JSONModel::HTTP.current_backend_session
          @current_session
        end

        self
      end
    end

    module Methods
      def run_indexer
        SpecIndexing.get_indexer.run_index_round
      end

      def run_indexers
        SpecIndexing.get_indexer.run_index_round
        SpecIndexing.get_pui_indexer.run_index_round
      end
    end
  end
end
