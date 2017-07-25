class AssessmentAttributesController < ApplicationController

  set_access_control  "manage_repository" => [:edit, :update]


  def edit
    @assessment_attribute_definitions = AssessmentAttributeDefinitions.find(nil)
  end

  def update
    # FIXME add real form paths
    @assessment_attribute_definitions = AssessmentAttributeDefinitions.find(nil)
    @assessment_attribute_definitions.repo_formats = ASUtils.wrap(params[:formats])
    @assessment_attribute_definitions.repo_ratings = ASUtils.wrap(params[:ratings])
    @assessment_attribute_definitions.repo_conservation_issues = ASUtils.wrap(params[:conservation_issues])

    begin
      @assessment_attribute_definitions.save
      @assessment_attribute_definitions = AssessmentAttributeDefinitions.find(nil)
      flash.now[:success] = I18n.t('assessment_attribute_definitions._frontend.messages.updated')
    rescue
      flash.now[:error] = I18n.t('assessment_attribute_definitions._frontend.messages.error')
      raise $!.inspect # FIXME add real validation handling
    end

    render :template => 'assessment_attributes/edit'
  end
end