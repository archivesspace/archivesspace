class Repository < Struct.new(:code, :name, :uri, :display_name, :parent, :parent_url)

  @@AllRepos = {}
  def Repository.get_repos
    if @@AllRepos.blank?
      @@AllRepos = ArchivesSpaceClient.new.list_repositories
    end
    @@AllRepos
  end

  def Repository.set_repos(repos)
    @@AllRepos = repos
  end

  # determine which badges to display
  def Repository.badge_list(repo_code)
    list = []
    %i(resource record digital_object accession subject agent classification).each do |sym|
      badge = "#{sym}_badge".to_sym
      unless AppConfig[:pui_repos].dig(repo_code, :hide, badge).nil? ? AppConfig[:pui_hide][badge] :  AppConfig[:pui_repos][repo_code][:hide][badge]
        list.push(sym.to_s)
      end
    end
    list
  end

  def initialize(code, name, uri, display_name, parent, parent_url = '')
    self.code = code
    self.name = name
    self.uri = uri
    self.display_name = display_name
    self.parent = parent
    self.parent_url = parent_url if !parent_url.blank? &&  !parent_url.end_with?("url\.unspecified")
  end

  def self.from_json(json)
    new(json['repo_code'], json['name'], json['uri'], json['display_string'], json['parent_institution_name'], json['url'])
  end

end
