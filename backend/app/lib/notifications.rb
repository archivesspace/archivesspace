require_relative 'longpolling'
require 'thread'

class Notifications

  def self.init
    @longpolling = LongPolling.new(AppConfig[:notifications_backlog_ms])

    @last_sequence = 0

    start_background_thread
  end


  def self.shutdown
    @longpolling.shutdown if @longpolling
  end


  def self.notify(code, params = {}, immediate = true)
    if DB.in_transaction?
      # Don't bother emitting a notification if we already have an identical one
      # queued one up for this database transaction anyway.  Prevents floods of
      # identical notifications during large imports.
      DB.session_storage[:emitted_notifications] ||= []
      notification = {:code => code, :params => params.to_json}

      if DB.session_storage[:emitted_notifications].include?(notification)
        # Already got this one
        return
      else
        DB.session_storage[:emitted_notifications] << notification
      end
    end

    DB.after_commit do
      DB.open do |db|
        db[:notification].insert(:code => code, :params => DB.blobify(params.to_json),
                                 :time => Time.now)
      end

      if immediate
        # Fire it out straight away.  This will cause duplicates when the same
        # notification is read from the database, but that's OK.
        @longpolling.record_update(:code => code, :params => params)
      end
    end
  end


  def self.since(seq)
    @longpolling.updates_since(seq)
  end


  def self.blocking_since(seq)
    @longpolling.blocking_updates_since(seq)
  end


  def self.expire_old_notifications
    DB.open do |db|
      db[:notification].where {time < (Time.now - ((AppConfig[:notifications_backlog_ms] / 1000.0) * 2))}.delete
    end
  end


  def self.start_background_thread
    frequency = AppConfig[:notifications_poll_frequency_ms] / 1000.0

    Thread.new do
      while true
        begin
          sleep frequency

          DB.open do |db|
            last_sequence = @last_sequence
            db[:notification].where {id > last_sequence}.all.each do |row|
              @longpolling.record_update(:code => row[:code], :params => ASUtils.json_parse(row[:params]))
              @last_sequence = row[:id] if row[:id] > @last_sequence
            end
          end
        rescue
          Log.warn("#{$!}: #{$@}")
        end
      end
    end
  end

end
