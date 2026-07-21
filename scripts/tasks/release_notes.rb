require 'git'
require 'github_api'
require_relative 'git_jruby_compat'

module ReleaseNotes

  def self.non_semantic_tag_suffix_regex
    /-RC\d+[_-a-zA-Z\d]*$/
  end

  # we are going to convert the incoming current tag to a semantic tag,
  # e.g., v3.4.0-RC1-TEST_FOR_GH-9999 --> v3.4.0
  # then add it to our list of existing semantic tags (if not already there)
  # then sort the list to find its semantic predecessor
  def self.find_previous_tag(current_tag)
    current_tag = current_tag.sub(self.non_semantic_tag_suffix_regex, '')
    git = Git.open('./')
    vtags = git.tags.reject {|t| t.name !~ /^v\d\.\d\.\d$/}.map { |v| v.name }
    vtags << current_tag unless vtags.include?(current_tag)
    matched = false
    vtags.sort.reverse.each do |tag|
      return tag if matched
      matched = (tag == current_tag)
    end
    raise "Cannot find a previous tag for #{current_tag} in #{vtags.join(', ')}!"
  end

  # Generate the release notes for the commit range previous_tag..current_tag
  # and return them as a Markdown string.
  def self.generate(current_tag:, previous_tag: nil, token: nil,
                    gh_user: 'archivesspace', gh_repo: 'archivesspace')
    previous_tag ||= find_previous_tag(current_tag)
    github = github_client(token, gh_user, gh_repo)
    git = Git.open('./')

    log = parse_log(git.log.max_count(:all).between(previous_tag, current_tag))

    # Drop merge commits, which don't represent distinct contributions and just add noise.
    log.reject! { |log_entry| log_entry[:desc].match(/^Merge pull request/) }
    puts "Found #{log.count} commit(s) between #{previous_tag} and #{current_tag} excluding merge commits."

    default_branch = default_branch(github, gh_user, gh_repo)
    original_commits = commits_by_identity(git, default_branch)
    resolve_pull_requests(github, gh_user, gh_repo, log, default_branch, original_commits)

    Generator.new(
      current_tag: current_tag,
      log: log,
      previous_tag: previous_tag,
      style: 'brief'
    ).process.to_s
  end

  def self.github_client(token, gh_user, gh_repo)
    Github.new do |config|
      if token
        config.connection_options = { headers: { 'authorization' => "Bearer #{token}" } }
      end
      config.user = gh_user
      config.repo = gh_repo
    end
  end

  # Resolve and attach the pull request for every commit
  def self.resolve_pull_requests(github, gh_user, gh_repo, log, default_branch, original_commits)
    log.each_with_index do |log_entry, index|
      if ((index + 1) % 50).zero? || index + 1 == log.count
        puts "Resolving pull requests: #{index + 1}/#{log.count}"
      end
      add_pull_request(github, gh_user, gh_repo, log_entry, default_branch, original_commits)
    end
  end


  def self.default_branch(github, gh_user, gh_repo)
    github.get_request("/repos/#{gh_user}/#{gh_repo}")['default_branch']
  end

  # Build a lookup from commit identity to SHA for every commit on a branch.
  #
  # A commit's identity here is its author name, author date, and subject - all
  # of which `git cherry-pick` preserves on the copy it creates. This lets us
  # trace a commit that reached a release branch through a cherry-pick back to
  # the original commit it was copied from on the default branch.
  def self.commits_by_identity(git, branch)
    output = git.lib.send(:command, 'log', '--no-merges', '--format=%H%x1f%an%x1f%at%x1f%s', branch)
    output.each_line.with_object({}) do |line, map|
      sha, name, date, subject = line.chomp.split("\x1f", 4)
      next unless sha

      map[commit_identity(name, date, subject)] ||= sha
    end
  end

  def self.commit_identity(name, date, subject)
    "#{name}\x1f#{date}\x1f#{subject}"
  end

  # Associate a commit (a log entry produced by #parse_log) with the pull
  # request targeting the default branch that introduced it, if any.
  def self.add_pull_request(github, gh_user, gh_repo, log_entry, default_branch, original_commits)
    pr = candidate_pull_request(github, gh_user, gh_repo, log_entry)

    if pr.nil? || pr['base']['ref'] != default_branch
      original_pr = original_pull_request(github, gh_user, gh_repo, log_entry, original_commits)
      pr = original_pr if original_pr
    end

    return unless pr

    log_entry[:pr_number] = pr['number']
    log_entry[:pr_title] = pr['title']
  end

  # The pull request directly associated with a commit: the one named in a
  # squash commit's "(#123)" subject, or the one GitHub reports for the SHA.
  def self.candidate_pull_request(github, gh_user, gh_repo, log_entry)
    if (match = log_entry[:desc].match(/\(#(\d+)\)$/))
      pr = pull_request(github, gh_user, gh_repo, match[1])
      return pr if pr
    end

    pull_request_for_commit(github, gh_user, gh_repo, log_entry[:sha])
  end

  # The pull request of the original commit a cherry-picked commit was copied
  # from, or nil when no distinct original can be found on the default branch.
  def self.original_pull_request(github, gh_user, gh_repo, log_entry, original_commits)
    # Use the primary author name (:author_name), not :authors (which also
    # includes Co-authored-by contributors), so it lines up with the `%an`
    # keys built by .commits_by_identity.
    identity = commit_identity(log_entry[:author_name], log_entry[:author_date], log_entry[:desc])
    original_sha = original_commits[identity]
    return if original_sha.nil? || original_sha == log_entry[:sha]

    pull_request_for_commit(github, gh_user, gh_repo, original_sha)
  end

  # Fetch a single pull request by number
  def self.pull_request(github, gh_user, gh_repo, number)
    github.get_request("/repos/#{gh_user}/#{gh_repo}/pulls/#{number}")
  rescue Github::Error::NotFound
    nil
  end

  def self.pull_request_for_commit(github, gh_user, gh_repo, sha)
    pulls = github.get_request("/repos/#{gh_user}/#{gh_repo}/commits/#{sha}/pulls")
    pulls.find { |pull| pull['merged_at'] } || pulls.first
  end

  # Extract the display name from a "Name <email>" contact string, used to
  # turn a Co-authored-by trailer into a plain author name.
  CONTACT_PATTERN = /\A(.+?)\s*<[^>]+@[^>]+>\z/

  def self.name_from_contact(contact)
    match = contact.match(CONTACT_PATTERN)
    match ? match[1] : contact
  end

  def self.parse_log(gitlog)
    gitlog.map do |log_entry|
      authors = [log_entry.author.name]
      authors += log_entry.message.split(/\n+/)
                    .select { |line| line =~ /^Co-authored-by/ }
                    .map { |line| name_from_contact(line.split(':', 2).last.strip) }
      {
        authors: authors.uniq,
        # Primary author name, used only for cherry-pick identity matching -
        # see .original_pull_request. Display credit uses :authors instead.
        author_name: log_entry.author.name,
        desc: log_entry.message.split("\n")[0],
        sha: log_entry.sha,
        # Author date as a Unix timestamp, matching git's `%at`. Together with
        # the author name and subject it identifies a commit across a
        # cherry-pick, which preserves all three. See .commits_by_identity.
        author_date: log_entry.author.date.to_i
      }
    end
  end

  class Generator
    attr_reader :contributors, :contributions, :doc, :log, :messages, :previous_tag, :style, :current_tag, :migrations

    ANW_URL = 'https://archivesspace.atlassian.net/browse'
    PR_URL  = 'https://github.com/archivesspace/archivesspace/pull'

    # Names must match the spelling that appears in git commit metadata; a
    # contributor whose commits use multiple display names may need multiple entries.
    EXCLUDE_AUTHORS = [
      'Christine Di Bella',
      'Jessica Crouch',
      'Thimios Dimopulos',
      'Thimios',
      'Brian Zelip',
      'dependabot[bot]',
      'Martha Tenney',
      'Martha',
      'Zeff Morgan',
      'Weblate (bot)',
      'Anonymous',
      'archivesspace',
      'aspace-ci-bot'
    ]

    def initialize(current_tag:, log:, previous_tag:, style:)
      @contributors = {}
      @contributions = 0
      @doc = []
      @log = log
      @messages = []
      @current_tag = current_tag
      @previous_tag = previous_tag
      @style = style
      @diff = Git.open('.').gtree("#{@previous_tag}").diff("#{@current_tag}")
      @migrations = OpenStruct.new
      all_changes = @diff.path('common/db/migrations').name_status
      relevant_changes = all_changes.select { |_, d| d == 'A' }
      @migrations.count = relevant_changes.count
      @migrations.schema_version = (@migrations.count>0) ? relevant_changes.to_a.last.map { |m| m[/\d+/] }.first : "UNCHANGED"
    end

    def process
      log.each do |data|
        add_jira_id(data)
        if data[:pr_number]
          messages << format_log_entry(data)
        end
        next if data[:pr_title].nil? && data[:desc].nil?
        data[:authors].each do |author|
          next if EXCLUDE_AUTHORS.include?(author)
          contributors[author] ||= []
          contributors[author] << data
        end
      end

      # Group each author's commits by contribution title, so a contribution
      # spread across several pull requests (e.g. recurring translation
      # updates) is listed on a single line.
      contributors.transform_values! do |entries|
        entries.group_by { |data| contribution_title(data) }.values
      end

      @contributions = contributors.values.sum(&:size)
      make_doc
      self
    end

    def to_s
      doc.join("\n")
    end

    private

    def pr_count
      log.map {|l| l[:pr_number]}.compact.uniq.count
    end

    def ticket_count
      log.map {|l| l[:anw_number]}.compact.uniq.count
    end

    def add_jira_id(data)
      if (data[:desc].match(/ANW[\s_-]*(\d+)/i) || data[:pr_title]&.match(/ANW[\s_-]*(\d+)/i))
        data[:anw_number] = "ANW-#{$1}"
      end
    end

    def anw_link(anw_number)
      return nil unless anw_number

      anw_capitalized = anw_number.upcase.gsub(' ', '-')
      "[#{anw_number}](#{ANW_URL}/#{anw_capitalized})"
    end

    def pr_link(pr_number)
      return nil unless pr_number

      "[#{pr_number}](#{PR_URL}/#{pr_number})"
    end

    def find_deprecations
      deprecated_endpoints = []
      Dir.glob('backend/app/controllers/*').each do |controller_file|
        File.foreach(controller_file, "Endpoint") do |ep|
          if ep.include?(".deprecated")
            d_ep = ep.lines.first
            deprecated_endpoints << "Endpoint#{d_ep}"
          end
        end
      end

      deprecated_endpoints
    end

    def format_log_entry(data)
      links = [pr_link(data[:pr_number]), anw_link(data[:anw_number])]
      msg = ''
      if style == 'brief'
        msg = "- #{contribution_line(data)}"
      elsif style == 'verbose'
        msg = "PR: #{links.compact.join(' - ')} "
        msg += "by #{data[:authors].join(', ')} accepted on #{data[:date]}\n"
        msg += "#{data[:title]}\n"
      else
        raise "Invalid style: #{style}"
      end
      msg
    end

    def contribution_title(data)
      data[:pr_title] || data[:desc]
    end

    # An entry for the JIRA Tickets and Pull Requests Completed section: the
    # pull request and Jira ticket links followed by the title.
    def contribution_line(data)
      links = [pr_link(data[:pr_number]), anw_link(data[:anw_number])].compact
      return contribution_title(data) if links.empty?

      prefix = data[:pr_number] ? 'PR: ' : ''
      "#{prefix}#{links.join(' - ')}: #{contribution_title(data)}"
    end

    # An entry for the Community Contributions section: the contribution title
    # followed by a parenthetical linking every pull request that carried it
    # (as "#1234") and the Jira ticket when available. `group` is the commits
    # that share one contribution title.
    def community_contribution(group)
      pr_numbers = group.map { |data| data[:pr_number] }.compact.uniq.sort.reverse
      anw_numbers = group.map { |data| data[:anw_number] }.compact.uniq
      refs = pr_numbers.map { |number| "[##{number}](#{PR_URL}/#{number})" }
      refs += anw_numbers.map { |anw_number| anw_link(anw_number) }
      title = contribution_title(group.first)
      refs.empty? ? title : "#{title} (#{refs.join(', ')})"
    end

    def config_changes
      result = ""
      @diff.path('common/config/config-defaults.rb').patch.split("\n").each do |line|
        next if line =~ /^\+\+\+/ || line =~ /^\-\-\-/
        if line =~ /^@@/ && result.empty?
          result << "```diff\n"
        elsif line =~ /^@@/
          result << "```\n```diff\n"
        elsif line =~ /^[\+\-].+/
          result << line + "\n"
        end
      end
      result << "```\n" unless result.empty?
      result
    end

    def solr_changes
      return @solr_diff if @solr_diff
      @solr_diff = ""
      diff = Git.open('.').gtree("#{@previous_tag}").diff("#{@current_tag}")
      diff.path('solr/schema.xml').patch.split("\n").each do |line|
        next if line =~ /^\+\+\+/ || line =~ /^\-\-\-/
        if line =~ /^@@/ && @solr_diff.empty?
          @solr_diff << "```diff\n"
        elsif line =~ /^@@/
          @solr_diff << "```\n```diff\n"
        elsif line =~ /^[\+\-].+/
          @solr_diff << line + "\n"
        end
      end
      @solr_diff << "```\n" unless @solr_diff.empty?
      @solr_diff
    end

    def make_doc
      doc << "# Release notes for #{current_tag}\n"
      doc << "(Updating from #{previous_tag})"
      doc << "__TODO: add release summary__\n"
      doc << "## Configurations and Migrations\n"
      doc << "This release includes several modifications to the configuration defaults file: \n"
      doc << config_changes
      doc << "This release includes #{migrations.count} new database migrations. The schema number for this release is #{migrations.schema_version}.\n"
      doc << "## API Deprecations\n"
      doc << "The following API endpoints have been newly deprecated as part of this release. For the time being, they will work and you may continue to use them, however they will be removed from the core code of ArchivesSpace on or after **#{DateTime.now.next_year(1).to_date}**.  For more information see the [ArchivesSpace API documentation](https://archivesspace.github.io/archivesspace/api/).\n"
      doc << find_deprecations
      unless solr_changes.empty?
        doc << "## Solr Schema\n"
        doc << "The Solr schema has changed. A rebuild and reindex of the Solr core will be required: \n"
        doc << solr_changes
      end
      doc << "## Other considerations (plugins etc.):\n"
      doc << "__TODO: add anything else to call out here__\n"
      doc << "## Community Contributions\n"
      doc << "Our thanks go out to these members of the community for their code contributions:\n"
      doc.concat contributors.sort_by { |name, _| name }.map { |name, groups|
        items = groups.map { |group| "  - #{community_contribution(group)}\n" }.join
        "- #{name}:\n#{items}"
      }
      doc << "Total community contributions accepted: #{contributions}\n"
      doc << "## JIRA Tickets and Pull Requests Completed\n"
      doc.concat messages.uniq

      doc << "\nTotal Pull Requests accepted: #{pr_count}"
      doc << "Total Jira Tickets closed: #{ticket_count}"
    end

  end

end
