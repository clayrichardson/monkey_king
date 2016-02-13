require 'spec_helper'
require 'yaml'
require 'climate_control'

describe MonkeyKing::Parser do
  context '#secret_tag' do
    let(:secret_fixture_before) {
      fixture_file_path('secret_before.yml')
    }

    let(:secret_fixture_after_content) {
      load_file('secret_after.yml')
    }

    let(:parser) {
      described_class.new
    }

    it 'parse the secret annotation and replace it with a new secret' do
      allow_any_instance_of(MonkeyKing::SecretTag).to receive(:gen_secret).and_return('new_secret')
      transformed_yaml = parser.transform(secret_fixture_before)
      expect(transformed_yaml).to eql(secret_fixture_after_content)
    end
  end

  context '#get_tags' do
    let(:tag_file) {
      fixture_file_path('tags.yml')
    }

    let(:tags) {
      [
        '!MK:secret',
        '!MK:env:id1',
        '!MK:env:id2',
        '!MK:env:id3'
      ]
    }

    let(:parser) {
      described_class.new
    }

    it 'returns a list of the tags in the yaml file' do
      expect(parser.get_tags(tag_file)).to be_a Array
      expect(parser.get_tags(tag_file)).to eql(tags)
    end
  end


  context '#env_tag' do
    let(:env_fixture_before) {
      fixture_file_path('env_before.yml')
    }

    let(:env_fixture_after_content) {
      load_file('env_after.yml')
    }

    let(:parser) {
      described_class.new
    }

    it 'replace the field with env tag' do
			ClimateControl.modify id1: 'id1_from_env', id2: 'id2_from_env' do
				transformed_yaml = parser.transform(env_fixture_before)
				expect(transformed_yaml).to eql(env_fixture_after_content)
			end
    end

  end

end
