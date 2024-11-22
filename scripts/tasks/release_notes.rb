require 'git'
require 'github_api'

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


  def self.parse_log(gitlog)
    gitlog.map do |log_entry|
      authors = [log_entry.author.name]
      authors += log_entry.message.split(/\n+/)
                   .select { |line| line =~ /^Co-authored-by/ }
                   .map { |line| line.sub(/^.*by:\s+/, '').sub(/ <.*@.*>$/, '') }
      {
        authors: authors,
        desc: log_entry.message.split("\n")[0],
        sha: log_entry.sha
      }
    end
  end

  class Generator
    attr_reader :contributors, :contributions, :doc, :log, :messages, :previous_tag, :style, :current_tag, :migrations

    ANW_URL = 'https://archivesspace.atlassian.net/browse'
    PR_URL  = 'https://github.com/archivesspace/archivesspace/pull'
    EXCLUDE_AUTHORS = [
      'Christine Di Bella',
      'Jessica Crouch',
      'Thimios Dimopulos',
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
          @contributions += 1
          contributors[author] ||= []
          contributors[author] << (data[:pr_title] || data[:desc])
        end

      end

      contributors.each do |author, contributions|
        contributions.uniq!
      end
      make_doc
      self
    end

    def to_s
      doc.join("\n")
    end

    private

    def pr_count
      log.map {|l| l[:pr_number]}.compact!.uniq.count
    end

    def ticket_count
      log.map {|l| l[:anw_number]}.compact!.uniq.count
    end

    def add_jira_id(data)
      if (data[:desc].match(/(ANW-\d+)/) || data[:pr_title]&.match(/(ANW-\d+)/))
        data[:anw_number] = $1
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
        msg = "- PR: #{links.compact.join(' - ')}: #{data[:pr_title]}"
      elsif style == 'verbose'
        msg = "PR: #{links.compact.join(' - ')} "
        msg += "by #{data[:authors].join(', ')} accepted on #{data[:date]}\n"
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
      doc.concat contributors.sort_by { |k, _| k }.map { |c|
        "- #{c[0]}:\n#{c[1].map { |c| "  - #{c}\n" }.join}"
      }
      doc << "Total community contributions accepted: #{contributions}\n"
      doc << "## JIRA Tickets and Pull Requests Completed\n"
      doc.concat messages.uniq

      doc << "\nTotal Pull Requests accepted: #{pr_count}"
      doc << "Total Jira Tickets closed: #{ticket_count}"
    end

  end

end
