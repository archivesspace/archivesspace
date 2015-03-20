require_relative 'export_spec_helper'

describe 'MARC Export' do

  describe "datafield 110 name mapping" do

    before(:each) do
      @name = build(:json_name_corporate_entity)
      agent = create(:json_agent_corporate_entity,
                    :names => [@name])
      @resource = create(:json_resource,
                         :linked_agents => [
                                            {
                                              'role' => 'creator',
                                              'ref' => agent.uri
                                            }
                                           ]
                         )

      @marc = get_marc(@resource)
    end

    it "maps primary_name to subfield 'a'" do
      @marc.should have_tag "datafield[@tag='110']/subfield[@code='a']" => @name.primary_name
    end
  end


  describe "datafield 245 mapping" do
    before(:each) do

      @dates = ['inclusive', 'bulk'].map {|type|
        range = [nil, nil].map { generate(:yyyy_mm_dd) }.sort
        build(:json_date,
              :date_type => type,
              :begin => range[0],
              :end => range[1],
              :expression => [true, false].sample ? generate(:string) : nil
              )
      }

      2.times { @dates << build(:json_date) }


      @resource = create(:json_resource,
                         :dates => @dates)

      @marc = get_marc(@resource)
    end

    it "maps the first inclusive date to subfield 'f'" do
      date = @dates.find{|d| d.date_type == 'inclusive'}

      if date.expression
        @marc.should have_tag "datafield[@tag='245']/subfield[@code='f']" => "#{date.expression}"
      else
        @marc.should have_tag "datafield[@tag='245']/subfield[@code='f']" => "#{date.begin} - #{date.end}"
      end
    end


    it "maps the first bulk date to subfield 'g'" do
      date = @dates.find{|d| d.date_type == 'bulk'}
      @marc.should have_tag "datafield[@tag='245']/subfield[@code='g']" => "#{date.begin} - #{date.end}"
    end


    it "doesn't create more than two dates" do
      %w(f g).each do |code|
        @marc.should_not have_tag "datafield[@tag='245']/subfield[@code='#{code}'][2]"
      end
    end
  end


  describe "datafield 3xx mapping" do
    before(:each) do

      @notes = %w(arrangement fileplan).map { |type|
        build(:json_note_multipart,
              :type => type,
              :publish => true)
      }

      @extents = (0..5).to_a.map{ build(:json_extent) }
      @resource = create(:json_resource,
                         :extents => @extents,
                         :notes => @notes)

      @marc = get_marc(@resource)
    end

    it "creates a 300 field for each extent" do
      @marc.should have_tag "datafield[@tag='300'][#{@extents.count}]"
      @marc.should_not have_tag "datafield[@tag='300'][#{@extents.count + 1}]"
    end


    it "maps extent number and type to subfield a" do
      type = I18n.t("enumerations.extent_extent_type.#{@extents[0].extent_type}")
      extent = "#{@extents[0].number} #{type}"
      @marc.should have_tag "datafield[@tag='300'][1]/subfield[@code='a']" => extent
    end


    it "maps container summary to subfield f" do
      @extents.each do |e|
        next unless e.container_summary
        @marc.should have_tag "datafield[@tag='300']/subfield[@code='f']" => e.container_summary
      end
    end


    it "maps arrangment and fileplan notes to datafield 351" do
      @notes.each do |note|
        @marc.should have_tag "datafield[@tag='351']/subfield[@code='b'][1]" => note_content(note)
      end
    end
  end

  describe "datafield 65x mapping" do
    before(:all) do

      @subjects = []
      30.times {
        subject = create(:json_subject)
        # only count subjects that map to 65x fields
        @subjects << subject unless ['uniform_title', 'temporal'].include?(subject.terms[0]['term_type'])
      }
     linked_subjects = @subjects.map {|s| {:ref => s.uri} }




      @extents = [ build(:json_extent)]
      @resource = create(:json_resource,
                         :extents => @extents,
                         :subjects => linked_subjects)

      @marc = get_marc(@resource)

    end

    it "creates a 65x field for each subject" do
      xmlnotes = []
      (0..9).each do |i|
        tag = "65#{i.to_s}"
        @marc.xpath("//xmlns:datafield[@tag = '#{tag}']").each { |x| xmlnotes << x  }
      end
      #puts xmlnotes.map{|n| n.inner_text }.inspect
      #puts @subjects.map{|s| s.to_hash }.inspect

      xmlnotes.length.should eq(@subjects.length)
    end
  end

  describe "strips mixed content" do
    before(:each) do

      @dates = ['inclusive', 'bulk'].map {|type|
        range = [nil, nil].map { generate(:yyyy_mm_dd) }.sort
        build(:json_date,
              :date_type => type,
              :begin => range[0],
              :end => range[1],
              :expression => [true, false].sample ? generate(:string) : nil
              )
      }

      2.times { @dates << build(:json_date) }


      @resource = create(:json_resource,
                         :dates => @dates,
                         :id_0 => "999",
                         :title => "Foo <emph render='bold'>BAR</emph> Jones")

      @marc = get_marc(@resource)
    end

    it "should strip out the mixed content in title" do
      @marc.should have_tag "datafield[@tag='245']/subfield[@code='a']" => "Foo  BAR  Jones"
    end
  end
end
