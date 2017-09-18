class IndexerCommon

  self.add_indexer_initialize_hook do |indexer|
    indexer.record_has_children('hello_worlds')
    indexer.add_extra_documents_hook {|record|
      docs = []
      (record['record']['hello_worlds'] || []).each do |hw|
        parent_type = JSONModel.parse_reference(record['uri'])[:type]
        docs << {
          'id' => "#{record['uri']}##{parent_type}_hello_worlds",
          'parent_id' => record['uri'],
          'parent_title' => record['record']['title'],
          'parent_type' => parent_type,
          'title' => record['record']['title'],
          'types' => ['hello_world'],
          'primary_type' => 'hello_world',
          'fullrecord' => hw.to_json(:max_nesting => false),
          'who_u_sstr' => hw['who'],
          'repository' => indexer.get_record_scope(record['uri']),
          'created_by' => hw['created_by'],
          'last_modified_by' => hw['last_modified_by'],
          'system_mtime' => hw['system_mtime'],
          'user_mtime' => hw['user_mtime'],
          'create_time' => hw['create_time'],
        }
      end
      docs
    }
  end
end
