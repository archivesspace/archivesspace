module JsonmodelFormHelper
  def jsonmodel_form_for(name, *args, &block)
    options = args.extract_options!
    form_for(name, *(args << options.merge(:builder => JsonmodelFormBuilder)), &block)
  end
end