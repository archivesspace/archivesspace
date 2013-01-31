require 'spec_helper'

describe 'Date model' do

  def create_date(opts = {})
    ASDate.create_from_json(build(:json_date, opts))
  end


  it "allows an expression date to created" do
    opts = {:expression => generate(:alphanumstr)}
    date = create_date(opts)

    ASDate[date[:id]].expression.should eq(opts[:expression])
  end


  it "throws a validation error if date begin is missing (applies to any date type)" do
    opts = {:begin => nil}

    5.times do
      json = build(:json_date, opts)
      expect { ASDate.create_from_json(json) }.to raise_error(JSONModel::ValidationException)
    end
  end


  it "allows a single date to be created" do
    opts = {:begin => generate(:yyyy_mm_dd), 
            :expression => generate(:alphanumstr)
            }

    date = create_date(opts)

    ASDate[date[:id]].begin.should eq(opts[:begin])
  end


  it "throws a validation error when a begin time is set but no end time is set" do
    opts = {:date_type => 'bulk',
            :begin_time => generate(:hh_mm), 
            :end_time => nil
            }

    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)
  end


  it "allows incomplete dates in compliance with ISO 8601" do
    opts = {:begin => '0123', :end => '0123'}
    expect { create_date(opts) }.to_not raise_error(JSONModel::ValidationException)

    opts = {:begin => '2012-12', :end => '2012-12'}
    expect { create_date(opts) }.to_not raise_error(JSONModel::ValidationException)
  end


  it "throws a validation error when begin is not a valid ISO Date" do
    opts = {:begin => '123', :end => '123'}
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

    opts = {:begin => '2012-13', :end => '2012-14'}
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)
    
    opts = {:begin => '2012-12-32', :end => '2012-12-32'}
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

    opts = {:begin => 'FOOBAR', :end => 'FOOBAR'}
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)
  end


  it "throws a validation error when begin time is not a valid ISO Date" do
    opts = {:begin_time => '12', :end_time => '12'}
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)
    
    opts = {:begin_time => '25:00', :end_time => '25:00'}
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

    opts = {:begin_time => '23:72', :end_time => '23:72'}
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

    opts = {:begin_time => '23:40:61', :end_time => '23:40:61'}
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

    opts = {:begin_time => '23:40:40', :end_time => '23:40:41'}
    date = create_date(opts)

    ASDate[date[:id]].begin_time.should eq("23:40:40")
    ASDate[date[:id]].end_time.should eq("23:40:41")
  end


  it "creates a bulk date with begin and end times" do
    opts = {:date_type => 'bulk',
            :begin_time => generate(:hh_mm), 
            :end_time => generate(:hh_mm)
            }
    
    expect { create_date(opts) }.to_not raise_error
  end


  it "reports an error if a bulk date lacks a begin date" do
    opts = {:date_type => 'bulk',
            :begin => nil, 
            }
            
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)
  end


  it "reports an error if a bulk date lacks an end date" do
    opts = {:date_type => 'bulk',
            :end => nil
            }
    
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)
  end


  it "reports an error if a bulk date has a begin time and lacks an end time" do
    opts = {:date_type => 'bulk',
            :begin_time => generate(:hh_mm), 
            :end_time => nil
            }
    
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)
  end


  it "reports an error if a bulk date has an end time and lacks a begin time" do
    opts = {:date_type => 'bulk',
            :begin_time => nil, 
            :end_time => generate(:hh_mm)
            }
    
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)
  end


  it "ensures end is not before begin" do
    # ok if begin and end are the same
    opts = {:date_type => 'bulk', :begin => "2000-01-01", :end => "2000-01-01"}
    expect { create_date(opts) }.to_not raise_error

    # not ok if end if before begin
    opts = {:date_type => 'inclusive', :begin => "2000-01-01", :end => "1999-12-31"}
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

    # even if it's really close
    opts = {:date_type => 'bulk',
            :begin => "2000-01-01", "begin_time" => "00:00:00",
              :end => "1999-12-31",   "end_time" => "23:59:59"}
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

    # and even if they look almost the same
    opts = {:date_type => 'inclusive',
            :begin => "2000-01-01", "begin_time" => "00:00:01",
              :end => "2000-01-01",   "end_time" => "00:00:00"}
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

    # and even if the dates are incomplete
    opts = {:date_type => 'bulk', :begin => "2000", :end => "1999"}
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

    # and at different levels of specificity
    opts = {:date_type => 'inclusive', :begin => "2000", :end => "1999-12"}
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

    # end time defaults to '23:59:59'
    opts = {:date_type => 'bulk',
            :begin => "2000-01-01", "begin_time" => "00:00:01",
              :end => "2000-01-01"}
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

  end


  it "reports an error if no expression or date type is set" do

    opts = {:date_type => nil,
            :begin_time => nil,
            :end_time => nil,
            :expression => nil
    }

    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)
  end


  it "allows a date to be created with an expression but no date type" do

    opts = {:date_type => nil,
            :expression => "My Birthday"
    }

    date = create_date(opts)

    ASDate[date[:id]].expression.should eq(opts[:expression])
  end
end
