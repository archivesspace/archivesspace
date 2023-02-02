require 'git'
require 'github_api'

module ReleaseNotes

  def self.find_previous_tag(current_tag)
    current_tag = current_tag.sub(/-RC\d+$/, '')
    git = Git.open('./')
    vtags = git.tags.reject {|t| t.name !~ /^v\d\.\d\.\d(-RC\d)?$/}
    matched = false
    vtags.sort_by {|v| v.name}.map {|v| v.name}.reverse.each do |tag|
      return tag if matched
      matched = (tag.sub(/-RC\d+$/, '') == current_tag)
    end
  end

  class Generator
    attr_reader :contributors, :contributions, :doc, :log, :messages, :previous_tag, :style, :current_tag, :migrations
    ANW_URL = 'https://archivesspace.atlassian.net/browse'
    PR_URL  = 'https://github.com/archivesspace/archivesspace/pull'
    EXCLUDE_AUTHORS = [
      'Christine Di Bella',
      'Jessica Crouch',
      'Brian Hoffman',
      'Mark Cooper',
      'Brian Zelip',
      'Donald Smith',
      'dependabot[bot]'
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
      relevant_changes = all_changes.select{ |_,d| d == 'A'}
      @migrations.count = relevant_changes.count
      @migrations.schema_version = (@migrations.count>0) ? relevant_changes.to_a.last.map { |m| m[/\d+/] }.first : "UNCHANGED"
    end

    def process
      log.each do |data|
        add_jira_id(data)
        if data[:pr_number]
          messages << format_log_entry(data)
        end
        next if EXCLUDE_AUTHORS.include?(data[:author])
        next if data[:pr_number].nil?
        @contributions += 1
        contributors[data[:author]] ||= []
        contributors[data[:author]] << data[:pr_title]
      end
      make_doc
      self
    end

    def to_s
      doc.join("\n")
    end

    private

    def add_jira_id(data)
      if (data[:desc].match(/(ANW-\d+)/) || data[:pr_title]&.match(/(ANW-\d+)/))
        data[:anw_number] = $1
      end
    end

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
        msg = "- PR: #{links.compact.join(' - ')}: #{data[:pr_title]}"
      elsif style == 'verbose'
        msg = "PR: #{links.compact.join(' - ')} "
        msg += "by #{data[:author]} accepted on #{data[:date]}\n"
        msg += "#{data[:title]}\n"
      else
        raise "Invalid style: #{style}"
      end
      msg
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

    def make_doc
      doc << "# Release notes for #{current_tag}\n"
      doc << "__TODO: add release summary__\n"
      doc << "## Configurations and Migrations\n"
      doc << "This release includes several modifications to the configuration defaults file: \n"
      doc << config_changes
      doc << "This release includes #{migrations.count} new database migrations. The schema number for this release is #{migrations.schema_version}.\n"
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
