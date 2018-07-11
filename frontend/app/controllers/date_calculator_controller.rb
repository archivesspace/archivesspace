class DateCalculatorController < ApplicationController

  set_access_control  "view_repository" => [:calculate],
                      "update_resource_record" => [:create_date]

  def calculate
    if params['record_uri']
      calculator_params = {
        'record_uri' => params['record_uri'],
        'label' => params['label'].blank? ? nil : params['label']
      }

      results = JSONModel::HTTP::get_json("/date_calculator", calculator_params)

      if results['min_begin'] == results['max_end'] || results['max_end'].nil?
        date_type = 'single'
      else
        date_type = 'inclusive'
      end

      date = {
        'jsonmodel_type' => 'date',
        'date_type' => date_type,
        'label' => results['label'] || 'creation',
        'begin' => results['min_begin'],
        'end' => date_type == 'inclusive' ? results['max_end'] : nil
      }

      render_aspace_partial :partial => "date_calculator/results", :locals => {:results => results, :date => date}
    else
      render_aspace_partial :partial => "date_calculator/no_object"
    end

  end


  def create_date
    begin
      date = JSONModel(:date).from_hash(params[:date].to_hash)

      record = JSONModel(params[:record_type].intern).find(params[:record_id])

      record.dates ||= []
      record.dates << date
      record.save

      render :text => 'success'
    rescue ValidationException => e
      render :json => e.errors, :status => 400
    end
  end

end

