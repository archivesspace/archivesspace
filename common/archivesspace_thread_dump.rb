# A class that watches for updates to a status file and generates a Ruby-level
# dump of all running threads, followed by a Java-level dump of all running
# threads.
#
# You can always trigger a JVM-level thread dump by sending a QUIT signal to the
# JVM process, but sometimes these thread dumps can be dashed hard to read.

require 'java'

class ArchivesSpaceThreadDump

  def self.init(status_file_path)
    $stderr.puts("\n#{self}: Touch the file '#{status_file_path}' to trigger a thread dump")

    Thread.new do
      begin
        watcher = java.nio.file.FileSystems.getDefault().newWatchService()

        status_file_path = File.absolute_path(status_file_path)
        dir = java.nio.file.Paths.get(File.dirname(status_file_path))

        dir.register(watcher,
                     java.nio.file.StandardWatchEventKinds::ENTRY_CREATE)

        loop do
          key = watcher.take

          key.poll_events.each do |event|
            # Cast both to Path objects to normalize between '/' and '\\' on win32
            if dir.resolve(event.context).to_string == java.nio.file.Paths.get(status_file_path).to_string
              begin
                ArchivesSpaceThreadDump.print_dump
              rescue
                $stderr.puts("Problem while printing thread dump: #{$!}")
              end

              File.unlink(status_file_path)
            end
          end

          unless key.reset
            raise "Key reset failed"
          end
        end
      rescue
        $stderr.puts "Failure in #{self} handler for path #{status_file_path}: #{$!}"
        $stderr.puts($@)
      end
    end
  end

  def self.print_dump
    $stderr.puts("[#{Time.now.to_i}] Starting Ruby-level thread dump")
    $stderr.puts("=" * 72)

    Thread.list.each do |thread|
      $stderr.puts("\n")
      $stderr.puts(thread.inspect)
      thread.backtrace.each do |frame|
        $stderr.puts("  #{frame}")
      end
    end

    $stderr.puts("")

    $stderr.puts("[#{Time.now.to_i}] Starting JVM-level thread dump")
    $stderr.puts("=" * 72)

    java.lang.Thread.all_stack_traces.each do |thread, frames|
      $stderr.puts("\n")
      $stderr.puts("\"#{thread.name}\"")
      frames.each do |frame|
        $stderr.puts("  #{frame}")
      end
    end

    $stderr.puts("")
    $stderr.puts("==== End of thread dump ====")
  end

end
