
module MARCExportSpecHelpers

  # typical mapping of source codes to marc @ind2 attribute
  def source_to_code(source)
    code =  case source
            when 'naf', 'lcsh'; 0
            when 'lcshac'; 1
            when 'mesh'; 2
            when 'nal'; 3
            when nil; 4
            when 'cash'; 5
            when 'rvm'; 6
            else; 7
            end
    code.to_s
  end

  # typical marc subfield codes contingent upon term type
  def term_type_code(term)
    case term['term_type']
    when 'genre_form', 'style_period'; 'v'
    when 'topical', 'cultural_context'; 'x'
    when 'temporal', 'y'
    when 'geographic', 'z'
    end
  end


  def test_person_name(df, name)
    name_string = %w(primary_ rest_of_).map{|p| name["#{p}name"]}.reject{|n| n.nil? || n.empty?}\
                                                                 .join(name['name_order'] == 'direct' ? ' ' : ', ')

    df.sf_t('a').should include(name_string)
    df.sf_t('b').should include(name['number'])
    df.sf_t('c').should include(%w(prefix title suffix).map{|p| name[p]}.compact.join(', '))
    df.sf_t('d').should include(name['dates'])
    df.sf_t('q').should include(name['fuller_form'])
  end


  def test_family_name(df, name)
    df.sf_t('a').should include(name['family_name'])
    df.sf_t('c').should include(name['prefix'])
    df.sf_t('d').should include(name['dates'])
  end


  def test_corporate_name(df, name)
    df.sf_t('a').should include(name['primary_name'])
    df.sf_t('b').should include(name['subordinate_name_1']+name['subordinate_name_2'])
    df.sf_t('n').should include(name['number'])
  end


  def note_test(note_types, dfcodes, sfcode, filters = {})
    raise "Missing test instance variable @resource" unless @resource
    raise "Missing test instance variable @doc" unless @doc

    notes = @resource.notes.select{|n| note_types.include?(n['type'])}
    filters.each do |k, v|
      notes.reject! {|n| n[k] != v }
    end

    pending "a different sample set (this is ok)" unless notes.count > 0
    xml_content = @doc.df(*dfcodes).sf_t(sfcode)
    xml_content.should_not be_empty
    notes.map{|n| note_content(n)}.join('').should eq(xml_content)
  end
end