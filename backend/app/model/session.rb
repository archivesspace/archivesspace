require 'securerandom'
require 'digest/sha1'

class Session

  SESSION_ID_LENGTH = 32

  attr_reader :id


  def initialize(sid = nil, store = nil)
    if not sid
      # Create a new session in the DB
      DB.open do |db|

        while true
          sid = SecureRandom.hex(SESSION_ID_LENGTH)

          completed = DB.attempt {
            db[:session].insert(:session_id => Digest::SHA1.hexdigest(sid),
                                :session_data => [Marshal.dump({})].pack("m*"),
                                :system_mtime => Time.now)
            true
          }.and_if_constraint_fails {
            # Retry with a different session ID.
            false
          }

          break if completed
        end

        @id = sid
        @store = {}
      end
    else
      @id = sid
      @store = store
    end
  end


  def self.find(sid)
    DB.open do |db|
      session_data = db[:session].filter(:session_id => Digest::SHA1.hexdigest(sid)).get(:session_data)

      if session_data
        Session.new(sid, Marshal.load(session_data.unpack("m*").first))
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
    max_age = AppConfig[:session_expire_after_seconds] || (7 * 24 * 60 * 60)

    DB.open do |db|
      db[:session].where {system_mtime < (Time.now - max_age)}.filter(:expirable => 1).delete
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
    DB.open do |db|
      db[:session]
        .filter(:session_id => Digest::SHA1.hexdigest(@id))
        .update(:system_mtime => Time.now)
    end
  end


  def age
    system_mtime = 0
    DB.open do |db|
      system_mtime = db[:session]
        .filter(:session_id => Digest::SHA1.hexdigest(@id))
        .get(:system_mtime)
    end
    (Time.now - system_mtime).to_i
  end

end
