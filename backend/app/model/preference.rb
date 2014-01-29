class Preference < Sequel::Model(:preference)
  include ASModel
  corresponds_to JSONModel(:preference)

  set_model_scope :global


  def before_save
    super
    self.user_uniq = self.user_id || 'GLOBAL_USER'
  end


  def self.defaults
    defaults_for(RequestContext.get(:repo_id), RequestContext.get(:current_username))
  end


  def self.defaults_for(repo_id = Repository.global_repo_id, username = nil)
    unless username.nil?
      user = User.find(:username => username)
      raise "Username '#{username}' does not exist" if user.nil?
    end

    # get the global defaults
    defaults = ASUtils.json_parse(Preference.find(:repo_id => Repository.global_repo_id).defaults)

    # merge in the global defaults for the user if specified
    unless username.nil?
      user_prefs = Preference.find(:repo_id => Repository.global_repo_id, :user_id => user.id)
      unless user_prefs.nil?
        defaults.merge!(ASUtils.json_parse(user_prefs.defaults))
      end
    end

    # merge in the defaults for the repository if specified
    if repo_id != Repository.global_repo_id
      repo_prefs = Preference.find(:repo_id => repo_id, :user_id => nil)
      unless repo_prefs.nil?
        defaults.merge!(ASUtils.json_parse(repo_prefs.defaults))
      end

      # merge in the repository defaults for the user if specified
      unless username.nil?
        user_prefs = Preference.find(:repo_id => repo_id, :user_id => user.id)
        unless user_prefs.nil?
          defaults.merge!(ASUtils.json_parse(user_prefs.defaults))
        end
      end
    end

    defaults
  end

end
