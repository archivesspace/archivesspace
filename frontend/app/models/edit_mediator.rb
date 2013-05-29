require 'thread'
require 'atomic'

class EditMediator

  # The table of all editing clients
  @active_edits = Atomic.new({})

  # Queue used to serialise access to the active edit table
  @queue = Queue.new

  def self.record(user, uri, lock_version, last_report_time)

    # Check whether the lock version is out of date, or whether someone else is
    # editing.
    status = @active_edits.value[uri]

    if status && status[:lock_version] && status[:lock_version] > lock_version
      # Stale
      return {:status => "stale"}
    end


    # Record the fact that this user is editing
    @queue << {
      :type => :update,
      :values => [user, uri, last_report_time]
    }

    if status && status[:edited_by].keys.count > 1
      # Someone else is editing too!
      {
        :status => "opened_for_editing",
        :edited_by => Hash[status[:edited_by].reject {|u, _| u == user}]
      }
    else
      {:status => "ok"}
    end
  end


  class UpdateThread

    def initialize(active_edits, queue)
      @active_edits = active_edits
      @queue = queue
    end


    def record_update_locally(user, uri, last_report_time)
      @active_edits.update {|edits|
        entry = edits[uri] ? edits[uri].clone : {:edited_by => {}}
        entry[:edited_by][user] = last_report_time

        edits.merge(uri => entry)
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
              self.record_update_locally(*request[:values])
            elsif request[:type] == :sync
              self.synchronise_with_backend
            end

            puts @active_edits.value.inspect

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
