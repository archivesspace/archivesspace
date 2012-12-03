require 'spec_helper'
require 'i18n'
require_relative '../../app/models/resource.rb'
require_relative '../../app/models/accession.rb'

describe "Resource Model" do
  it "can spawn a resource from an accession" do
    resource = Resource.new(:title => "A new resource")

    accession = Accession.new(:condition_description => 'My condition',
                              :content_description => 'My content',
                              :title => 'My title',
                              :extents => [stub])

    accession.should_receive(:uri) { "/stub/uri" }



    resource.populate_from_accession(accession)

    resource.title.should eq('My title')
    resource.notes.count.should eq(2)

    resource.notes.map {|note| note['label']}.sort.should eq([I18n.t('accession.condition_description'),
                                                              I18n.t('accession.content_description')])

    resource.notes.map {|note| note['content']}.sort.should eq(['My condition', 'My content'])

    resource.related_accession.should eq("/stub/uri")

  end
end
