require 'thor'
require_relative 'release_notes'

def gh_client(token)
  github = Github.new do |config|
    config.basic_auth = token unless token.nil?
    config.user = "archivesspace"
    config.repo = "archivesspace"
  end
  github
end

class Doc < Thor

  desc "api", "generate docs/slate/source/index.html.md"
  def api
    begin
      require_relative '../../docs/api_doc.rb'
    rescue Exception => e
      puts e.inspect
      puts e.backtrace
      raise e
    end
    ApiDoc.generate_markdown_for_slate
  end

  desc "release_notes", "generate release notes"
  option :token, :required => true
  option :current_tag, :required => true
  option :previous_tag, :required => false
  option :out, :required => false
  option :max_pr_pages, :required => false, :default => 20, type: :numeric
  def release_notes
    current_tag = options[:current_tag]
    previous_tag = options[:previous_tag] || ReleaseNotes.find_previous_tag(current_tag)
    out = if options[:out]
            File.open(File.join(Dir.pwd, '/', options[:out]), 'w')
          else
            $stderr
          end
    github = gh_client(options[:token])
    git = Git.open('./')
    log = git.log('a').between(previous_tag, current_tag).map do |log_entry|
      {
        author: log_entry.author.name,
        desc: log_entry.message.split("\n")[0],
        sha: log_entry.sha
      }
    end

    log.reject! { |log_entry| log_entry[:desc].match(/^Merge pull request/) }
    pulls_page = 1
    while((log.select { |log_entry| log_entry[:pr_number].nil? }.size > 0) && (pulls_page < options[:max_pr_pages] + 1)) do
      pulls = []
      puts "Fetch pulls page #{pulls_page}"
      pulls = github.pulls.all(state: "closed", page: pulls_page)
      pulls.each do |pull|
        pull[:commits] = github.pulls.commits(number: pull[:number])
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
    generator = ReleaseNotes::Generator.new(
      current_tag: current_tag,
      log: log,
      previous_tag: previous_tag,
      style: "brief"
    )
    out << generator.process.to_s
    out.close
  end
end
