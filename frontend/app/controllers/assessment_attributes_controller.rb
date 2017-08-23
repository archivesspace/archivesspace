class AssessmentAttributesController < ApplicationController

  set_access_control  "manage_assessment_attributes" => [:edit, :update]


  def edit
    @assessment_attribute_definitions = AssessmentAttributeDefinitions.find(nil)
  end

  def update
    @assessment_attribute_definitions = AssessmentAttributeDefinitions.find(nil)
    @assessment_attribute_definitions.repo_formats = ASUtils.wrap(params[:formats]).reject {|entry| entry['label'].blank?}
    @assessment_attribute_definitions.repo_ratings = ASUtils.wrap(params[:ratings]).reject {|entry| entry['label'].blank?}
    @assessment_attribute_definitions.repo_conservation_issues = ASUtils.wrap(params[:conservation_issues].reject {|entry| entry['label'].blank?})

    begin
      @assessment_attribute_definitions.save
      @assessment_attribute_definitions = AssessmentAttributeDefinitions.find(nil)
      flash.now[:success] = I18n.t('assessment_attribute_definitions._frontend.messages.updated')
    rescue ConflictException => e
      flash.now[:error] = I18n.t('assessment_attribute_definitions._frontend.messages.conflict',
                                 :conflicts => e.conflicts.join('; '))
    end

    render :template => 'assessment_attributes/edit'
  end
end