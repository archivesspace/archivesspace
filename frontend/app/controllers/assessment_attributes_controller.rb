class AssessmentAttributesController < ApplicationController

  set_access_control  "manage_assessment_attributes" => [:edit, :update]


  def edit
    @assessment_attribute_definitions = AssessmentAttributeDefinitions.find(nil)
  end

  def update
    @assessment_attribute_definitions = AssessmentAttributeDefinitions.find(nil)

    original_repo_formats = @assessment_attribute_definitions.repo_formats
    original_repo_ratings = @assessment_attribute_definitions.repo_ratings
    original_repo_conservation_issues = @assessment_attribute_definitions.repo_conservation_issues

    @assessment_attribute_definitions.repo_formats = prepare(params[:formats])
    @assessment_attribute_definitions.repo_ratings = prepare(params[:ratings])
    @assessment_attribute_definitions.repo_conservation_issues = prepare(params[:conservation_issues])

    begin
      @assessment_attribute_definitions.save
      @assessment_attribute_definitions = AssessmentAttributeDefinitions.find(nil)
      flash.now[:success] = I18n.t('assessment_attribute_definitions._frontend.messages.updated')
    rescue ConflictException => e
      if "RECORD_IN_USE" == e.conflicts
        flash.now[:error] = I18n.t('assessment_attribute_definitions._frontend.messages.attribute_in_use')

        # Add back anything that was deleted
        @assessment_attribute_definitions.repo_formats += (original_repo_formats - @assessment_attribute_definitions.repo_formats)
        @assessment_attribute_definitions.repo_ratings += (original_repo_ratings - @assessment_attribute_definitions.repo_ratings)
        @assessment_attribute_definitions.repo_conservation_issues += (original_repo_conservation_issues - @assessment_attribute_definitions.repo_conservation_issues)
      else
        flash.now[:error] = I18n.t('assessment_attribute_definitions._frontend.messages.conflict',
                                   :conflicts => e.conflicts.join('; '))
      end
    end

    render :template => 'assessment_attributes/edit'
  end

  private

  def prepare(attributes)
    result = ASUtils.wrap(attributes).reject {|entry| entry['label'].blank?}

    result.each do |attribute|
      if attribute['id'] == ''
        attribute.delete('id')
      end
    end
  end

end