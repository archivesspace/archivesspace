class UtilsController  < ApplicationController

  set_access_control  :public => [:generate_sequence]


  def generate_sequence
    render :json => SequenceGenerator.from_params(params)
  end

end