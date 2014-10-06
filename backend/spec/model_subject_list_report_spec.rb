require 'spec_helper'

describe 'SubjectListReport model' do
  
  
  it "can be created from a JSON module" do
    Subject.all.each { |s| s.delete }  
    subjects = []
    3.times { |i| subjects <<  create(:json_subject ) }

    report = SubjectListReport.new()
    json = JSON(  String.from_java_bytes( report.render(:json) )   )
    
    json["results"].length.should == 5 # one extra for the footer 
    
    sub1 = json["results"][0]
    sub2 = json["results"][1]
    sub3 = json["results"][2]

    sub1["subject"].should eq(subjects[0].title)
    sub2["subject"].should eq(subjects[1].title)
    sub3["subject"].should eq(subjects[2].title)
    
    # unsure how to test these...let's just render them and see if there are
    # any errors. 
    report.render(:html)
    report.render(:pdf) 
    report.render(:xlsx) 
  end
end
