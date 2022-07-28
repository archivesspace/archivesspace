require 'bundler'
Bundler.require

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
end
