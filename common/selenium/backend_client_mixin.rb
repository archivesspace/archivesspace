# frozen_string_literal: true

require 'ashttp'

module BackendClientMethods

  class ASpaceUser
    attr_reader :username
    attr_reader :password

    def initialize(username, password, json = nil)
      @username = username
      @password = password
      @json = json
    end

    def id
      @json['id']
    end

  end


  def set_repo(repo)
    if repo.respond_to?(:uri)
      set_repo(repo.uri)
    elsif repo.is_a?(String) && repo.match(/^\/repositories\/\d+/)
      set_repo(JSONModel(:repository).id_for(repo))
    else
      JSONModel.set_repository(repo)
    end
  end


  def do_http_request(url, req)
    req['X-ArchivesSpace-Session'] = @current_session

    ASHTTP.start_uri(url) do |http|
      http.read_timeout = 1200
      http.request(req)
    end
  end

  def run_index_round
    $last_sequence ||= 0
    $last_sequence = $indexer.run_index_round($last_sequence)
  end

  def run_periodic_index
    $period.run_index_round
  end


  def run_all_indexers
    run_index_round
    run_periodic_index
  end

  def admin_backend_request(req)
    res = ASHTTP.post_form(URI("#{$backend}/users/admin/login"), :password => "admin")
    admin_session = JSON(res.body)["session"]

    req["X-ARCHIVESSPACE-SESSION"] = admin_session
    req["X-ARCHIVESSPACE-PRIORITY"] = "high"

    uri = URI("#{$backend}")

    ASHTTP.start_uri(uri) do |http|
      res = http.request(req)

      if res.code != "200"
        raise "Bad response: #{res.body}"
      end

      res
    end
  end


  def create_user(roles = {}, active = true)
    user = "test_user_#{SecureRandom.hex}"
    pass = "pass_#{SecureRandom.hex}"

    req = Net::HTTP::Post.new("/users?password=#{pass}")
    req['Content-Type'] = 'text/json'
    req.body = "{\"username\": \"#{user}\", \"name\": \"#{user}\", \"is_active_user\": #{active}}"

    res = admin_backend_request(req)
    roles.each do |repo, repo_roles|
      repo = repo.uri if repo.respond_to?(:uri)
      repo_roles.each do |rr|
        add_user_to_group(user, repo, rr)
      end
    end
    json = JSON.parse(res.body)

    ASpaceUser.new(user, pass, json)
  end

  def create_subjects
    %w[cultural_context function genre_form geographic occupation style_period technique temporal topical uniform_title].each do |term|
      params = { 'lock_version' => '1',
                 'title' => term,
                 'vocabulary' => '/vocabularies/1',
                 'authority_id' => SecureRandom.uuid,
                 'source' => 'local',
                 'scope_note' => 'Test',
                 'terms' => [
                   { 'vocabulary' => '/vocabularies/1',
                     'term' => term,
                     'term_type' => term }
                 ] }

      req = Net::HTTP::Post.new('/subjects')
      req['Content-Type'] = 'text/json'
      req.body = params.to_json

      admin_backend_request(req)
    end
  end

  def add_user_to_group(user, repo, group_code)
    req = Net::HTTP::Get.new("#{repo}/groups")

    groups = admin_backend_request(req)

    uri = JSON.parse(groups.body).find {|group| group['group_code'] == group_code}['uri']

    req = Net::HTTP::Get.new(uri)
    group = JSON.parse(admin_backend_request(req).body)
    group['member_usernames'] = [user]

    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'text/json'
    req.body = group.to_json

    admin_backend_request(req)
  end
end
