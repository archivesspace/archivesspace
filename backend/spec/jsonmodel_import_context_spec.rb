require 'spec_helper'

describe 'Import JSONModel context' do

  # JSONModel.parse_reference uses a cache to quickly determine an
  # object's model. But if JSONModel is modified to use a different
  # uri pattern, the cache will explode if object.id is called for
  # objects with the variant pattern, such as temporary import uris.
  it "does not break the JSONModel.parse_reference caching model" do
    model_lookup_cache = JSONModel.class_variable_get(:@@model_lookup_cache)
    obj = ASpaceImport::JSONModel(:accession).new
    expect(model_lookup_cache.value[obj.uri]).to be_nil
    obj.id
    expect(model_lookup_cache.value[obj.uri]).to be_nil
  end
end
