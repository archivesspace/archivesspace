require 'bcrypt'

class DBAuth

  include BCrypt

  def add_user(username, password)
    pwhash = Password.create(password)

    DB.open do |db|
      db[:auth_db].insert(:username => username,
                          :pwhash => pwhash,
                          :create_time => Time.now,
                          :last_modified => Time.now)
    end
  rescue Sequel::DatabaseError => ex
    if DB.is_integrity_violation(ex)
      raise ConflictException.new("User '#{username}' already exists.")
    end
  end


  def login(username, password)
    DB.open do |db|
      pwhash = db[:auth_db].filter(:username => username).get(:pwhash)

      return (pwhash and (Password.new(pwhash) == password))
    end
  end
end
