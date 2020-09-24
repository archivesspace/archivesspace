# frozen_string_literal: true

module ReleaseNotes
  module GitLogParser
    ANW_MATCH = /([Aa][Nn][Ww][- ]\d+)(\s|\.|:)/.freeze
    PR_MATCH  = /#(\d+)\s/.freeze

    def self.run(path:, since:, target:)
      g = Git.open(path)
      log = []

      g.log(1_000_000).between(since, target).each do |commit|

        title, desc = commit.message.split("\n").delete_if(&:empty?).compact
        data = {}
        data[:pr_number] = title.match(PR_MATCH)[1] if commit.message =~ /^Merge pull request/
        data[:anw_number] = desc.match(ANW_MATCH)[1] if desc =~ ANW_MATCH
        data[:author] = commit.parents.last.author.name
        data[:date] = Date.parse(commit.date.to_s).to_s
        data[:desc] = desc || title
        log << data
      end
      log.sort_by { |l| l[:pr_number].to_i }
    end
  end

  class Generator
    attr_reader :contributors, :contributions, :doc, :log, :messages, :style, :version
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
    def initialize(version:, log:, style:)
      @contributors = {}
      @contributions = 0
      @doc = []
      @log = log
      @messages = []
      @style = style
      @version = version
    end

    def process
      log.each do |data|
        unless EXCLUDE_AUTHORS.include?(data[:author])
          contributors[data[:author]] = [] unless contributors.key? data[:author]
          contributors[data[:author]] << data[:desc]
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

    def format_log_entry(data)
      links = [pr_link(data[:pr_number]), anw_link(data[:anw_number])]
      msg = ''
      if style == 'brief'
        msg = "- PR: #{links.compact.join(' - ')}: #{data[:desc]}"
      elsif style == 'verbose'
        msg = "PR: #{links.compact.join(' - ')} "
        msg += "by #{data[:author]} accepted on #{data[:date]}\n"
        msg += "#{data[:desc]}\n"
      else
        raise "Invalid style: #{style}"
      end
      msg
    end

    def make_doc
      doc << "# Release notes for #{version}\n"
      doc << "__TODO: add release summary__\n"
      doc << "## Configurations and Migrations\n"
      doc << "__TODO: add config changes and migrations as denoted by PR labels__\n"
      doc << "## API Deprecations\n"
      doc << "The following API endpoints have been newly deprecated as part of
this release. For the time being, they will work and you may continue to
use them, however they will be removed from the core code of ArchivesSpace
on or after **#{DateTime.now.next_year(1).to_date}**.  For more information see
the [ArchivesSpace API documentation](https://archivesspace.github.io/archivesspace/api/).\n"
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
      doc.concat messages
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

  end
end
