AdvancedSearch.define_field(:name => 'keyword', :type => :text, :visibility => [:staff, :public], :solr_field => 'fullrecord')
AdvancedSearch.define_field(:name => 'title', :type => :text, :visibility => [:staff, :public], :solr_field => 'title')
AdvancedSearch.define_field(:name => 'identifier', :type => :text, :visibility => [:staff, :public], :solr_field => 'identifier')
AdvancedSearch.define_field(:name => 'creators', :type => :text, :visibility => [:staff, :public], :solr_field => 'creators_text')
AdvancedSearch.define_field(:name => 'notes', :type => :text, :visibility => [:staff, :public], :solr_field => 'notes')
AdvancedSearch.define_field(:name => 'subjects', :type => :text, :visibility => [:staff, :public], :solr_field => 'subjects_text')

AdvancedSearch.define_field(:name => 'published', :type => :boolean, :visibility => [:staff], :solr_field => 'publish')
AdvancedSearch.define_field(:name => 'suppressed', :type => :boolean, :visibility => [:staff], :solr_field => 'suppressed')

AdvancedSearch.define_field(:name => 'create_time', :type => :date, :visibility => [:staff], :solr_field => 'create_time')
AdvancedSearch.define_field(:name => 'user_mtime', :type => :date, :visibility => [:staff], :solr_field => 'user_mtime')

AdvancedSearch.define_field(:name => 'system_mtime', :type => :date, :visibility => [:api], :solr_field => 'system_mtime')
AdvancedSearch.define_field(:name => 'last_modified_by', :type => :text, :visibility => [:api], :solr_field => 'last_modified_by')

AdvancedSearch.define_field(:name => 'id', :type => :text, :visibility => [:api], :solr_field => 'id')
AdvancedSearch.define_field(:name => 'resource', :type => :text, :visibility => [:api], :solr_field => 'resource')
AdvancedSearch.define_field(:name => 'repository', :type => :text, :visibility => [:api], :solr_field => 'repository')

AdvancedSearch.set_default(:text, 'keyword')
AdvancedSearch.set_default(:boolean, 'published')
AdvancedSearch.set_default(:date, 'create_time')

