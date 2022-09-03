class AssessmentAttributesController < ApplicationController

  set_access_control "manage_assessment_attributes" => [:edit, :update]


  def edit
    @assessment_attribute_definitions = AssessmentAttributeDefinitions.find(nil)
  end

  def current_record
    @assessment_attribute_definitions
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
      flash.now[:success] = t('assessment_attribute_definitions._frontend.messages.updated')
    rescue ConflictException => e
      if "RECORD_IN_USE" == e.conflicts
        flash.now[:error] = t('assessment_attribute_definitions._frontend.messages.attribute_in_use')

        # Add back anything that was deleted
        @assessment_attribute_definitions.repo_formats = revert_deletions(@assessment_attribute_definitions.repo_formats, original_repo_formats)
        @assessment_attribute_definitions.repo_ratings = revert_deletions(@assessment_attribute_definitions.repo_ratings, original_repo_ratings)
        @assessment_attribute_definitions.repo_conservation_issues = revert_deletions(@assessment_attribute_definitions.repo_conservation_issues, original_repo_conservation_issues)
      else
        flash.now[:error] = t('assessment_attribute_definitions._frontend.messages.conflict',
                                   :conflicts => e.conflicts.join('; '))
      end
    end

    render :template => 'assessment_attributes/edit'
  end

  private

  # Revert any deleted definitions and restore the original sorting
  def revert_deletions(form_definitions, original_definitions)
    form_definitions += attribute_set_subtract(original_definitions, form_definitions)
    form_definitions.sort {|a, b| a['position'] <=> b['position']}
  end

  # Return only the attributes of `a1` that aren't present in `a2`
  #
  # Comparison is against the 'id' fields
  def attribute_set_subtract(a1, a2)
    a2_ids = a2.map {|a| a['id']}.compact

    a1.select {|a| a['id'] && !a2_ids.include?(a['id'])}
  end

  def prepare(attributes)
    result = ASUtils.wrap(attributes).reject {|entry| entry['label'].blank?}

    result.each do |attribute|
      if attribute['id'] == ''
        attribute.delete('id')
      end
    end
  end

end
