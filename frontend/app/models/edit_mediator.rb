require 'thread'
require 'atomic'

class EditMediator

  # The table of all editing clients
  @active_edits = Atomic.new({})

  # Queue used to serialise access to the active edit table
  @queue = Queue.new

  Editor = Struct.new(:user, :uri, :lock_version, :last_report_time)


  def self.record(user, uri, lock_version, last_report_time)
    @queue << {
      :type => :update,
      :values => [user, uri, lock_version, last_report_time]
    }

    {:status => "ok"}
  end


  class UpdateThread

    def initialize(active_edits, queue)
      @active_edits = active_edits
      @queue = queue
    end


    def record_update_locally(values)
      editor = Editor.new(*values)
      @active_edits.update {|edits|
        edits.merge({[editor.user, editor.uri] => editor})
      }
    end


    def synchronise_with_backend
    end

    def start
      Thread.new do
        while true
          begin
            request = @queue.pop

            $stderr.puts("Got request: #{request.inspect}")

            if request[:type] == :update
              self.record_update_locally(request[:values])
            elsif request[:type] == :sync
              self.synchronise_with_backend
            end

          rescue
            $stderr.puts("ERROR: Edit mediator: #{$!}")
            sleep 5
          end
        end
      end

    end
  end


  # When the system starts, run the update thread
  UpdateThread.new(@active_edits, @queue).start
end
