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


  it "throws a validation error if date type is missing" do
    opts = {:date_type => nil}

    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)
  end


  it "allows incomplete dates in compliance with ISO 8601" do
    opts = {:begin => '0123', :end => '0123'}
    expect { create_date(opts) }.to_not raise_error

    opts = {:begin => '2012-12', :end => '2012-12'}
    expect { create_date(opts) }.to_not raise_error
  end


  it "BC?  NP!" do
    expect { create_date(:begin => '-0100-01-01', :end => '-0050-01-01') }.to_not raise_error
    expect { create_date(:begin => '1996-01-01', :end => '-0050-01-01', :date_type => 'inclusive') }.to raise_error(JSONModel::ValidationException)
  end


  it "throws a validation error when begin is not a valid ISO Date" do
    opts = {:begin => '2012-13', :end => '2012-14'}
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

    opts = {:begin => '2012-12-32', :end => '2012-12-32'}
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

    opts = {:begin => 'FOOBAR', :end => 'FOOBAR'}
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)
  end


  it "ensures end is not before begin" do
    # ok if begin and end are the same
    opts = {:begin => "2000-01-01", :end => "2000-01-01"}
    expect { create_date(opts) }.to_not raise_error

    # not ok if end is before begin
    opts = {:begin => "2000-01-01", :end => "1999-12-31"}
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

    # and even if the dates are incomplete
    opts = {:begin => "2000", :end => "1999"}
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

    # and at different levels of specificity
    opts = {:begin => "2000", :end => "1999-12"}
    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)

    # and at different levels of specificity in the same year
    opts = {:begin => "1999", :end => "1999-12"}
    expect { create_date(opts) }.to_not raise_error

    # and at different levels of specificity in the same month
    opts = {:begin => "1999-12-01", :end => "1999-12"}
    expect { create_date(opts) }.to_not raise_error
  end


  it "reports an error if no expression, begin, or end is set" do

    opts = {:begin => nil,
            :end => nil,
            :expression => nil
    }

    expect { create_date(opts) }.to raise_error(JSONModel::ValidationException)
  end

end
