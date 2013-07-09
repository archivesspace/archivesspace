class ReportsController < ApplicationController

  set_access_control  "view_repository" => [:index, :download]


  def index
    @report_data = JSONModel::HTTP::get_json("/reports")
    @report_params = {}
  end

  def download
    @report_data = JSONModel::HTTP::get_json("/reports")
    report = @report_data['reports'][params['report_key']]

    @report_params = params['report_params']

    queue = Queue.new

    Thread.new do
      begin
        JSONModel::HTTP::stream("/repositories/#{session[:repo_id]}/reports/#{report['uri_suffix']}", @report_params) do |report_response|
          response.headers['Content-Disposition'] = report_response['Content-Disposition']
          response.headers['Content-Type'] = report_response['Content-Type']
          queue << :ok
          report_response.read_body do |chunk|
            queue << chunk
          end
        end
      rescue
        queue << {:error => ASUtils.json_parse($!.message)}
      ensure
        queue << :EOF
      end

    end

    first_on_queue = queue.pop
    if first_on_queue.kind_of?(Hash)
      @report_errors = first_on_queue[:error]
      @report = report
      return render :action => :index
    end

    self.response_body = Class.new do
      def self.queue=(queue)
        @queue = queue
      end
      def self.each(&block)
        while(true)
          elt = @queue.pop
          break if elt === :EOF
          block.call(elt)
        end
      end
    end

    self.response_body.queue = queue
  end

end
