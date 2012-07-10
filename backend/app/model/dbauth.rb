require 'bcrypt'

class DBAuth

  include BCrypt

  def set_password(username, password)
    pwhash = Password.create(password)

    DB.open do |db|
      begin
        db[:auth_db].insert(:username => username,
                            :pwhash => pwhash,
                            :create_time => Time.now,
                            :last_modified => Time.now)
      rescue Sequel::DatabaseError => ex
        if DB.is_integrity_violation(ex)
          db[:auth_db].
            filter(:username => username).
            update(:username => username,
                   :pwhash => pwhash,
                   :last_modified => Time.now)
        end
      end
    end
  end


  def login(username, password)
    DB.open do |db|
      pwhash = db[:auth_db].filter(:username => username).get(:pwhash)

      return (pwhash and (Password.new(pwhash) == password))
    end
  end
end
