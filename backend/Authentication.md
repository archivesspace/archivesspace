Adding support for additional username/password-based authentication backends
=============================================================================

ArchivesSpace supports LDAP-based authentication out of the box, but
you can authenticate against other password-based user directories by
defining your own authentication handler and configuring your
ArchivesSpace instance to use it.


Creating a new authentication handler class
-------------------------------------------

An authentication handler is just a class that implements a couple of
key methods:

  * `initialize(opts)` -- An object constructor which receives the
    configuration block specified in the system's configuration.

  * `name` -- A zero-argument method which just returns a string that
    identifies the instance of your handler.  The format of this
    string isn't important: it just gets stored as a user attribute
    (in the ArchivesSpace database) to make it possible to tell which
    authentication source a user last successfully authenticated
    against.

  * `authenticate(username, password)` -- a method which checks
    whether `password` is the correct password for `username`.  If the
    password is correct, returns an instance of `JSONModel(:user)`.
    Otherwise, returns `nil`.

A new instance of your handler will be created for each login attempt,
so there's no need to handle concurrency in your implementation.

Your `authenticate` method can do whatever is required to check that
the provided password is correct, with the only constraint being that
it must return either `nil` or a `JSONModel(:user)` instance.

The `JSONModel(:user)` class (whose JSON schema is defined in
`common/schemas/user.rb`) defines the set of properties that the
system needs for a user.  When you return a `JSONModel(:user)` object,
its values will be used to create an ArchivesSpace user (if a user by
that name didn't exist already), or update the existing user (if they
were already known).

**Note**: `The JSONModel(:user)` class validates the values you give it
against its JSON schema and throws an `JSONModel::ValidationException`
if anything isn't right.  If this happens within your handler, the
exception will be logged and the authentication request will fail.

### A skeleton implementation

Suppose you already have a database with a table containing users that
should be able to log in to ArchivesSpace.  Below is a sketch of an
authentication handler that will connect to this database and use it
for authentication.


      # For this example we'll use the Sequel database toolkit.  Note that
      # this isn't necessary--you could use whatever database library you
      # like here.
      require 'sequel'

      class MyDatabaseAuth

        # For easy access to the JSONModel(:user) class
        include JSONModel


        def initialize(definition)
          # Store the database connection details for use at
          # authentication time.
          @db_url = definition[:db_url] or raise "Need a value for :db_url"
        end


        # Just for informational purposes.  Return a string containing our
        # database URL.
        def name
          "MyDatabaseAuth - #{@db_url}"
        end


        def authenticate(username, password)
          # Open a connection to the database
          Sequel.connect(@db_url) do |db|

            # Check whether we have an entry for the given username
            # and password in our database's "users" table
            user = db[:users].filter(:username => username,
                                     :password => password).
                              first

            if !user
              # The user couldn't be found, or their password was wrong.
              # Authentication failed.
              return nil
            end

            # Build and return a JSONModel(:user) instance from fields in the database
            JSONModel(:user).from_hash(:username => username,
                                       :name => user[:user_full_name])

          end
        end

      end


Save your code into a file under `backend/app/models/`, and it will be
automatically loaded when ArchivesSpace starts up.



Modifying your configuration
----------------------------

To have ArchivesSpace invoke your new authentication handler, just add
a new entry to the `:authentication_sources` configuration block.
A configuration for the above example might be as follows:

     AppConfig[:authentication_sources] = [{
                                             :model => 'MyDatabaseAuth',
                                             :db_url => 'jdbc:mysql://localhost:3306/somedb?user=myuser&password=mypassword',
                                           }]

That's it!  You should now see authentication requests hitting your
new handler.
