require 'spec_helper'
require_relative 'factories'

describe 'Date Calculator model' do

  def create_tree(opts = {})
    resource = create_resource(opts.fetch(:resource_properties, {}))

    grandparent = create(:json_archival_object,
                         {
                           :resource => {"ref" => resource.uri},
                           :level => "series", :component_id => SecureRandom.hex
                         }.merge(opts.fetch(:grandparent_properties, {})))

    parent = create(:json_archival_object,
                    {
                      :resource => {"ref" => resource.uri},
                      :parent => {"ref" => grandparent.uri}
                    }.merge(opts.fetch(:parent_properties, {})))

    child = create(:json_archival_object,
                   {
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
    calculator.min_begin.should eq('1990-01-01')
    calculator.max_end.should eq('2000-05-02')
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
    calculator.min_begin.should eq('1985-10')
    calculator.max_end.should eq('2010')
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
    calculator.min_begin.should eq('1985-10')
    calculator.max_end.should eq('1999-01-02')
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
    calculator.min_begin.should eq('1985-10')
    calculator.max_end.should eq('2010')
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
    calculator.min_begin.should eq('1991-07-10')
    calculator.max_end.should eq('2010-01-02')
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

    report.fetch(:object).fetch(:uri).should eq(resource.uri)
    report.fetch(:object).fetch(:jsonmodel_type).should eq('resource')
    report.fetch(:object).fetch(:title).should eq(resource.title)
    report.fetch(:object).fetch(:id).should eq(resource.id)
    report.fetch(:label).should be_nil
    report.fetch(:min_begin).should eq('1985-10')
    report.fetch(:min_begin_date).should eq(Date.strptime('1985-10-01', '%Y-%m-%d'))
    report.fetch(:max_end).should eq('2010')
    report.fetch(:max_end_date).should eq(Date.strptime('2010-12-31', '%Y-%m-%d'))
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

    report.fetch(:object).fetch(:uri).should eq(parent.uri)
    report.fetch(:object).fetch(:jsonmodel_type).should eq('archival_object')
    report.fetch(:object).fetch(:title).should eq(parent.title)
    report.fetch(:object).fetch(:id).should eq(parent.id)

    report.fetch(:resource).fetch(:uri).should eq(resource.uri)
    report.fetch(:resource).fetch(:title).should eq(resource.title)

    report.fetch(:label).should eq('creation')
    report.fetch(:min_begin).should eq('1985-10')
    report.fetch(:min_begin_date).should eq(Date.strptime('1985-10-01', '%Y-%m-%d'))
    report.fetch(:max_end).should eq('2010-01-02')
    report.fetch(:max_end_date).should eq(Date.strptime('2010-01-02', '%Y-%m-%d'))
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
    calculator.min_begin.should eq('1989-05-22')
    calculator.max_end.should eq('2017-05-17')
  end
end
