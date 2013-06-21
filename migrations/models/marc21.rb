ASpaceExport::model :marc21 do
  
  include JSONModel
    
  @archival_object_map = {
    :repository => :handle_repo_code,
    :title => :handle_title,
    :linked_agents => :handle_agents,
    :subjects => :handle_subjects,
    :extents => :handle_extents,
  }
  
  @resource_map = {
    [:id_0, :id_1, :id_2, :id_3] => :handle_id,
    :notes => :handle_notes,
  }
  
  @@datafield = Class.new do
    
    attr_accessor :tag
    attr_accessor :ind1
    attr_accessor :ind2
    attr_accessor :subfields

    
    def initialize(*args)
      @tag, @ind1, @ind2 = *args
      @subfields = []
    end
    
    def with_sfs(*sfs)
      sfs.each {|sf| @subfields << @@subfield.new(*sf) }
      return self
    end
    
  end
  
  @@subfield = Class.new do
    
    attr_accessor :code
    attr_accessor :text
    
    def initialize(*args)
      @code, @text = *args
    end
    
  end
  
  def initialize
    @datafields = {}
  end
  
  def datafields
    @datafields.map {|k,v| v}
  end
  

  def self.from_aspace_object(obj)
    self.new
  end
    
  # 'archival object's in the abstract
  def self.from_archival_object(obj)
    
    marc = self.from_aspace_object(obj)
    
    marc.apply_map(obj, @archival_object_map)
    
    marc
  end
    
  # subtypes of 'archival object':
  
  def self.from_resource(obj)
    Log.debug("Obj #{obj.inspect}")
    marc = self.from_archival_object(obj)
    marc.apply_map(obj, @resource_map)
    
    marc
  end
  
  
  def df(*args)
    if @datafields.has_key?(args.to_s)
      @datafields[args.to_s]
    else
      @datafields[args.to_s] = @@datafield.new(*args)
      @datafields[args.to_s]
    end
  end
  

  def handle_id(*ids)
    df('852').with_sfs(['c', ids.join('--')])
  end
  
  def handle_title(title)
    df('852').with_sfs(['b', title])
  end 
  
  def handle_repo_code(repository)
    df('852').with_sfs(['a', "Repository: #{repository['_resolved']['repo_code']}"])
  end
  
  def handle_subjects(subjects)
    subjects.each do |subject|
      json = subject['_resolved']
      
      json['terms'].each do |term|
        
        code =case term['term_type']
              when 'Uniform title' then '630'
              when 'Topical' then '650'
              when 'Geographic' then '651'
              when 'Genre / form' then '655'
              when 'Occupation' then '656'
              when 'Function' then '657'
              else
                '650' # ??????
              end
        
        df(code, nil, '7').with_sfs(['a', term['term']])
      end
    end
  end
  

  def handle_agents(linked_agents)
    linked_agents.each do |link|

      role = link['role']
      agent = link['_resolved']

      agent['names'].each do |name|
        case agent['agent_type']
        when 'agent_person'
          a = ['primary_name', 'rest_of_name'].map {|np| name[np] if name[np] }.join(', ')
          df('700', '1').with_sfs(['a', a], ['e', role])
          
        when 'agent_family'
          a = name['family_name']
          df('700', '3').with_sfs(['a', a], ['e', role])
        
        when 'agent_corporate_entity'
          a = name['primary_name']
          df('700', '2').with_sfs(['a', a], ['e', role])
        end
      end
        
    end
  end


  def handle_notes(notes)

    notes.each do |note|

      knote = Proc.new{ |d,s| df(d).with_sfs([s, Array(ASpaceExport::Utils.extract_note_text(note))]) }

      case note['type']
      
      when 'arrangement'
        knote.call('352','b')
      when 'odd'
        knote.call('500','a')
      when 'accessrestrict'
        knote.call('506','a')
      when 'scopecontent'
        knote.call('520','a')
      when 'prefercite'
        knote.call('524','a')
      when 'acqinfo'
        knote.call('541','a')
      when 'relatedmaterial'
        knote.call('544','a')
      when 'bioghist'
        knote.call('545','a')
      when 'otherfindaid'
        knote.call('555','a')
      when 'custodhist'
        knote.call('561','a')
      when 'appraisal'
        knote.call('583','a')
      when 'accruals'
        knote.call('584', 'a')
      end
    end 
  end
  
  def handle_extents(extents)
    extents.each do |ext|
      e = ext['number']
      e << " (#{ext['portion']})" if ext['portion']
      e << " #{ext['extent_type']}"
      df('300').with_sfs(['a', e])
    end
  end

      
  
end
