class Preference < Sequel::Model(:preference)
  include ASModel
  corresponds_to JSONModel(:preference)

  set_model_scope :repository


  def before_save
    super
    self.user_uniq = self.user_id || 'GLOBAL_USER'
  end


  def parsed_defaults
    ASUtils.json_parse(self.defaults)
  end


  def self.parsed_defaults_for(filter)
    pref = self[filter.merge(:repo_id => RequestContext.get(:repo_id))]
    pref ? pref.parsed_defaults : {}
  end


  def self.global_defaults
    RequestContext.open(:repo_id => Repository.global_repo_id) do
      self.parsed_defaults_for(:user_id => nil)
    end
  end


  def self.user_global_defaults
    RequestContext.open(:repo_id => Repository.global_repo_id) do
      user_defs = self.parsed_defaults_for(:user_id => User[:username => RequestContext.get(:current_username)].id)
      self.global_defaults.merge(user_defs)
    end
  end


  def self.repo_defaults
    self.user_global_defaults.merge(self.parsed_defaults_for(:user_id => nil))
  end


  def self.defaults
    user_defs = self.parsed_defaults_for(:user_id => User[:username => RequestContext.get(:current_username)].id)
    self.repo_defaults.merge(user_defs)
  end


  def self.current_preferences(repo_id = RequestContext.get(:repo_id))
    user_id = User[:username => RequestContext.get(:current_username)].id
    filter = {:repo_id => repo_id, :user_uniq => [user_id.to_s, 'GLOBAL_USER']}
    json_prefs = {'defaults' => {}}
    prefs = {}
    defaults = {}

    self.filter(filter).each do |pref|
      if pref.user_uniq == 'GLOBAL_USER'
        json_prefs['repo'] = self.sequel_to_jsonmodel(pref)
        prefs[:repo] = pref
      else
        json_prefs['user_repo'] = self.sequel_to_jsonmodel(pref)
        prefs[:user_repo] = pref
      end
    end

    RequestContext.in_global_repo do
      filter = {:repo_id => Repository.global_repo_id, :user_uniq => [user_id.to_s, 'GLOBAL_USER']}
      self.filter(filter).each do |pref|
        if pref.user_uniq == 'GLOBAL_USER'
          json_prefs['global'] = self.sequel_to_jsonmodel(pref)
          prefs[:global] = pref
        else
          json_prefs['user_global'] = self.sequel_to_jsonmodel(pref)
          prefs[:user_global] = pref
        end
      end
    end

    [:global, :user_global, :repo, :user_repo].each do |k|
      if prefs[k]
        json_prefs['defaults'].merge!(prefs[k].parsed_defaults)
      end
    end
    json_prefs['defaults'].delete('jsonmodel_type')

    json_prefs
  end


  def self.sequel_to_jsonmodel(obj, opts = {})
    json = super
    json['defaults'] = JSONModel(:defaults).from_json(obj.defaults)
    json
  end


  def self.create_from_json(json, opts = {})
    super(json, opts.merge('defaults' => JSON(json.defaults)))
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    super(json, opts.merge('defaults' => JSON(json.defaults)),
          apply_nested_records)
  end

end
