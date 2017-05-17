require 'securerandom'
require 'digest/sha1'

class Session

  SESSION_ID_LENGTH = 32

  # If it's worth doing it's worth overdoing!
  #
  # For really small AJAX-driven lookups, like nodes and waypoints, sometimes
  # touching the user's session (with its associated database commit) was adding
  # 5-10x to the response time.  Upsetting!
  #
  # Since touching sessions is very common, but not really mission critical,
  # offload the work to a background thread that will periodically update them.

  UPDATE_FREQUENCY_SECONDS = 5

  def self.init
    @sessions_to_update = Queue.new

    @session_touch_thread = Thread.new do
      while true
        begin
          self.touch_pending_sessions
        rescue
          Log.exception($!)
        end

        sleep UPDATE_FREQUENCY_SECONDS
      end
    end
  end

  def self.touch_pending_sessions(now = Time.now)
    sessions = []

    while !@sessions_to_update.empty?
      sessions << @sessions_to_update.pop
    end

    unless sessions.empty?
      DB.open do |db|
        db[:session]
          .filter(:session_id => sessions.map {|id| Digest::SHA1.hexdigest(id) }.uniq)
          .update(:system_mtime => now)
      end
    end
  end

  def self.touch_session(id)
    @sessions_to_update << id
  end


  attr_reader :id, :system_mtime

  def initialize(sid = nil, store = nil, system_mtime = nil)
    now = Time.now

    if not sid
      # Create a new session in the DB
      DB.open do |db|

        while true
          sid = SecureRandom.hex(SESSION_ID_LENGTH)

          completed = DB.attempt {
            db[:session].insert(:session_id => Digest::SHA1.hexdigest(sid),
                                :session_data => [Marshal.dump({})].pack("m*"),
                                :system_mtime => now)
            true
          }.and_if_constraint_fails {
            # Retry with a different session ID.
            false
          }

          break if completed
        end

        @id = sid
        @system_mtime = now
        @store = {}
      end
    else
      @id = sid
      @store = store
      @system_mtime = system_mtime
    end
  end


  def self.find(sid)
    DB.open do |db|
      row = db[:session]
        .filter(:session_id => Digest::SHA1.hexdigest(sid))
        .select(:session_data, :system_mtime)
        .first

      if row
        Session.new(sid, Marshal.load(row[:session_data].unpack("m*").first), row[:system_mtime])
      else
        nil
      end
    end
  end


  def self.expire(sid)
    DB.open do |db|
      db[:session].filter(:session_id => Digest::SHA1.hexdigest(sid)).delete
    end
  end


  def self.expire_old_sessions
    max_expirable_age = AppConfig[:session_expire_after_seconds] || (7 * 24 * 60 * 60)
    max_nonexpirable_age = AppConfig[:session_nonexpirable_force_expire_after_seconds] || (7 * 24 * 60 * 60)

    DB.open do |db|
      db[:session].where {system_mtime < (Time.now - max_expirable_age)}.filter(:expirable => 1).delete
      db[:session].where {system_mtime < (Time.now - max_nonexpirable_age)}.filter(:expirable => 0).delete
    end
  end


  def []=(key, val)
    @store[key] = val
  end


  def [](key)
    return @store[key]
  end


  def save
    DB.open do |db|
      db[:session]
        .filter(:session_id => Digest::SHA1.hexdigest(@id))
        .update(:session_data => [Marshal.dump(@store)].pack("m*"),
                :expirable => @store[:expirable] ? 1 : 0,
                :system_mtime => Time.now)
    end
  end


  def touch
    self.class.touch_session(@id)
  end


  def age
    (Time.now - system_mtime).to_i
  end

end
