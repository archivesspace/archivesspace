class AssessmentsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show, :embedded_search],
                      "update_assessment_record" => [:new, :edit, :create, :update],
                      "delete_assessment_record" => [:delete]

  include ExportHelper

  def index
    respond_to do |format|
      format.html {
        @search_data = Search.for_type(session[:repo_id], "assessment", params_for_backend_search.merge({"facet[]" => SearchResultData.ASSESSMENT_FACETS}))
      }
      format.csv {
        search_params = params_for_backend_search.merge({"facet[]" => SearchResultData.ASSESSMENT_FACETS})
        search_params["type[]"] = "assessment"
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, Search.build_filters(search_params), "#{t('assessment._plural').downcase}." )
      }
    end
  end


  def current_record
    @assessment
  end


  def show
    @assessment = JSONModel(:assessment).find(params[:id], 'resolve[]' => ['surveyed_by', 'records', 'reviewer'])
    @assessment_attribute_definitions = AssessmentAttributeDefinitions.find(nil)
  end


  def new
    if params[:record_uri]
      uri_bits = JSONModel.parse_reference(params[:record_uri])
      record = JSONModel(uri_bits.fetch(:type)).find(uri_bits.fetch(:id))

      @assessment = JSONModel(:assessment).new({
        'records' => [{
          'ref' => params[:record_uri],
          '_resolved' => record
        }]
      })._always_valid!
    end

    @assessment ||= JSONModel(:assessment).new._always_valid!
    @assessment.survey_begin ||= Date.today.strftime('%Y-%m-%d')
    @assessment_attribute_definitions = AssessmentAttributeDefinitions.find(nil)
  end


  def edit
    @assessment = JSONModel(:assessment).find(params[:id], 'resolve[]' => ['surveyed_by', 'records', 'reviewer'])
    @assessment_attribute_definitions = AssessmentAttributeDefinitions.find(nil)
  end


  def create
    handle_crud(:instance => :assessment,
                :model => JSONModel(:assessment),
                :on_invalid => ->() {
                  @assessment_attribute_definitions = AssessmentAttributeDefinitions.find(nil)
                  render action: "new"
                },
                :on_valid => ->(id) {
                    flash[:success] = t("assessment._frontend.messages.created")
                    redirect_to(:controller => :assessments,
                                :action => :edit,
                                :id => id) })
  end


  def update
    handle_crud(:instance => :assessment,
                :model => JSONModel(:assessment),
                :obj => JSONModel(:assessment).find(params[:id]),
                :on_invalid => ->() {
                  @assessment_attribute_definitions = AssessmentAttributeDefinitions.find(nil)
                  @assessment.display_string = params[:id]
                  return render action: "edit"
                },
                :on_valid => ->(id) {
                  flash[:success] = t("assessment._frontend.messages.updated")
                  redirect_to :controller => :assessments, :action => :edit, :id => id
                })
  end


  def delete
    assessment = JSONModel(:assessment).find(params[:id])
    assessment.delete

    flash[:success] = t("assessment._frontend.messages.deleted")
    redirect_to(:controller => :assessments, :action => :index, :deleted_uri => assessment.uri)
  end


  def embedded_search
    @search_data = Search.all(session[:repo_id], params_for_backend_search.merge({'facet[]' => SearchResultData.ASSESSMENT_FACETS, 'type[]' => ['assessment']}))
    respond_to do |format|
      format.js {
        if params[:listing_only]
          render_aspace_partial :partial => "assessments/search_listing"
        else
          render_aspace_partial :partial => "search/results"
        end
      }
      format.html {
        # default render
      }
    end
  end


  private

  def cleanup_params_for_schema(params_hash, schema)
    if ASUtils.wrap(params_hash.dig('records', 'ref')).length > 0
      params_hash['records'] = ASUtils.wrap(params_hash['records']['ref']).zip(ASUtils.wrap(params_hash['records']['_resolved'])).map {|ref, resolved|
        {
          'ref' => ref,
          '_resolved' => resolved
        }
      }
    end

    if ASUtils.wrap(params_hash.dig('surveyed_by', 'ref')).length > 0
      params_hash['surveyed_by'] = ASUtils.wrap(params_hash['surveyed_by']['ref']).zip(ASUtils.wrap(params_hash['surveyed_by']['_resolved'])).map {|ref, resolved|
        {
          'ref' => ref,
          '_resolved' => resolved
        }
      }
    end

    if ASUtils.wrap(params_hash.dig('reviewer', 'ref')).length > 0
      params_hash['reviewer'] = ASUtils.wrap(params_hash['reviewer']['ref']).zip(ASUtils.wrap(params_hash['reviewer']['_resolved'])).map {|ref, resolved|
        {
          'ref' => ref,
          '_resolved' => resolved
        }
      }
    end

    # When the 'No Rating' radio is selected, Rails gives the radio a value of
    # `on`.  We change this 'on' value as 'No Rating' really means a `nil` value
    ASUtils.wrap(params_hash.dig('ratings')).each do |rating_params|
      rating_params.values.each do |rating|
        if rating['value'] == 'on'
          rating['value'] = nil
        end
      end
    end

    super
  end
end
