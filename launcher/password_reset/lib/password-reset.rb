require_relative '../../launcher_init'
require 'config/config-distribution'
require 'bcrypt'
require 'sequel'

class PasswordReset

  include BCrypt

  def set_password(username, password)
    pwhash = Password.create(password)

    Sequel.connect(AppConfig[:db_url]) do |db|
      if db[:auth_db].filter(:username => username).count == 1
        db[:auth_db].filter(:username => username).
                     update(:pwhash => pwhash,
                            :system_mtime => Time.now)
        puts "Password updated for user: #{username}"
      else
        puts "User not found: #{username}"
      end
    end
  rescue Sequel::DatabaseError => e
    puts "Trouble connecting to database: #{e}"
  end

end


def main
  if ARGV.length != 2
    puts "Usage: password-reset <username> <new password>"
    exit
  end

  PasswordReset.new.set_password(*ARGV)
end


main
