require 'spec_helper'
require_relative '../../common/db/migrations/utils'

describe 'RDETemplateFix' do
  let(:order) {[ 'a', 'b', 'c', 'colLang', 'd', 'e' ]}
  let(:updated_order) {[ 'a', 'b', 'c', 'colLanguage', 'colScript', 'd', 'e' ]}
  let(:defaults) {{ 'a' => 'b', 'colLang' => 'eng' }}
  let(:updated_defaults) {{ 'a' => 'b', 'colLanguage' => 'eng', 'colScript' => 'Latn' }}

  it 'replaces colLang in array with colLanguage and colScript' do
    did_something = RDETemplateFix.update_array(order)
    expect(did_something).to be true
    expect(order).to eq updated_order
  end

  it 'does nothing to array when deprecated term not present' do
    did_something = RDETemplateFix.update_array(updated_order)
    expect(did_something).to be false
  end

  it 'replaces colLang in hash with colLanguage and colScript' do
    did_something = RDETemplateFix.update_hash(defaults)
    expect(did_something).to be true
    expect(defaults.key?('colLang')).to be false
    expect(defaults).to eq updated_defaults
  end

  it 'does nothing to hash when deprecated term not present' do
    did_something = RDETemplateFix.update_hash(updated_defaults)
    expect(did_something).to be false
  end
end
