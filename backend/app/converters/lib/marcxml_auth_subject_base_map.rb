module MarcXMLAuthSubjectBaseMap

  AUTH_SUBJECT_SOURCE = {
    'a'=>"lcsh",
    'b'=>"LC subject headings for children's literature",
    'c'=>"Medical Subject Headings",
    'd'=>"National Agricultural Library subject authority file",
    'k'=>"Canadian Subject Headings",
    'n'=>"Not applicable",
    'r'=>"Art and Architecture Thesaurus",
    's'=>"Sears List of Subject Headings",
    'v'=>"R\u00E9pertoire de vedettes-matic\u00E8re",
    'z'=>"Other"
  }

  BIB_SUBJECT_SOURCE = {
    '0'=>"lcsh",
    '1'=>"LC subject headings for children's literature",
    '2'=>"Medical Subject Headings",
    '3'=>"National Agricultural Library subject authority file",
    '4'=>"Source not specified",
    '5'=>"Canadian Subject Headings",
    '6'=>"R\u00E9pertoire de vedettes-matic\u00E8re"
  }

  def record_properties(type_of_record = nil, source = nil, rules = nil)
    @properties ||= { type: :bibliographic, source: nil , rules: nil}
    if type_of_record
      @properties[:type] = type_of_record == 'z' ? :authority : :bibliographic
    end
    if @properties[:type] == :authority
      @properties[:source] = source if source
      @properties[:rules]  = rules  if rules
    end
    @properties
  end

  alias_method :set_record_properties, :record_properties

  def BASE_RECORD_MAP
    {
      :obj => :resource,
      :defaults => {
      },
      :map => {
      }
    }
  end
end
