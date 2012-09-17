require 'rbconfig'

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


  def self.wait_for_url(url)
    while true
      begin
        response = Net::HTTP.get_response(url)

        if response.is_a?(Net::HTTPSuccess)
          break
        else
          raise "Not ready (#{response})"
        end
      rescue
        # Keep trying
        puts "Waiting for #{url} (#{$!.inspect})"
        sleep(5)
      end
    end
  end


  def self.start_backend(port)
    base = File.dirname(__FILE__)

    Process.spawn({:JAVA_OPTS => "-Xmx64M -XX:MaxPermSize=64M"},
                  "#{base}/../build/run", "backend:devserver:integration",
                  "-Daspace.backend.port=#{port}",
                  "-Daspace_integration_test=1")
  end


  def self.start_frontend(port, backend_url)
    base = File.dirname(__FILE__)

    Process.spawn({:JAVA_OPTS => "-Xmx128M -XX:MaxPermSize=96M -Daspace.config.backend_url=#{backend_url}"},
                  "#{base}/../build/run", "frontend:devserver:integration",
                  "-Daspace.frontend.port=#{port}")
  end

end
