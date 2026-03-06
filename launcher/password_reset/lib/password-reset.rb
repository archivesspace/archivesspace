
if $0 =~ /scripts[\/\\][\/\\]password-reset.rb$/
  # This script runs in two contexts: build/run as a part of development, and
  # password-reset.(sh|bat) from the distribution zip file.  Allow for both.
  require_relative '../../launcher/launcher_init'
end

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
