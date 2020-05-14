require_relative 'factories'

module SpecHelperMethods
  extend self

  def make_test_repo(code = "ARCHIVESSPACE", org_code = "test", is_slug_auto = 0)
    repo = create(:repo, {:repo_code => code, :org_code => org_code, :is_slug_auto => is_slug_auto})

    @repo_id = repo.id
    @repo = JSONModel(:repository).uri_for(repo.id)

    JSONModel::set_repository(@repo_id)
    RequestContext.put(:repo_id, @repo_id)

    @repo_id
  end


  def make_test_user(username, name = "A test user", source = "local")
    create(:user, {:username => username, :name => name, :source => source})
  end


  def create_accession(opts = {})
    Accession.create_from_json(build(:json_accession,
                                     {:title => "Papers of Mark Triggs"}.merge(opts)),
                               :repo_id => $repo_id)
  end


  def create_agent_person(opts = {})
    AgentPerson.create_from_json(build(:json_agent_person, opts),
                                 :repo_id => $repo_id)
  end


  def create_archival_object(opts = {})
    ArchivalObject.create_from_json(
      build(:json_archival_object, opts),
      :repo_id => $repo_id
    )
  end
  
  def create_top_container(opts = {})
    TopContainer.create_from_json(
      build(:json_top_container, opts),
      :repo_id => $repo_id
    )
  end
  
  def create_sub_container(opts = {})
      SubContainer.create_from_json(
        build(:json_sub_container, opts),
        :repo_id => $repo_id
      )
    end


  def create_event(opts = {})
    Event.create_from_json(build(:json_event, opts),
                           :repo_id => $repo_id)
  end


  def create_resource(opts = {})
    Resource.create_from_json(build(:json_resource, opts), :repo_id => $repo_id)
  end


  def create_digital_object(opts = {})
    DigitalObject.create_from_json(build(:json_digital_object, opts), :repo_id => $repo_id)
  end


  def create_digital_object_component(opts = {})
    DigitalObjectComponent.create_from_json(
      build(:json_digital_object_component, opts), :repo_id => $repo_id
    )
  end


  def create_nobody_user
    user = create(:user, :username => 'nobody')

    viewers = JSONModel(:group).all(:group_code => "repository-viewers").first
    viewers.member_usernames = ['nobody']
    viewers.save

    user
  end


  def as_test_user(username)
    old_user = Thread.current[:active_test_user]
    Thread.current[:active_test_user] = User.find(:username => username)
    orig = RequestContext.get(:enforce_suppression)
    old_username = RequestContext.get(:current_username)

    begin
      if RequestContext.active?
        RequestContext.put(:enforce_suppression,
                           !Thread.current[:active_test_user].can?(:manage_repository))
        RequestContext.put(:current_username, username)
      end

      yield
    ensure
      RequestContext.put(:enforce_suppression, orig) if RequestContext.active?
      RequestContext.put(:current_username, old_username) if RequestContext.active?
      Thread.current[:active_test_user] = old_user
    end
  end


  def as_anonymous_user
    old_user = Thread.current[:active_test_user]
    orig = RequestContext.get(:enforce_suppression)

    Thread.current[:active_test_user] = AnonymousUser.new

    begin
      if RequestContext.active?
        RequestContext.put(:enforce_suppression, true)
      end

      yield
    ensure
      RequestContext.put(:enforce_suppression, orig) if RequestContext.active?
      Thread.current[:active_test_user] = old_user
    end
  end

  def create_user(username = "test1", name = "Tester")
    user = JSONModel(:user).from_hash(:username => username,
                                      :name => name)

    # Probably more realistic than we'd care to think
    user.save(:password => "password")
  end

end
