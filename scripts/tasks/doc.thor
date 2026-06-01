require 'logger'
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
  option :gh_user, :required => false, :default => "archivesspace"

  def release_notes
    notes = ReleaseNotes.generate(
      current_tag: options[:current_tag],
      previous_tag: options[:previous_tag],
      token: options[:token],
      gh_user: options[:gh_user]
    )

    if options[:out]
      File.write(File.join(Dir.pwd, options[:out]), "#{notes}\n")
    else
      $stderr.puts notes
    end
  end
end
