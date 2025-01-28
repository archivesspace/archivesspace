require 'spec_helper'
require_relative 'factories'

describe 'Date Calculator model' do

  def create_tree(opts = {})
    resource = create_resource(opts.fetch(:resource_properties, {}))

    grandparent = create(:json_archival_object,
                         {
                           :dates => [],
                           :resource => {"ref" => resource.uri},
                           :level => "series", :component_id => SecureRandom.hex
                         }.merge(opts.fetch(:grandparent_properties, {})))

    parent = create(:json_archival_object,
                    {
                      :dates => [],
                      :resource => {"ref" => resource.uri},
                      :parent => {"ref" => grandparent.uri}
                    }.merge(opts.fetch(:parent_properties, {})))

    child = create(:json_archival_object,
                   {
                     :dates => [],
                     :resource => {"ref" => resource.uri},
                     :parent => {"ref" => parent.uri},
                   }.merge(opts.fetch(:child_properties, {})))

    [
      resource,
      ArchivalObject[grandparent.id],
      ArchivalObject[parent.id],
      ArchivalObject[child.id]
    ]
  end

  it "can calculate the date range for a resource all date types" do
    (resource, _, _, _) = create_tree({
      :resource_properties => {
        :dates => [build(:json_date, :label => 'existence', :begin => '1990-01-01', :end => '2000-05-02')]
      }
    })

    calculator = DateCalculator.new(resource)
    expect(calculator.min_begin).to be_nil
    expect(calculator.max_end).to be_nil
  end

  it "can accept dates without leading zeros" do
    (resource, grandparent, _, _) = create_tree({
                                        :resource_properties => {
                                          :dates => [build(:json_date, :label => 'existence', :begin => '1990-1-1', :end => '2000-5-2')]
                                        },
                                        :grandparent_properties => {
                                          :dates => [build(:json_date, :label => 'existence', :begin => '1990-1-1', :end => '2000-5-2')]
                                        }
                                      })

    calculator = DateCalculator.new(resource)
    expect(calculator.min_begin).to eq('1990-1-1')
    expect(calculator.max_end).to eq('2000-5-2')
  end


  it "can calculate the date range for a resource, all date types and a bunch of dates" do
    (resource, _, _, _) = create_tree({
                                         :resource_properties => {
                                           :dates => [
                                            build(:json_date, :label => 'existence', :begin => '1990-01-01', :end => '2000-05-02'),
                                            build(:json_date, :label => 'creation', :begin => '1989-05-22', :end => nil)]
                                         },
                                         :grandparent_properties => {
                                           :dates => [
                                             build(:json_date, :label => 'existence', :begin => '1999-12-12', :end => '2000-05-02'),
                                             build(:json_date, :label => 'creation', :begin => nil, :end => nil)]
                                         },
                                         :parent_properties => {
                                           :dates => [
                                             build(:json_date, :label => 'deaccession', :begin => '1999', :end => '2000'),
                                             build(:json_date, :label => 'creation', :begin => '1999-01-01', :end => nil)]
                                         },
                                         :child_properties => {
                                           :dates => [
                                             build(:json_date, :label => 'copyright', :begin => '1999', :end => '2010'),
                                             build(:json_date, :label => 'creation', :begin => '1985-10', :end => nil)]
                                         }
                                     })

    calculator = DateCalculator.new(resource)
    expect(calculator.min_begin).to eq('1985-10')
    expect(calculator.max_end).to eq('2010')
  end


  it "can calculate the date range for a resource, creation only and a bunch of dates" do
    (resource, _, _, _) = create_tree({
                                        :resource_properties => {
                                          :dates => [
                                            build(:json_date, :label => 'existence', :begin => '1990-01-01', :end => '2000-05-02'),
                                            build(:json_date, :label => 'creation', :begin => '1989-05-22', :end => nil)]
                                        },
                                        :grandparent_properties => {
                                          :dates => [
                                            build(:json_date, :label => 'existence', :begin => '1999-12-12', :end => '2000-06-02'),
                                            build(:json_date, :label => 'creation', :begin => nil, :end => nil)]
                                        },
                                        :parent_properties => {
                                          :dates => [
                                            build(:json_date, :label => 'deaccession', :begin => '1999', :end => '2000'),
                                            build(:json_date, :label => 'creation', :begin => '1999-01-01', :end => '1999-01-02')]
                                        },
                                        :child_properties => {
                                          :dates => [
                                            build(:json_date, :label => 'copyright', :begin => '1999', :end => '2010'),
                                            build(:json_date, :label => 'creation', :begin => '1985-10', :end => nil)]
                                        }
                                      })

    calculator = DateCalculator.new(resource, 'creation')
    expect(calculator.min_begin).to eq('1985-10')
    expect(calculator.max_end).to eq('1999-01-02')
  end

  it "can calculate the date range for a component" do
    (_, _, parent, _) = create_tree({
                                        :resource_properties => {
                                          :dates => [
                                            build(:json_date, :label => 'existence', :begin => '1990-01-01', :end => '2000-05-02'),
                                            build(:json_date, :label => 'creation', :begin => '1955-05-22', :end => nil)]
                                        },
                                        :grandparent_properties => {
                                          :dates => [
                                            build(:json_date, :label => 'existence', :begin => '1999-12-12', :end => '2000-06-02'),
                                            build(:json_date, :label => 'creation', :begin => nil, :end => '2022')]
                                        },
                                        :parent_properties => {
                                          :dates => [
                                            build(:json_date, :label => 'deaccession', :begin => '1985-10-02', :end => '2000'),
                                            build(:json_date, :label => 'creation', :begin => '1999-01-01', :end => nil)]
                                        },
                                        :child_properties => {
                                          :dates => [
                                            build(:json_date, :label => 'copyright', :begin => '1999', :end => '2010'),
                                            build(:json_date, :label => 'creation', :begin => '1985-10', :end => '2010-01-02')]
                                        }
                                      })

    calculator = DateCalculator.new(parent)
    expect(calculator.min_begin).to eq('1985-10')
    expect(calculator.max_end).to eq('2010')
  end


  it "can calculate the date range for a component, creation only" do
    (_, _, parent, _) = create_tree({
                                      :resource_properties => {
                                        :dates => [
                                          build(:json_date, :label => 'existence', :begin => '1990-01-01', :end => '2000-05-02'),
                                          build(:json_date, :label => 'creation', :begin => '1955-05-22', :end => nil)]
                                      },
                                      :grandparent_properties => {
                                        :dates => [
                                          build(:json_date, :label => 'existence', :begin => '1999-12-12', :end => '2000-06-02'),
                                          build(:json_date, :label => 'creation', :begin => nil, :end => '2022')]
                                      },
                                      :parent_properties => {
                                        :dates => [
                                          build(:json_date, :label => 'deaccession', :begin => '1985-10-02', :end => '2000'),
                                          build(:json_date, :label => 'creation', :begin => '1999-01-01', :end => nil)]
                                      },
                                      :child_properties => {
                                        :dates => [
                                          build(:json_date, :label => 'copyright', :begin => '1999', :end => '2010'),
                                          build(:json_date, :label => 'creation', :begin => '1991-07-10', :end => '2010-01-02')]
                                      }
                                    })

    calculator = DateCalculator.new(parent, 'creation')
    expect(calculator.min_begin).to eq('1991-07-10')
    expect(calculator.max_end).to eq('2010-01-02')
  end

  it "returns the correct report data for a resource" do
    (resource, _, _, _) = create_tree({
                                        :resource_properties => {
                                          :dates => [
                                            build(:json_date, :label => 'existence', :begin => '1990-01-01', :end => '2000-05-02'),
                                            build(:json_date, :label => 'creation', :begin => '1989-05-22', :end => nil)]
                                        },
                                        :grandparent_properties => {
                                          :dates => [
                                            build(:json_date, :label => 'existence', :begin => '1999-12-12', :end => '2000-05-02'),
                                            build(:json_date, :label => 'creation', :begin => nil, :end => nil)]
                                        },
                                        :parent_properties => {
                                          :dates => [
                                            build(:json_date, :label => 'deaccession', :begin => '1999', :end => '2000'),
                                            build(:json_date, :label => 'creation', :begin => '1999-01-11', :end => nil)]
                                        },
                                        :child_properties => {
                                          :dates => [
                                            build(:json_date, :label => 'copyright', :begin => '1999', :end => '2010'),
                                            build(:json_date, :label => 'creation', :begin => '1985-10', :end => nil)]
                                        }
                                      })

    report = DateCalculator.new(resource).to_hash

    expect(report.fetch(:object).fetch(:uri)).to eq(resource.uri)
    expect(report.fetch(:object).fetch(:jsonmodel_type)).to eq('resource')
    expect(report.fetch(:object).fetch(:title)).to eq(resource.title)
    expect(report.fetch(:object).fetch(:id)).to eq(resource.id)
    expect(report.fetch(:label)).to be_nil
    expect(report.fetch(:min_begin)).to eq('1985-10')
    expect(report.fetch(:min_begin_date)).to eq(Date.strptime('1985-10-01', '%Y-%m-%d'))
    expect(report.fetch(:max_end)).to eq('2010')
    expect(report.fetch(:max_end_date)).to eq(Date.strptime('2010-12-31', '%Y-%m-%d'))
  end


  it "returns the correct report data for a component" do
    (resource, _, parent, _) = create_tree({
                                      :resource_properties => {
                                        :dates => [
                                          build(:json_date, :label => 'existence', :begin => '1990-01-01', :end => '2000-05-02'),
                                          build(:json_date, :label => 'creation', :begin => '1955-05-22', :end => nil)]
                                      },
                                      :grandparent_properties => {
                                        :dates => [
                                          build(:json_date, :label => 'existence', :begin => '1999-12-12', :end => '2000-06-02'),
                                          build(:json_date, :label => 'creation', :begin => nil, :end => '2022')]
                                      },
                                      :parent_properties => {
                                        :dates => [
                                          build(:json_date, :label => 'deaccession', :begin => '1985-10-02', :end => '2000'),
                                          build(:json_date, :label => 'creation', :begin => '1999-01-11', :end => nil)]
                                      },
                                      :child_properties => {
                                        :dates => [
                                          build(:json_date, :label => 'copyright', :begin => '1999', :end => '2010'),
                                          build(:json_date, :label => 'creation', :begin => '1985-10', :end => '2010-01-02')]
                                      }
                                    })

    report = DateCalculator.new(parent, 'creation').to_hash

    expect(report.fetch(:object).fetch(:uri)).to eq(parent.uri)
    expect(report.fetch(:object).fetch(:jsonmodel_type)).to eq('archival_object')
    expect(report.fetch(:object).fetch(:title)).to eq(parent.title)
    expect(report.fetch(:object).fetch(:id)).to eq(parent.id)

    expect(report.fetch(:resource).fetch(:uri)).to eq(resource.uri)
    expect(report.fetch(:resource).fetch(:title)).to eq(resource.title)

    expect(report.fetch(:label)).to eq('creation')
    expect(report.fetch(:min_begin)).to eq('1985-10')
    expect(report.fetch(:min_begin_date)).to eq(Date.strptime('1985-10-01', '%Y-%m-%d'))
    expect(report.fetch(:max_end)).to eq('2010-01-02')
    expect(report.fetch(:max_end_date)).to eq(Date.strptime('2010-01-02', '%Y-%m-%d'))
  end


  it "takes into account single dates where a begin date is beyond all other end dates" do
    (resource, _, _, _) = create_tree({
                                        :resource_properties => {
                                          :dates => [
                                            build(:json_date, :label => 'existence', :begin => '1990-01-01', :end => '2000-05-02'),
                                            build(:json_date, :label => 'creation', :begin => '1989-05-22', :end => nil)]
                                        },
                                        :grandparent_properties => {
                                          :dates => [
                                            build(:json_date, :label => 'existence', :begin => '1999-12-12', :end => '2000-06-02'),
                                            build(:json_date, :label => 'creation', :begin => nil, :end => nil)]
                                        },
                                        :parent_properties => {
                                          :dates => [
                                            build(:json_date, :label => 'deaccession', :begin => '1999', :end => '2000'),
                                            build(:json_date, :label => 'creation', :begin => '1999-01-10', :end => nil)]
                                        },
                                        :child_properties => {
                                          :dates => [
                                            build(:json_date, :label => 'copyright', :begin => '1999', :end => '2010'),
                                            build(:json_date, :label => 'creation', :begin => '2017-05-17', :end => nil)]
                                        }
                                      })

    calculator = DateCalculator.new(resource)
    expect(calculator.min_begin).to eq('1999')
    expect(calculator.max_end).to eq('2017-05-17')
  end

  it "excludes dates from the root resource when calculating date ranges" do
    # Create a resource with its own date that should be excluded
    resource = create_resource({
      :dates => [build(:json_date, {
        :label => 'creation',
        :begin => '1900',
        :end => '2000',
        :date_type => 'inclusive'
      })]
    })

    # Create child archival objects with different dates
    child1 = create_archival_object({
      :resource => { :ref => resource.uri },
      :dates => [build(:json_date, {
        :label => 'creation',
        :begin => '1950',
        :end => '1960',
        :date_type => 'inclusive'
      })]
    })

    child2 = create_archival_object({
      :resource => { :ref => resource.uri },
      :dates => [build(:json_date, {
        :label => 'creation',
        :begin => '1955',
        :end => '1965',
        :date_type => 'inclusive'
      })]
    })

    calculator = DateCalculator.new(Resource.get_or_die(resource.id))
    result = calculator.to_hash

    # Should only include dates from children, not from resource
    expect(result[:min_begin]).to eq('1950')
    expect(result[:max_end]).to eq('1965')
  end

  it "excludes dates from the parent archival object when calculating date ranges" do
    resource = create_resource

    # Create parent AO with its own date that should be excluded
    parent = create_archival_object({
      :resource => { :ref => resource.uri },
      :dates => [build(:json_date, {
        :label => 'creation',
        :begin => '1900',
        :end => '2000',
        :date_type => 'inclusive'
      })]
    })

    # Create child AOs with different dates
    child1 = create_archival_object({
      :resource => { :ref => resource.uri },
      :parent => { :ref => parent.uri },
      :dates => [build(:json_date, {
        :label => 'creation',
        :begin => '1950',
        :end => '1960',
        :date_type => 'inclusive'
      })]
    })

    child2 = create_archival_object({
      :resource => { :ref => resource.uri },
      :parent => { :ref => parent.uri },
      :dates => [build(:json_date, {
        :label => 'creation',
        :begin => '1955',
        :end => '1965',
        :date_type => 'inclusive'
      })]
    })

    calculator = DateCalculator.new(ArchivalObject.get_or_die(parent.id))
    result = calculator.to_hash

    # Should only include dates from children, not from parent
    expect(result[:min_begin]).to eq('1950')
    expect(result[:max_end]).to eq('1965')
  end

  it "handles empty child date ranges correctly" do
    resource = create_resource

    # Create parent with no children
    parent = create_archival_object({
      :resource => { :ref => resource.uri },
      :dates => [build(:json_date, {
        :label => 'creation',
        :begin => '1900',
        :end => '2000',
        :date_type => 'inclusive'
      })]
    })

    calculator = DateCalculator.new(ArchivalObject.get_or_die(parent.id))
    result = calculator.to_hash

    # Should have nil dates since there are no children
    expect(result[:min_begin]).to be_nil
    expect(result[:max_end]).to be_nil
  end
end
