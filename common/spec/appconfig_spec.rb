# frozen_string_literal: true

# ./build/run common:test

require_relative '../config/config-distribution'

describe AppConfig do
  context 'parsing values' do
    it 'parses "true" into boolean true' do
      expect(AppConfig.parse_value('true')).to be true
      expect(AppConfig.parse_value('TRUE')).to be true
      expect(AppConfig.parse_value('TRue')).to be true
    end

    it 'parses "false" into boolean false' do
      expect(AppConfig.parse_value('false')).to be false
      expect(AppConfig.parse_value('FALSE')).to be false
      expect(AppConfig.parse_value('FALse')).to be false
    end

    it 'parses "number" into integer' do
      expect(AppConfig.parse_value('123')).to eq 123
    end

    it 'parses ":string" into symbol' do
      expect(AppConfig.parse_value(':es')).to eq :es
      expect(AppConfig.parse_value(':with_underscore')).to eq :with_underscore
    end

    it 'parses "json []" into array' do
      expect(AppConfig.parse_value('[1, 2, 3]')).to eq([1, 2, 3])
    end

    it 'parses "json {}" into hash' do
      expect(AppConfig.parse_value('{"a": "b"}')).to eq({ 'a' => 'b' })
    end

    it 'raises an error if "json" is invalid' do
      expect do
        AppConfig.parse_value('{a: proc { 1 + 1 }}')
      end.to raise_error(JSON::ParserError)
    end

    it 'returns original value if no other criteria matched' do
      expect(AppConfig.parse_value('0 4 * * *')).to eq '0 4 * * *'
    end

    context 'through the environment' do
      it 'can add new properties' do
        ENV['APPCONFIG_ABC_DEF'] = 'abc_def'
        AppConfig.load_overrides_from_environment
        expect(AppConfig[:abc_def]).to eq 'abc_def'
      end

      it 'can override default values' do
        ENV['APPCONFIG_PLUGINS'] = '["plugin1",  "plugin2"]'
        ENV['APPCONFIG_SOLR_PARAMS'] = '{"mm": "200%"}'
        AppConfig.load_overrides_from_environment
        expect(AppConfig[:plugins]).to eq(['plugin1', 'plugin2'])
        expect(AppConfig[:solr_params]).to eq({ 'mm' => '200%' })
      end
    end
  end
end
