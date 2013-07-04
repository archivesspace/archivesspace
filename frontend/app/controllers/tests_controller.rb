class TestsController < ApplicationController

  set_access_control  :public => [:shutdown]


  def shutdown
    # Used to cleanly shutdown the devserver when running the coverage tests
    if ENV['COVERAGE_REPORTS'] == 'true'
      SimpleCov.result.format!
      exit!(0)
    end

    render :text => "No way"
  end
end
