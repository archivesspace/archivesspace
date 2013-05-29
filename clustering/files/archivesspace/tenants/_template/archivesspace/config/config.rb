$basedir = File.expand_path(File.dirname(__FILE__))
load File.join($basedir, "../../../../config/tenant.rb")

# E.g.: jdbc:mysql://somehost:3306/dbname?user=db_username&password=db_pass&useUnicode=true&characterEncoding=UTF-8
AppConfig[:db_url] = "<FILL THIS IN>"

# A random string (the password for the user account used by search indexing)
AppConfig[:search_user_secret] = "<FILL THIS IN>"
AppConfig[:public_user_secret] = "<FILL THIS IN>"
AppConfig[:staff_user_secret] = "<FILL THIS IN>"

# Secrets used for securing cookies
AppConfig[:frontend_cookie_secret] = "<FILL THIS IN>"
AppConfig[:public_cookie_secret] = "<FILL THIS IN>"
