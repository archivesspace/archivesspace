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

    if status && status['lock_version'] && status['lock_version'] > lock_version
      # Stale
      return {:status => "stale"}
    end


    # Record the fact that this user is editing
    @queue << {
      :type => :update,
      :values => [user, uri, last_report_time.iso8601]
    }

    if status && status['edited_by'].keys.count > 1
      # Someone else is editing too!
      {
        :status => "opened_for_editing",
        'edited_by' => Hash[status['edited_by'].reject {|u, _| u == user}]
      }
    else
      {:status => "ok"}
    end
  end


  class UpdateThread

    # We send our local copy of the active edits table to the backend
    # periodically.  Set this the same as the client's INTERVAL_PERIOD so we
    # don't add too much delay to a client's update hitting the backend.
    SYNC_WITH_BACKEND_SECONDS = 10

    def initialize(active_edits, queue)
      @active_edits = active_edits
      @queue = queue
    end


    def record_update_locally(user, uri, last_report_time)
      @active_edits.update {|edits|
        entry = edits[uri] ? edits[uri].clone : {'edited_by' => {}}
        entry['edited_by'][user] = last_report_time

        edits.merge(uri => entry)
      }
    end


    def log_in_to_backend(force = false)
      @backend_session = nil if force

      if !@backend_session
        response = JSONModel::HTTP.post_form("/users/#{AppConfig[:staff_username]}/login",
                                             {
                                               "expiring" => "false",
                                               "password" => AppConfig[:staff_user_secret]
                                             })

        auth = ASUtils.json_parse(response.body)

        @backend_session = auth['session']
      end

      @backend_session
    end


    def synchronise_with_backend
      snapshot = @active_edits.value
      edits = JSONModel(:active_edits).new

      edits.active_edits = snapshot.map {|uri, entries|
        entries['edited_by'].map {|user, last_time|
          {
            'uri' => uri,
            'user' => user,
            'time' => last_time,
          }
        }
      }.flatten(1)

      JSONModel::HTTP.current_backend_session = log_in_to_backend

      begin
        updated = edits.save({}, true)
        @active_edits.update {|old_val| updated}
      rescue AccessDeniedException
        log_in_to_backend(true)
      end
    end

    def start

      # The main thread: respond to updates and manage the local editing state.
      Thread.new do
        while true
          begin
            request = @queue.pop

            if request[:type] == :update
              self.record_update_locally(*request[:values])
            elsif request[:type] == :sync
              self.synchronise_with_backend
            end
          rescue
            $stderr.puts("ERROR: Edit mediator: #{$!}: #{$@}")
            sleep 5
          end
        end
      end


      # A separate thread to trigger a sync with the backend every now and then.
      Thread.new do
        while true
          sleep SYNC_WITH_BACKEND_SECONDS
          @queue << {:type => :sync}
        end
      end

    end
  end


  # When the system starts, run the update thread
  UpdateThread.new(@active_edits, @queue).start
end
