
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
    when 'uniform_title'; 't'
    when 'genre_form', 'style_period'; 'v'
    when 'topical', 'cultural_context'; 'x'
    when 'temporal'; 'y'
    when 'geographic'; 'z'
    end
  end


  def test_person_name(df, name)
    name_string = %w(primary_ rest_of_).map{|p| name["#{p}name"]}.reject{|n| n.nil? || n.empty?}\
                                                                 .join(name['name_order'] == 'direct' ? ' ' : ', ')

    agent_test_template(df, {
                              'a' => name_string,
                              'b' => name['number'],
                              'c' => %w(prefix title suffix).map{|p| name[p]}.compact.join(', '),
                              'd' => name['dates'],
                              'q' => name['fuller_form']
                            })
  end


  def test_family_name(df, name)
    agent_test_template(df, {
                              'a' => name['family_name'],
                              'c' => name['prefix'],
                              'd' => name['dates'],
                            })
  end


  def test_corporate_name(df, name)
    agent_test_template(df, {
                              'a' => name['primary_name'],
                              'b' => [name['subordinate_name_1'], name['subordinate_name_2']],
                              'n' => name['number'],
                            })
  end


  def agent_test_template(df, code_hash)
    code_hash.each do |code, value|
      test_values = value.is_a?(Array) ? value : [value]
      test_values.each do |tv|
        next if tv.nil? || tv.empty?
        df.should have_node("subfield[@code='#{code}'][text()='#{tv}']")
      end
    end
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