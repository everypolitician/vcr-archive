require 'test_helper'
require 'open-uri'

describe VCR::Archive do
  it 'has a version number' do
    refute_nil ::VCR::Archive::VERSION
  end

  describe 'Serializer'  do
    subject { VCR::Archive::Serializer }
    it 'returns "archive" as the file extension' do
      assert_equal 'archive', subject.file_extension
    end

    it "doesn't touch the hash when (de)serializing" do
      assert_equal({ foo: :bar }, subject.serialize(foo: :bar))
      assert_equal({ foo: :bar }, subject.deserialize(foo: :bar))
    end
  end

  describe 'Persister' do
    subject { VCR::Archive::Persister }

    let(:tmpdir) { Dir.mktmpdir }
    let(:uri) { 'http://example.org' }
    let(:meta) do
      {
        'http_interactions' => [
          {
            'request' => {
              'uri' => uri,
            },
            'response' => {
              'body' => {
                'string' => 'Hello, world.',
              },
            },
          },
        ],
      }
    end
    let(:path) { File.join(tmpdir, 'foo', 'example.org', Digest::SHA1.hexdigest(uri)) }

    before { subject.storage_location = tmpdir }

    describe '#[]' do
      let(:path) { subject.storage_location + '/foo/example.com/123' }
      let(:yaml_path) { path + '.yml' }
      let(:html_path) { path + '.html' }

      before { FileUtils.mkdir_p(File.dirname(path)) }

      it 'reads from the given file, relative to the configured storage location' do
        File.write(yaml_path, YAML.dump(meta['http_interactions'].first))
        html = '<p>Hello, world.</p>'
        File.write(html_path, html)
        meta['http_interactions'].first['response']['body']['string'] = html
        assert_equal meta, subject['foo']
      end

      it 'returns nil if the directory does not exist' do
        FileUtils.rm_rf(File.dirname(path))
        assert_nil subject['bar']
      end

      it 'returns nil if the directory exists but is empty' do
        FileUtils.mkdir_p(File.dirname(path))
        assert_nil subject['foo']
      end
    end

    describe '#[]=' do
      it 'writes out response body to an html file' do
        subject['foo'] = meta
        assert_equal 'Hello, world.', File.read("#{path}.html")
      end

      it 'writes out the metadata to a yaml file' do
        subject['foo'] = meta
        expected = { 'request'=> { 'uri' => 'http://example.org' }, 'response' => { 'body' => {} } }
        assert_equal expected, YAML.load_file("#{path}.yml")
      end
    end
  end
end
