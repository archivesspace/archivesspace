require 'rbconfig'
require 'socket'
require 'net/http'

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


  def self.get(url)
    Net::HTTP.get_response(url)
  end


  def self.wait_for_url(url)
    100.times do
      begin
        uri = URI(url)
        req = Net::HTTP::Get.new(uri.request_uri)
        Net::HTTP.start(uri.host, uri.port, nil, nil, nil,
                        :open_timeout => 3,
                        :read_timeout => 3) do |http|
          http.request(req)
        end

        break
      rescue
        # Keep trying
        puts "Waiting for #{url} (#{$!.inspect})"
        sleep(5)
      end
    end
  end


  def self.build_config_string(config)
    java_opts = ""
    config.each do |key, value|
      java_opts += " -Daspace.config.#{key}=#{value}"
    end

    # Pass through any system properties from the parent JVM too
    java.lang.System.getProperties.each do |property, value|
      if property =~ /aspace.config.(.*)/
        key = $1
        if !config.has_key?(key)
          java_opts += " -Daspace.config.#{key}=#{value}"
        end
      end
    end

    java_opts
  end


  def self.start_backend(port, config = {}, config_file = nil)
    base = File.dirname(__FILE__)

    java_opts = "-Xmx256M -XX:MaxPermSize=128M"
    java_opts += build_config_string(config)
    if config_file
      java_opts += " -Daspace.config=#{config_file}"
    end

    build_args = ["backend:devserver:integration",
            "-Daspace.backend.port=#{port}",
            "-Daspace_integration_test=1"]

    if config[:solr_port]
      build_args.push("-Daspace.solr.port=#{config[:solr_port]}")
      java_opts += " -Daspace.config.solr_url=http://localhost:#{config[:solr_port]}"
    end

    pid = Process.spawn({:JAVA_OPTS => java_opts},
                        "#{base}/../build/run", *build_args)

    TestUtils.wait_for_url("http://localhost:#{port}")

    pid
  end


  def self.start_frontend(port, backend_url, config = {})
    base = File.dirname(__FILE__)

    java_opts = "-Xmx256M -XX:MaxPermSize=128M -Daspace.config.backend_url=#{backend_url}"
    java_opts += build_config_string(config)

    pid = Process.spawn({:JAVA_OPTS => java_opts, :TEST_MODE => "true"},
                        "#{base}/../build/run", "frontend:devserver:integration",
                        "-Daspace.frontend.port=#{port}")

    TestUtils.wait_for_url("http://localhost:#{port}")

    pid
  end


  def self.start_public(port, backend_url, config = {})
    base = File.dirname(__FILE__)

    java_opts = "-Xmx256M -XX:MaxPermSize=128M -Daspace.config.backend_url=#{backend_url}"
    config.each do |key, value|
      java_opts += " -Daspace.config.#{key}=#{value}"
    end

    pid = Process.spawn({:JAVA_OPTS => java_opts, :TEST_MODE => "true"},
                        "#{base}/../build/run", "public:devserver:integration",
                        "-Daspace.public.port=#{port}")

    TestUtils.wait_for_url("http://localhost:#{port}")

    pid
  end


  def self.free_port_from(port)
    begin
      server = TCPServer.new('127.0.0.1', port)
      server.close

      port
    rescue Errno::EADDRINUSE
      port += 1
      retry
    end
  end

end
