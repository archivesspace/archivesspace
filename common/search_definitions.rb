AdvancedSearch.define_field(:name => 'keyword', :type => :text, :visibility => [:staff, :public], :solr_field => 'fullrecord')
AdvancedSearch.define_field(:name => 'title', :type => :text, :visibility => [:staff, :public], :solr_field => 'title')
AdvancedSearch.define_field(:name => 'creators', :type => :text, :visibility => [:staff, :public], :solr_field => 'creators_text')
AdvancedSearch.define_field(:name => 'notes', :type => :text, :visibility => [:staff, :public], :solr_field => 'notes')
AdvancedSearch.define_field(:name => 'subjects', :type => :text, :visibility => [:staff, :public], :solr_field => 'subjects_text')

AdvancedSearch.define_field(:name => 'published', :type => :boolean, :visibility => [:staff], :solr_field => 'publish')
AdvancedSearch.define_field(:name => 'suppressed', :type => :boolean, :visibility => [:staff], :solr_field => 'suppressed')

AdvancedSearch.define_field(:name => 'create_time', :type => :date, :visibility => [:staff], :solr_field => 'create_time')
AdvancedSearch.define_field(:name => 'user_mtime', :type => :date, :visibility => [:staff], :solr_field => 'user_mtime')


AdvancedSearch.set_default(:text, 'keyword')
AdvancedSearch.set_default(:boolean, 'published')
AdvancedSearch.set_default(:date, 'create_time')
