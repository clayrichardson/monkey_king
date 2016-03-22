require 'spec_helper'
require 'yaml'
require 'climate_control'

def exercise_fixture(fixture)
  fixture_before = fixture_file_path("#{fixture}_before.yml")
  transformed_yaml = parser.transform(fixture_before)
  fixture_after_content = load_file("#{fixture}_after.yml")
  expect(transformed_yaml).to eql(fixture_after_content)
end

describe MonkeyKing::Parser do
  let(:parser) {
    described_class.new
  }

  before :each do
    MonkeyKing.variables = {}
  end

  context 'read from and write to variable' do
    it 'get the expected results' do
      exercise_fixture('read_and_write')
    end
  end

  context 'formatting string' do
    it 'formatting the string' do
      allow_any_instance_of(MonkeyKing::FunctionTag).to receive(:gen_secret).and_return('nats_password')
      ClimateControl.modify NATS_USER: 'nats_user', NATS_HOST: 'nats_host' do
        exercise_fixture('format')
      end
    end
  end

  context 'generates secrets' do
    it 'generates a random secret' do
      allow_any_instance_of(MonkeyKing::FunctionTag).to receive(:gen_secret).and_return('after_secret')
      exercise_fixture('generate_secret')
    end
    it 'generates a random secret of the requested length' do
      expect(MonkeyKing::FunctionTag.new.gen_secret(20).length).to eql(20)
    end
  end

  context 'reading from env' do
    it 'read from env' do
      ClimateControl.modify id1: 'id1_from_env', id2: 'id2_from_env' do
        exercise_fixture('env')
      end
    end
  end

  context 'combine them all' do
    it 'read env and write to variables for read later' do
      ClimateControl.modify id1: 'id1_from_env', id2: 'id2_from_env' do
        exercise_fixture('write_env_read')
      end
    end
  end

  context 'errors' do
    it 'raise error when reading unresolved variable' do
       expect {
         exercise_fixture('error_read_unresolved')
       }.to raise_error('unresolved variables NATS_USER')
    end

    it 'raise error when redefine variable' do
       expect {
         exercise_fixture('error_redefine_immutable')
       }.to raise_error('attempting to redefine immutable variable NATS_PASSWORD, exiting')
    end

    it 'raise error when read get more than 1 argument' do
       expect {
         exercise_fixture('error_read_too_many_arguments')
       }.to raise_error('too many arguments for read function (2 of 1)')
    end

    it 'raise error when read get less than 1 argument' do
       expect {
         exercise_fixture('error_read_not_enough_arguments')
       }.to raise_error('not enough arguments for read function (0 of 1)')
    end

    it 'raise error when secret get less than 1 argument' do
       expect {
         exercise_fixture('error_secret_not_enough_arguments')
       }.to raise_error('not enough arguments for secret function (0 of 1)')
    end

    it 'raise error when secret get more than 1 argument' do
       expect {
         exercise_fixture('error_secret_too_many_arguments')
       }.to raise_error('too many arguments for secret function (2 of 1)')
    end

    it 'raise error when secret gets garbage argument' do
       expect {
         exercise_fixture('error_secret_garbage_argument')
       }.to raise_error('argument error for secret function: got Symbol instead of Fixnum')
    end

    it 'raise error when write gets less than 2 arguments' do
       expect {
         exercise_fixture('error_write_not_enough_arguments')
       }.to raise_error('not enough arguments for write function (1 of 2)')
    end

    it 'raise error when write get more than 2 argument' do
       expect {
         exercise_fixture('error_write_too_many_arguments')
       }.to raise_error('too many arguments for write function (3 of 2)')
    end

    it 'raise error when env get less than 1 argument' do
       expect {
         exercise_fixture('error_env_not_enough_arguments')
       }.to raise_error('not enough arguments for env function (0 of 1)')
    end

    it 'raise error when env get more than 1 argument' do
       expect {
         exercise_fixture('error_env_too_many_arguments')
       }.to raise_error('too many arguments for env function (2 of 1)')
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

    it 'returns a list of uniq tags in the yaml file' do
      expect(parser.get_tags(tag_file)).to be_a Array
      expect(parser.get_tags(tag_file)).to eql(tags)
    end
  end
end
