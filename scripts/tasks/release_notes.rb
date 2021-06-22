# frozen_string_literal: true

require 'github_api'

module ReleaseNotes
  module GitLogParser
    ANW_MATCH = /([Aa][Nn][Ww][- ]\d+)(\s|\.|:)/.freeze

    def self.run(milestone:)
      github = Github.new user: 'archivesspace',
                          repo: 'archivesspace',
                          basic_auth: ENV["REL_NOTES_TOKEN"]

      @new_milestone = (github.issues.milestones.list).select{|m| m['title'] == milestone }.first

      pull_requests = []
      issue_search = github.issues.list user: 'archivesspace',
                                        repo: 'archivesspace',
                                        state: 'closed',
                                        base: 'master',
                                        milestone: @new_milestone.number,
                                        auto_pagination: true
      issue_search.each do |issue|
        pull_requests << [issue&.number, issue&.title]
      end

      log = []
      pull_requests.each do |pr|
        commits = github.pull_requests.commits 'archivesspace', 'archivesspace', pr[0]
        if commits.count > 1
          # Catch PRs with multiple commits all authored and committed by the
          # same person (e.g. we should have had them squash) and only keep one
          # of those commits
          if (commits.map {|c| c.commit.author.name}).difference(commits.map {|c| c.commit.committer.name}).empty?
            commits = commits.uniq { |c| [c.commit.author.name] }
          # Otherwise, there's probably some other reason this PR has multiple
          # commits (cherry-picks, multiple authors, etc.) so we want to keep
          # them all but denote that they're special
          else
            commits.each do |c|
              c[:single_commit] = true
            end
          end
        end

        commits.each do |commit|
          data = {}
          data[:pr_number] = pr[0]
          data[:anw_number] = pr[1].match(ANW_MATCH)[1] if pr[1] =~ ANW_MATCH
          data[:single_commit] = true if commit[:single_commit]
          data[:author] = commit.commit.author.name
          data[:date] = commit.commit.author.date
          data[:desc] = commit.commit.message
          data[:title] = pr[1]
          log << data
        end
      end
      log.sort_by { |l| l[:pr_number].to_i }
    end

  end

  class Generator
    attr_reader :contributors, :contributions, :doc, :log, :messages, :old_milestone, :style, :version
    ANW_URL = 'https://archivesspace.atlassian.net/browse'
    PR_URL  = 'https://github.com/archivesspace/archivesspace/pull'
    EXCLUDE_AUTHORS = [
      'Christine Di Bella',
      'Jessica Crouch',
      'Laney McGlohon',
      'Lora Woodford',
      'Mark Cooper',
      'dependabot[bot]'
    ]

    def initialize(version:, log:, old_milestone:, style:)
      @contributors = {}
      @contributions = 0
      @doc = []
      @log = log
      @messages = []
      @old_milestone = old_milestone
      @style = style
      @version = version
    end

    def process
      log.each do |data|
        unless EXCLUDE_AUTHORS.include?(data[:author])
          contributors[data[:author]] = [] unless contributors.key? data[:author]
          # If this is a standalone commit, grab the commit message, otherwise
          # we want the PR title (it'll have ANW numbers)
          title = data[:single_commit] ? data[:desc].lines.first.strip : data[:title]
          contributors[data[:author]] << title
        end
        if data[:pr_number]
          messages << format_log_entry(data)
        end
      end
      @contributions = contributors.map{ |_, v| v.count }.reduce(:+)
      make_doc
      self
    end

    def to_s
      doc.join("\n")
    end

    private

    def anw_link(anw_number)
      return nil unless anw_number

      anw_capitalized = anw_number.upcase.gsub(' ','-')
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
        msg = "- PR: #{links.compact.join(' - ')}: #{data[:title]}"
      elsif style == 'verbose'
        msg = "PR: #{links.compact.join(' - ')} "
        msg += "by #{data[:author]} accepted on #{data[:date]}\n"
        msg += "#{data[:title]}\n"
      else
        raise "Invalid style: #{style}"
      end
      msg
    end

    def find_new(old = old_milestone, new = version)
      g = Git.open('.')
      configs = g.gtree("v#{old}").diff("v#{new}").path('common/config/config-defaults.rb')

      all_changes = g.gtree("v#{old}").diff("v#{new}").path('common/db/migrations').name_status
      migrations = all_changes.select{ |_,d| d == 'A'}
      return configs, migrations
    end

    def make_doc
      doc << "# Release notes for v#{version}\n"
      doc << "__TODO: add release summary__\n"
      doc << "## Configurations and Migrations\n"
      doc << "This release includes several modifications to the configuration defaults file: \n"
      doc << find_new[0]
      doc << "This release includes #{find_new[1].count} new database migrations. The schema number for this release is #{find_new[1].to_a.last.map {|x| x[/\d+/]}.first}.\n"
      doc << "## API Deprecations\n"
      doc << "The following API endpoints have been newly deprecated as part of this release. For the time being, they will work and you may continue to use them, however they will be removed from the core code of ArchivesSpace on or after **#{DateTime.now.next_year(1).to_date}**.  For more information see the [ArchivesSpace API documentation](https://archivesspace.github.io/archivesspace/api/).\n"
      doc << find_deprecations
      doc << "## Other considerations (plugins etc.):\n"
      doc << "__TODO: add anything else to call out here__\n"
      doc << "## Community Contributions\n"
      doc << "Our thanks go out to these members of the community for their code contributions:\n"
      doc.concat contributors.sort_by { |k, _| k }.map { |c|
        "- #{c[0]}:\n#{c[1].map { |c| "  - #{c}\n" }.join}"
      }
      doc << "Total community contributions accepted: #{contributions}\n"
      doc << "## JIRA Tickets and Pull Requests Completed\n"
      doc.concat messages.uniq
      doc << "Total Pull Requests accepted: #{messages.uniq.count}"
    end

  end

end
