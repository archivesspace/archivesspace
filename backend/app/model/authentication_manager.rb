require_relative 'dbauth'

class AuthenticationManager

  def self.prepare_sources(sources)
    sources.map { |source|
      model = Kernel.const_get(source[:model].intern)

      model.new(source)
    }
  end

  def self.authentication_sources
    [DBAuth] + prepare_sources(AppConfig[:authentication_sources])
  end


  # Attempt to authenticate `user' with the provided `password'.
  # Return a User object if successful, nil otherwise
  def self.authenticate(username, password)

    authentication_sources.each do |source|
      begin
        jsonmodel_user = source.authenticate(username, password)

        if !jsonmodel_user
          next
        end

        user = User.find(:username => username)

        if user
          begin
            user.update_from_json(jsonmodel_user,
                                  :source => source.name,
                                  :lock_version => user.lock_version)
          rescue Sequel::NoExistingObject => e
            # We'll swallow these because they only really mean that the user
            # logged in twice simultaneously.  As long as one of the updates
            # succeeded it doesn't really matter.
            Log.warn("Got an optimistic locking error when updating user: #{e}")

            user = User.find(:username => username)
          end
        else
          DB.attempt {
            user = User.create_from_json(jsonmodel_user, :source => source.name)
          }.and_if_constraint_fails {
            return authenticate(username, password)
          }
        end

        return user
      rescue
        Log.error("Error communicating with authentication source #{source.inspect}: #{$!}")
        Log.exception($!)
        next
      end
    end

    nil
  end


  def self.matching_usernames(query)
    authentication_sources.map {|source|
      source.matching_usernames(query)
    }.flatten(1).sort.uniq
  end


  ArchivesSpaceService.loaded_hook do
    # Fire this at load time to sanity check our source definitions
    self.authentication_sources
  end
end
