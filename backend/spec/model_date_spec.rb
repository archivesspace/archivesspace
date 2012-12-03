require 'spec_helper'

describe 'Date model' do

  def create_date(opts = {})
    ASDate.create_from_json(build(:json_date, opts))
  end


  it "Allows an expression date to created" do

    opts = {:expression => generate(:alphanumstr)}

    date = create_date(opts)

    ASDate[date[:id]].expression.should eq(opts[:expression])
  end


  it "Throws a validation error if no expression or begin date is set" do

    opts = {:expression => nil, :begin => nil}

    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)
  end


  it "Allows a single date to be created" do
    
    opts = {:begin => generate(:yyyy_mm_dd), 
            :expression => generate(:alphanumstr)
            }

    date = create_date(opts)

    ASDate[date[:id]].begin.should eq(opts[:begin])
  end


  it "Throws a validation error when a begin time is set but no end time is set" do

    opts = {:date_type => 'bulk',
            :begin_time => generate(:hh_mm), 
            :end_time => nil
            }

    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)
  end


  it "Throws a validation error when begin is not a valid ISO Date" do

    opts = {:begin => '123', :end => '123'}

    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

    opts = {:begin => '2012-13', :end => '2012-14'}

    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)
    
    opts = {:begin => '2012-12-32', :end => '2012-12-32'}

    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

    opts = {:begin => 'FOOBAR', :end => 'FOOBAR'}

    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)
  end


  it "Throws a validation error when begin time is not a valid ISO Date" do

    opts = {:begin_time => '12', :end_time => '12'}

    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)
    
    opts = {:begin_time => '25:00', :end_time => '25:00'}

    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

    opts = {:begin_time => '23:72', :end_time => '23:72'}

    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

    opts = {:begin_time => '23:40:61', :end_time => '23:40:61'}

    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

    opts = {:begin_time => '23:40:40', :end_time => '03:01:00'}

    date = create_date(opts)

    ASDate[date[:id]].begin_time.should eq("23:40:40")
    ASDate[date[:id]].end_time.should eq("03:01:00")
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
