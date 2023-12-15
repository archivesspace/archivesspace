require 'spec_helper'
require 'stringio'

describe 'Bulk Import Jobs' do

  describe "digital object spreadsheet imports" do

    let(:resource) do
      create(:json_resource, ead_id: "foobar")
    end

    let(:archival_object) do
      create(:json_archival_object, :resource => {:ref => resource.uri}, :publish => true, :title => "Series 1")
    end

    let(:job) do
      json = build(:json_job,
                   :job_type => 'bulk_import_job',
                   :job_params => {rid: resource.id}.to_json,
                   :job => JSONModel(:bulk_import_job).new({
                                                             resource_id: resource.id.to_s,
                                                             filename: 'foo',
                                                             load_type: 'digital',
                                                             content_type: 'csv',
                                                             format: "does it matter?",
                                                             only_validate: "hmmmmmm"

                                                           }))


      tmp = ASUtils.tempfile("bulk-import-digital-object-csv-#{Time.now.to_i}")
      tmp.write("ArchivesSpace digital object import field codes,collection_id,ead,ref_id,res_uri,ao_ref_id,ao_uri,digital_object_id,digital_object_title,digital_object_publish,rep_file_uri,rep_use_statement,rep_xlink_actuate_attribute,rep_xlink_show_attribute,rep_file_format,rep_file_format_version,rep_file_size,rep_checksum,rep_checksum_method,rep_caption,nonrep_file_uri,nonrep_publish,nonrep_use_statement,nonrep_xlink_actuate_attribute,nonrep_xlink_show_attribute,nonrep_file_format,nonrep_file_format_version,nonrep_file_size,nonrep_checksum,nonrep_checksum_method,nonrep_caption\n")
      tmp.write(",,#{resource.ead_id},,,#{archival_object.ref_id},,,blah blah,t,http://blahblah.com,,,,,,,,,,http://thumbnail.com,f,\n")
      tmp.write(",,#{resource.ead_id},,,#{archival_object.ref_id},,,hide me,f,http://hideme.com,,,,,,,,,,http://thumbnail.com,t,\n")
      tmp.rewind
      user = create_nobody_user
      job = Job.create_from_json(json,
                                 :repo_id => $repo_id,
                                 :user => user)

      job.add_file(tmp)
      job
    end

    before(:each) do
      job_runner = JobRunner.for(job)
      job_runner.run
    end

    it "can determine publication status of digital objects, file link, and thumbnail" do
      ao = JSONModel(:archival_object).find(archival_object.id, 'resolve[]' => ["instances", "digital_object"])
      expect(ao.instances[0]['digital_object']['_resolved']['title']).to eq "blah blah"
      expect(ao.instances[0]['digital_object']['_resolved']['publish']).to be true
      expect(ao.instances[1]['digital_object']['_resolved']['publish']).to be false
      # file versions
      expect(ao.instances[0]['digital_object']['_resolved']['file_versions'][0]['publish']).to be true
      expect(ao.instances[0]['digital_object']['_resolved']['file_versions'][1]['publish']).to be false
      expect(ao.instances[1]['digital_object']['_resolved']['file_versions'][0]['publish']).to be true
      expect(ao.instances[1]['digital_object']['_resolved']['file_versions'][1]['publish']).to be true
    end
  end

  describe "archival object spreadsheet imports" do

    let(:resource) do
      create(:json_resource, ead_id: "foobar")
    end

    let(:job) do
      json = build(:json_job,
                   :job_type => 'bulk_import_job',
                   :job_params => {rid: resource.id}.to_json,
                   :job => JSONModel(:bulk_import_job).new({
                                                             resource_id: resource.id.to_s,
                                                             filename: 'foo',
                                                             load_type: 'ao',
                                                             content_type: 'csv',
                                                             format: "does it matter?",
                                                             only_validate: "hmmmmmm"
                                                           }))


      tmp = ASUtils.tempfile("bulk-import-archival-object-csv-#{Time.now.to_i}")
      tmp.write("ArchivesSpace field code (please don't edit this row),collection_id,ead,res_uri,ref_id,title,unit_id,hierarchy,level,other_level,publish,restrictions_flag,processing_note,l_lang,l_langscript,n_langmaterial,p_langmaterial,l_lang_2,l_langscript_2,n_langmaterial_2,p_langmaterial_2,dates_label,begin,end,date_type,expression,date_certainty,dates_label_2,begin_2,end_2,date_type_2,expression_2,date_certainty_2,portion,number,extent_type,container_summary,physical_details,dimensions,portion_2,number_2,extent_type_2,container_summary_2,physical_details_2,dimensions_2,cont_instance_type,type_1,indicator_1,barcode,type_2,indicator_2,type_3,indicator_3,cont_instance_type_2,type_1_2,indicator_1_2,barcode_2,type_2_2,indicator_2_2,type_3_2,indicator_3_2,digital_object_id,digital_object_title,digital_object_publish,rep_file_uri,rep_use_statement,rep_xlink_actuate_attribute,rep_xlink_show_attribute,rep_file_format,rep_file_format_version,rep_file_size,rep_checksum,rep_checksum_method,rep_caption,nonrep_file_uri,nonrep_publish,nonrep_use_statement,nonrep_xlink_actuate_attribute,nonrep_xlink_show_attribute,nonrep_file_format,nonrep_file_format_version,nonrep_file_size,nonrep_checksum,nonrep_checksum_method,nonrep_caption,people_agent_record_id_1,people_agent_header_1,people_agent_role_1,people_agent_relator_1,people_agent_record_id_2,people_agent_header_2,people_agent_role_2,people_agent_relator_2,people_agent_record_id_3,people_agent_header_3,people_agent_role_3,people_agent_relator_3,people_agent_record_id_4,people_agent_header_4,people_agent_role_4,people_agent_relator_4,people_agent_record_id_5,people_agent_header_5,people_agent_role_5,people_agent_relator_5,families_agent_record_id_1,families_agent_header_1,families_agent_role_1,families_agent_relator_1,families_agent_record_id_2,families_agent_header_2,families_agent_role_2,families_agent_relator_2,corporate_entities_agent_record_id_1,corporate_entities_agent_header_1,corporate_entities_agent_role_1,corporate_entities_agent_relator_1,corporate_entities_agent_record_id_2,corporate_entities_agent_header_2,corporate_entities_agent_role_2,corporate_entities_agent_relator_2,corporate_entities_agent_record_id_3,corporate_entities_agent_header_3,corporate_entities_agent_role_3,corporate_entities_agent_relator_3,subject_1_record_id,subject_1_term,subject_1_type,subject_1_source,subject_2_record_id,subject_2_term,subject_2_type,subject_2_source,n_abstract,p_abstract,n_accessrestrict,p_accessrestrict,b_accessrestrict,e_accessrestrict,n_acqinfo,p_acqinfo,n_arrangement,p_arrangement,n_bioghist,p_bioghist,n_custodhist,p_custodhist,n_dimensions,p_dimensions,n_odd,p_odd,n_physdesc,p_physdesc,n_physfacet,p_physfacet,n_physloc,p_physloc,n_prefercite,p_prefercite,n_processinfo,p_processinfo,n_relatedmaterial,p_relatedmaterial,n_scopecontent,p_scopecontent,n_separatedmaterial,p_separatedmaterial,n_userestrict,p_userestrict\n")
      tmp.write(",,#{resource.ead_id},,foobar1,One,foobar_1,1,series,,t,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,DOFOOBAR,Foo Bar and Friends,t,http://foo.bar,,,,,,,,,,http://foo.thumb,f,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,\n")
      tmp.write(",,#{resource.ead_id},,Foobar2,Two,foobar_2,1,series,,f,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,DOFOOBAR_2,Foo Bar and Friends Dos,t,http://foo.bar2,,,,,,,,,,http://foo.thumb2,t,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,")

      tmp.rewind
      user = create_nobody_user
      job = Job.create_from_json(json,
                                 :repo_id => $repo_id,
                                 :user => user)

      job.add_file(tmp)
      job
    end

    before(:each) do
      job_runner = JobRunner.for(job)
      job_runner.run
    end

    it "can determine publication status of digital objects, file link, and thumbnail" do
      res = JSONModel(:resource).find(resource.id, 'resolve[]' => ['tree'])
      ao0_id = res['tree']['_resolved']['children'][0]['id']
      ao1_id = res['tree']['_resolved']['children'][1]['id']
      ao0 = JSONModel(:archival_object).find(ao0_id, 'resolve[]' => ['instances', 'digital_object'])
      ao1 = JSONModel(:archival_object).find(ao1_id, 'resolve[]' => ['instances', 'digital_object'])

      expect(ao0.instances[0]['digital_object']['_resolved']['file_versions'][0]['file_uri']).to eq 'http://foo.bar'
      expect(ao0.instances[0]['digital_object']['_resolved']['file_versions'][0]['publish']).to be true
      expect(ao0.instances[0]['digital_object']['_resolved']['file_versions'][1]['file_uri']).to eq 'http://foo.thumb'
      expect(ao0.instances[0]['digital_object']['_resolved']['file_versions'][1]['publish']).to be false

      expect(ao1.instances[0]['digital_object']['_resolved']['file_versions'][0]['file_uri']).to eq 'http://foo.bar2'
      expect(ao1.instances[0]['digital_object']['_resolved']['file_versions'][0]['publish']).to be true
      expect(ao1.instances[0]['digital_object']['_resolved']['file_versions'][1]['file_uri']).to eq 'http://foo.thumb2'
      expect(ao1.instances[0]['digital_object']['_resolved']['file_versions'][1]['publish']).to be true
    end
  end
end
