class Preference < Sequel::Model(:preference)
  include ASModel
  corresponds_to JSONModel(:preference)

  set_model_scope :global
#  set_model_scope :repository


  def self.create_from_json(json, opts = {})
    puts "JJJJJJJJJJJJJJ #{json.inspect} :: #{opts}"
#    user = User.find(:username => json['username'])
#    puts "UUUUUUUUUUUUUU #{user.inspect}"
#    json['user_id'] = user.id unless user.nil?
    super(json, opts)
  end


  def update_from_json(json, opts = {})
 #   self[:user_id] = opts.fetch(:user).id
    super
  end


  def self.sequel_to_jsonmodel(obj, opts = {})
    json = super

    puts "OOOOOOOOOO #{obj.inspect}"
#    user = User[obj.user_id]

#    puts "UUUUUUUUUU #{user.inspect}"
#    json['username'] = user.username unless user.nil?

    json
  end


  def self.defaults
    defaults_for(RequestContext.get(:repo_id), RequestContext.get(:current_username))
  end

  def self.defaults_for(repo_id = 1, username = nil)
#    puts "CCCCCCCCCCCCCC #{RequestContext.get(:current_username)}"
#    puts "CCCCCCCCCCCCCC #{RequestContext.get(:repo_id)}"
    unless username.nil?
      user = User.find(:username => username)
      raise "Username '#{username}' does not exist" if user.nil?
    end

    # get the global defaults
    defaults = JSON.parse(Preference.find(:repo_id => 1).defaults)

    # merge in the global defaults for the user if specified
    unless username.nil?
      user_prefs = Preference.find(:repo_id => 1, :user_id => user.id)
      unless user_prefs.nil?
        defaults.merge!(JSON.parse(user_prefs.defaults))
      end
    end

    # merge in the defaults for the repository if specified
    if repo_id != 1
      repo_prefs = Preference.find(:repo_id => repo_id, :user_id => nil)
      unless repo_prefs.nil?
        defaults.merge!(JSON.parse(repo_prefs.defaults))
      end

      # merge in the defaults for the user if specified
      unless username.nil?
        user_prefs = Preference.find(:repo_id => repo_id, :user_id => user.id)
        unless user_prefs.nil?
          defaults.merge!(JSON.parse(user_prefs.defaults))
        end
      end
    end

    JSON.generate(defaults)
  end

end
