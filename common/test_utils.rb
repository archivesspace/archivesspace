require 'rbconfig'
require 'socket'
require 'ashttp'
require 'asutils'
require 'English'

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
    100.times do |idx|
      begin
        uri = URI(url)
        req = Net::HTTP::Get.new(uri.request_uri)
        ASHTTP.start_uri(uri, open_timeout: 60, read_timeout: 60) do |http|
          http.request(req)
        end
        break
      rescue
        # Keep trying
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

  def self.java_build_args(build_args)
    build_args << "-Dgem_home=#{ENV['GEM_HOME']}" if ENV['GEM_HOME']
    build_args
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

  def self.add_solr(java_opts, build_args, config)
    if config[:solr_port]
      java_opts +=
        " -Daspace.config.solr_url=http://localhost:#{config[:solr_port]}"
      build_args.push("-Daspace.solr.port=#{config[:solr_port]}")
    end
    [java_opts, build_args]
  end

  def self.start_backend(port, config = {}, config_file = nil)
    db_url = config.delete(:db_url)
    java_opts = build_config_string(config)
    java_opts += " -Daspace.config=#{config_file}" if config_file

    build_args = java_build_args(['backend:devserver:integration',
                                  "-Daspace.backend.port=#{port}",
                                  '-Daspace_integration_test=1',
                                  "-Daspace.config.db_url=#{db_url}"])

    java_opts, build_args = add_solr(java_opts, build_args, config)
    java_opts += ' -Xmx1024m'

    puts "Spawning backend with opts: #{java_opts}"
    pid = Process.spawn({ 'JAVA_OPTS' => java_opts }, find_ant, *build_args)
    out = File.join(find_ant.gsub(/run/, ''), 'backend_test_log.out')

    TestUtils.wait_for_url("http://localhost:#{port}", out)
    puts "Backend started with pid: #{pid}"

    pid
  end

  def self.start_frontend(port, backend_url, config = {})
    java_opts = "-Daspace.config.backend_url=#{backend_url}"
    java_opts += build_config_string(config)

    build_args = java_build_args(['frontend:devserver:integration',
                                  "-Daspace.frontend.port=#{port}"])

    java_opts += ' -Xmx1512m'

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
end
