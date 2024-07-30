class BulkArchivalObjectUpdaterController < ApplicationController
  set_access_control "view_repository" => [:download_form, :download]

  def download_form
    @uri = params[:resource]
    @tree = escape_xml_characters(load_tree)
  end

  def download
    uri = "/bulk_archival_object_updater/repositories/#{session[:repo_id]}/generate_spreadsheet"
    args = {
      'uri[]' => JSON.parse(params[:selected]),
      'resource_uri' => params[:resource],
      'min_subrecords' => params[:min_subrecords],
      'extra_subrecords' => params[:extra_subrecords],
      'min_notes' => params[:min_notes],
      'selected_columns[]' => params.to_unsafe_hash.map {|param, value|
        if param.to_s =~ /\Aupdate_select_(.*)/ && value == 'on'
          $1
        end
      }.compact
    }

    generate_spreadsheet(uri, args)
  end

  private

  def generate_spreadsheet(uri, args)
    queue = Queue.new

    backend_session = JSONModel::HTTP::current_backend_session

    # TBD: This should be probably be removed. There is no reason to wrap it in a thread.
    Thread.new do
      JSONModel::HTTP::current_backend_session = backend_session
      begin
        post_with_stream_response(uri, args) do |spreadsheet_response|
          response.headers['Content-Disposition'] = spreadsheet_response['Content-Disposition']
          response.headers['Content-Type'] = spreadsheet_response['Content-Type']
          response.headers['Last-Modified'] = Time.now.to_s
          response.headers['Cache-Control'] = 'no-cache'
          response.headers['X-Content-Type-Options'] = 'nosniff'

          queue << :ok
          spreadsheet_response.read_body do |chunk|
            queue << chunk unless chunk.empty?
          end
        end
      rescue
        queue << {:error => $!.message}
      ensure
        queue << :EOF
      end
    end

    first_on_queue = queue.pop # :ok or error hash
    if first_on_queue.is_a?(Hash)
      @spreadsheet_errors = first_on_queue[:error]

      @uri = params[:resource]
      @tree = escape_xml_characters(load_tree)

      return render :action => :download_form
    end

    self.response_body = Class.new do
      def self.queue=(queue)
        @queue = queue
      end

      def self.each(&block)
        while (true)
          chunk = @queue.pop

          break if chunk === :EOF

          block.call(chunk)
        end
      end
    end

    self.response_body.queue = queue
  end


  def escape_xml_characters(tree)
    result = tree.merge('title' => CGI.escapeHTML(tree['title']))

    if tree['children']
      result.merge('children' => tree['children'].map {|child| escape_xml_characters(child)})
    else
      result
    end
  end


  def load_tree
    JSONModel::HTTP::get_json("/bulk_archival_object_updater#{@uri}/small_tree")
  end


  def post_with_stream_response(uri, params = {}, &block)
    uri = URI("#{ JSONModel::backend_url}#{uri}")

    req = Net::HTTP::Post.new(uri.request_uri)
    req.body = URI.encode_www_form(params)

    req['X-ArchivesSpace-Session'] = JSONModel::HTTP::current_backend_session

    Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(req, nil) do |response|
        if response.code =~ /^4/
          #JSONModel::handle_error(ASUtils.json_parse(response.body))
          raise response.body
        end

        block.call(response)
      end
    end
  end

end
