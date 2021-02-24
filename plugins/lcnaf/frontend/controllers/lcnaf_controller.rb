require 'opensearcher'
require 'securerandom'

class LcnafController < ApplicationController

  set_access_control "update_agent_record" => [:search, :index, :import]

  def index
    @page = 1
    @records_per_page = 10

    flash.now[:info] = I18n.t("plugins.lcnaf.messages.service_warning")
  end


  def search
    results = do_search(params)

    render :json => results.to_json
  end


  def import
    marcxml_file = searcher.results_to_marcxml_file(params[:lccn])
    is_subject = is_subject_record?(marcxml_file)

    begin
      # agents are processed by MarcXMLAuthAgentConverter introduced in ANW-429
      if params[:lcnaf_service] == "lcnaf" && !is_subject
        job = Job.new("import_job", {
                        "import_type" => "marcxml_auth_agent",
                        "jsonmodel_type" => "import_job"
                        },
                      {"lcnaf_import_#{SecureRandom.uuid}" => marcxml_file})

      # subjects are processed by MarcXMLBibConverter as before ANW-429
      else 
       job = Job.new("import_job", {
                        "import_type" => "marcxml_subjects_and_agents",
                        "jsonmodel_type" => "import_job"
                        },
                      {"lcnaf_import_#{SecureRandom.uuid}" => marcxml_file})
      end

      response = job.upload
      render :json => {'job_uri' => url_for(:controller => :jobs, :action => :show, :id => response['id'])}
    rescue
      render :json => {'error' => $!.to_s}
    end
  end


  private

  def do_search(params)
    searcher.search(params[:family_name], params[:page].to_i, params[:records_per_page].to_i)
  end


  def searcher
    case params[:lcnaf_service]
    when  'lcnaf'
      OpenSearcher.new('https://id.loc.gov/search/', 'http://id.loc.gov/authorities/names')
    when 'lcsh'
      OpenSearcher.new('https://id.loc.gov/search/', 'http://id.loc.gov/authorities/subjects')
    end
  end

  def is_subject_record?(tempfile)
    doc = Nokogiri::XML::Document.parse(IO.read(tempfile))
    doc.remove_namespaces!
    is_subject_record = false

    subject_tags = ["630", "130", "650", "150", "651", "151", "655", "155", "656", "657", "690", "691", "692", "693", "694", "695", "696", "697", "698", "699"]


    subject_tags.each do |tag|
      if doc.search("//datafield[@tag='#{tag}']").length > 0
        is_subject_record = true
        break
      end
    end

    is_subject_record
  end
end
