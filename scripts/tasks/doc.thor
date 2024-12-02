require 'thor'
require_relative 'release_notes'

class Doc < Thor

  desc "api", "generate docs/slate/source/index.html.md"
  def api
    begin
      Dir.chdir("backend")
      require_relative '../../docs/api_doc.rb'
      Dir.chdir("..")
    rescue Exception => e
      puts e.inspect
      puts e.backtrace
      raise e
    end

    ApiDoc.generate_markdown_for_slate
  end

  desc "release_notes", "generate release notes"
  option :token, :required => false
  option :current_tag, :required => true
  option :previous_tag, :required => false
  option :out, :required => false
  option :max_pr_pages, :required => false, :default => 20, type: :numeric
  option :gh_user, :required => false, :default => "archivesspace"
  def release_notes
    current_tag = options[:current_tag]
    previous_tag = options[:previous_tag] || ReleaseNotes.find_previous_tag(current_tag)
    out = if options[:out]
            File.open(File.join(Dir.pwd, '/', options[:out]), 'w')
          else
            $stderr
          end
    github = github = Github.new do |config|
      if options[:token]
        config.connection_options = {headers: {"authorization" => "Bearer #{options[:token]}"}}
      end
      config.user = options[:gh_user]
      config.repo = "archivesspace"
    end

    git = Git.open('./')
    log = ReleaseNotes.parse_log(git.log.max_count(:all).between(previous_tag, current_tag))

    puts "Found #{log.count} commit(s) between #{previous_tag} and #{current_tag}"

    log.reject! { |log_entry| log_entry[:desc].match(/^Merge pull request/) }
    pulls_page = 1

    while ((log.select { |log_entry| log_entry[:pr_number].nil? }.size > 0) && (pulls_page < options[:max_pr_pages] + 1)) do
      pulls = []
      puts "Fetch pulls page #{pulls_page}"
      pulls = github.pulls.all(state: "closed", page: pulls_page)

      break if pulls.count == 0

      pulls.each do |pull|
        pull[:commits] = github.pulls.commits(number: pull[:number])
        puts "Found #{pull[:commits].count} commit(s) in PR: #{pull[:number]}"
      end

      log.each do |log_entry|
        next if log_entry[:pr_number]
        pr = pulls.select { |pull| pull[:commits].map { |c| c["sha"]}.include?(log_entry[:sha])}.first
        if pr
          log_entry[:pr_number] = pr["number"]
          log_entry[:pr_title] = pr["title"]
        end
      end
      pulls_page = pulls_page + 1
    end

    # for squash commits, try to get the PR id from the message string
    orphans = log.select {|l| l[:pr_number].nil? }
    orphans.each do |log_entry|
      match = log_entry[:desc].match /\(#(\d+)\)$/
      if match
        log_entry[:pr_number] = match[1].to_i
        log_entry[:pr_title] = log_entry[:desc]
      end
    end

    generator = ReleaseNotes::Generator.new(
      current_tag: current_tag,
      log: log,
      previous_tag: previous_tag,
      style: "brief"
    )
    out << generator.process.to_s
    out << "\n"
    out.close
  end
end
