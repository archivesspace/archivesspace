require 'rbconfig'
require 'socket'

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
    while true
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


  def self.start_backend(port, config = {})
    base = File.dirname(__FILE__)

    java_opts = "-Xmx64M -XX:MaxPermSize=64M"
    config.each do |key, value|
      java_opts += " -Daspace.config.#{key}=#{value}"
    end

    pid = Process.spawn({:JAVA_OPTS => java_opts},
                        "#{base}/../build/run", "backend:devserver:integration",
                        "-Daspace.backend.port=#{port}",
                        "-Daspace_integration_test=1")

    TestUtils.wait_for_url("http://localhost:#{port}")

    pid
  end


  def self.start_frontend(port, backend_url, config = {})
    base = File.dirname(__FILE__)

    java_opts = "-Xmx128M -XX:MaxPermSize=96M -Daspace.config.backend_url=#{backend_url}"
    config.each do |key, value|
      java_opts += " -Daspace.config.#{key}=#{value}"
    end

    pid = Process.spawn({:JAVA_OPTS => java_opts},
                        "#{base}/../build/run", "frontend:devserver:integration",
                        "-Daspace.frontend.port=#{port}")

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
