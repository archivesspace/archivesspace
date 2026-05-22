# JRuby compatibility shim for the `git` gem.
#
# The `git` gem (>= 2.x) captures a subprocess's stdout and stderr through an
# in-process pipe (ProcessExecuter::MonitoredPipe, backed by IO.pipe). Under
# JRuby the write end of that pipe, once inherited by the native `git` child
# process, behaves as non-blocking. As soon as the pipe buffer fills - which it
# does for large output such as `git log --pretty=raw` across a full release -
# git aborts with:
#
#   fatal: write failure on 'stdout': Resource temporarily unavailable
#
# Redirecting git's stdout and stderr to regular temp files instead of a pipe
# sidesteps the problem entirely: a regular file is always a blocking sink with
# no buffer limit. Once git exits we copy the captured bytes into the writers
# the gem expects, so the rest of the gem is unaffected.

require 'git'
require 'process_executer'
require 'tempfile'

module Git
  class CommandLine
    private

    def spawn(cmd, out_writers, err_writers, chdir:, timeout:)
      Tempfile.create('aspace-release-notes-git-out') do |out_file|
        Tempfile.create('aspace-release-notes-git-err') do |err_file|
          status = ProcessExecuter.spawn(
            env, *cmd,
            out: out_file, err: err_file, chdir: chdir, timeout: timeout
          )
          copy_captured_output(out_file, out_writers)
          copy_captured_output(err_file, err_writers)
          status
        end
      end
    end

    def copy_captured_output(file, writers)
      data = File.binread(file.path)
      writers.each do |writer|
        case writer
        when :out, 1 then $stdout.write(data)
        when :err, 2 then $stderr.write(data)
        else writer.write(data)
        end
      end
    end
  end
end
