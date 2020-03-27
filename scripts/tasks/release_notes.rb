# frozen_string_literal: true

module ReleaseNotes
  module GitLogParser
    ANW_MATCH = /(ANW-\d+)(\s|\.|:)/.freeze
    PR_MATCH  = /#(\d+)\s/.freeze

    def self.run(path:, since:, target:)
      g = Git.open(path)
      log = []

      g.log(1_000_000).between(since, target).each do |commit|
        next unless commit.message =~ /^Merge pull request/

        title, desc = commit.message.split("\n").delete_if(&:empty?).compact
        data = {}
        data[:pr_number] = title.match(PR_MATCH)[1]
        data[:anw_number] = desc.match(ANW_MATCH)[1] if desc =~ ANW_MATCH
        data[:author] = commit.parents.last.author.name
        data[:date] = Date.parse(commit.date.to_s).to_s
        data[:desc] = desc
        log << data
      end
      log
    end
  end

  class Generator
    attr_reader :contributors, :contributions, :doc, :log, :messages, :version
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
    def initialize(version:, log:)
      @contributors = Hash.new(0)
      @contributions = 0
      @doc = []
      @log = log
      @messages = []
      @version = version
    end

    def process
      log.each do |data|
        contributors[data[:author]] += 1 unless EXCLUDE_AUTHORS.include?(data[:author])
        messages << format_log_entry(data)
      end
      @contributions = contributors.values.reduce(:+)
      make_doc
      self
    end

    def to_s
      doc.join("\n")
    end

    private

    def anw_link(anw_number)
      return nil unless anw_number

      "[#{anw_number}](#{ANW_URL}/#{anw_number})"
    end

    def format_log_entry(data)
      links = [pr_link(data[:pr_number]), anw_link(data[:anw_number])]
      msg = "PR: #{links.compact.join(' - ')} "
      msg += "by #{data[:author]} accepted on #{data[:date]}\n"
      msg += "#{data[:desc]}\n"
      msg
    end

    def make_doc
      doc << "# Release notes for #{version}\n"
      doc << "__TODO: add release summary__\n"
      doc << "## Community Contributions\n"
      doc << "Our thanks go out to these members of the community for their code contributions: \n"
      doc.concat contributors.sort_by { |k, _| k }.map { |c| "- #{c[0]}: #{c[1]}" }
      doc << ''
      doc << "Total community contributions accepted: #{contributions}\n"
      doc << "## JIRA Tickets and Pull Requests Completed\n"
      doc.concat messages
    end

    def pr_link(pr_number)
      return nil unless pr_number

      "[#{pr_number}](#{PR_URL}/#{pr_number})"
    end
  end
end
